import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/app_cache_service.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../management/providers/coordinator_providers.dart';

const repositoryFileLimitBytes = 10 * 1024 * 1024;

const repositoryCategoryOptions = {
  'investigacion': 'Investigación',
  'manuales': 'Manuales',
  'actas': 'Actas',
  'divulgacion': 'Divulgación',
};

const repositoryAreaOptions = {
  'Ingeniería y Tecnología': 'Ingeniería y Tecnología',
  'Ciencias de la Salud': 'Ciencias de la Salud',
  'Ciencias Agropecuarias': 'Ciencias Agropecuarias',
  'Ciencias Sociales y Humanidades': 'Ciencias Sociales y Humanidades',
  'Ciencias Naturales y Exactas': 'Ciencias Naturales y Exactas',
  'Ciencias Económico Administrativas': 'Ciencias Económico Administrativas',
  'Educación y Artes': 'Educación y Artes',
};

class RepositoryFilters {
  const RepositoryFilters({
    this.search = '',
    this.author = '',
    this.date,
    this.clubId = '',
    this.category = '',
    this.area = '',
    this.sort = RepositorySort.newest,
  });

  final String search;
  final String author;
  final DateTime? date;
  final String clubId;
  final String category;
  final String area;
  final RepositorySort sort;

  String get cacheKey {
    return [
      search.trim().toLowerCase(),
      author.trim().toLowerCase(),
      date?.toIso8601String().split('T').first ?? '',
      clubId.trim(),
      category.trim(),
      area.trim(),
      sort.name,
    ].map(Uri.encodeComponent).join('|');
  }

  int get activeCount {
    return [
      search.trim(),
      author.trim(),
      date,
      clubId.trim(),
      category.trim(),
      area.trim(),
    ].where((value) {
      if (value == null) return false;
      return value is String ? value.isNotEmpty : true;
    }).length;
  }

  RepositoryFilters copyWith({
    String? search,
    String? author,
    DateTime? date,
    bool clearDate = false,
    String? clubId,
    String? category,
    String? area,
    RepositorySort? sort,
  }) {
    return RepositoryFilters(
      search: search ?? this.search,
      author: author ?? this.author,
      date: clearDate ? null : date ?? this.date,
      clubId: clubId ?? this.clubId,
      category: category ?? this.category,
      area: area ?? this.area,
      sort: sort ?? this.sort,
    );
  }
}

enum RepositorySort {
  newest('Más recientes'),
  oldest('Más antiguos'),
  title('Título A-Z');

  const RepositorySort(this.label);
  final String label;
}

class RepositoryDocument {
  const RepositoryDocument({
    required this.id,
    required this.title,
    required this.category,
    required this.createdAt,
    required this.fileUrls,
    required this.authorId,
    required this.clubId,
    required this.authorName,
    required this.clubName,
    required this.status,
    required this.description,
    required this.area,
    required this.tags,
    this.reviewComments,
  });

  final String id;
  final String title;
  final String category;
  final DateTime createdAt;
  final List<String> fileUrls;
  final String authorId;
  final String clubId;
  final String authorName;
  final String clubName;
  final String status;
  final String description;
  final String area;
  final List<String> tags;
  final String? reviewComments;

  /// Compatibilidad con consumidores antiguos que esperan un solo archivo.
  String get fileUrl => fileUrls.isEmpty ? '' : fileUrls.first;

  List<String> get downloadableFileUrls => fileUrls;

  factory RepositoryDocument.fromJson(Map<String, dynamic> json) {
    final profile = json['perfiles'] as Map<String, dynamic>?;
    final club = json['clubes'] as Map<String, dynamic>?;
    var fileUrls = _fileUrls(json['urls_archivos']);
    if (fileUrls.isEmpty) fileUrls = _fileUrls(json['fileUrls']);
    if (fileUrls.isEmpty) fileUrls = _fileUrls(json['fileUrl']);

    return RepositoryDocument(
      id: json['id'].toString(),
      title: (json['titulo'] ?? 'Documento sin título').toString(),
      category: (json['categoria'] ?? 'General').toString(),
      createdAt: DateTime.tryParse((json['fecha_creacion'] ?? '').toString()) ??
          DateTime.now(),
      fileUrls: fileUrls,
      authorId: (json['id_autor'] ?? '').toString(),
      clubId: (json['id_club'] ?? '').toString(),
      authorName:
          (profile?['nombre_completo'] ?? 'Autor no disponible').toString(),
      clubName: (club?['nombre'] ?? 'Club no disponible').toString(),
      status: (json['estado'] ?? 'pendiente').toString(),
      description: (json['descripcion'] ?? '').toString(),
      area: (json['area_conocimiento'] ?? '').toString(),
      tags: _tags(json['etiquetas']),
      reviewComments: json['comentarios_revision']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': title,
      'categoria': category,
      'fecha_creacion': createdAt.toIso8601String(),
      'urls_archivos': fileUrls,
      'id_autor': authorId,
      'id_club': clubId,
      'perfiles': {'nombre_completo': authorName},
      'clubes': {'nombre': clubName},
      'estado': status,
      'descripcion': description,
      'area_conocimiento': area,
      'etiquetas': tags,
      'comentarios_revision': reviewComments,
    };
  }

  static List<String> _fileUrls(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }
    return const [];
  }

  static List<String> _tags(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }
}

final repositoryFiltersProvider =
    NotifierProvider<RepositoryFiltersNotifier, RepositoryFilters>(
        RepositoryFiltersNotifier.new);

class RepositoryFiltersNotifier extends Notifier<RepositoryFilters> {
  @override
  RepositoryFilters build() => const RepositoryFilters();

  void setFilters(RepositoryFilters value) {
    state = value;
  }
}

final repositoryDocumentsProvider =
    FutureProvider.autoDispose<List<RepositoryDocument>>((ref) async {
  final filters = ref.watch(repositoryFiltersProvider);
  final cache = ref.read(appCacheServiceProvider);
  final supabase = ref.read(supabaseClientProvider);

  return cache.staleWhileRevalidate<List<RepositoryDocument>>(
    ref: ref,
    key: 'repository:documents:${filters.cacheKey}',
    ttl: CacheTtl.repository,
    fetch: () async {
      dynamic query = supabase.from('publicaciones_repositorio').select(
          'id, id_autor, id_club, titulo, descripcion, categoria, area_conocimiento, etiquetas, urls_archivos, estado, fecha_creacion, perfiles(nombre_completo), clubes(nombre)');

      if (filters.date != null) {
        final start = DateTime(
            filters.date!.year, filters.date!.month, filters.date!.day);
        final end = start.add(const Duration(days: 1));
        query = query
            .gte('fecha_creacion', start.toIso8601String())
            .lt('fecha_creacion', end.toIso8601String());
      }
      if (filters.clubId.isNotEmpty) {
        query = query.eq('id_club', filters.clubId);
      }
      if (filters.category.isNotEmpty) {
        query = query.eq('categoria', filters.category);
      }
      if (filters.area.isNotEmpty) {
        query = query.eq('area_conocimiento', filters.area);
      }

      switch (filters.sort) {
        case RepositorySort.newest:
          query = query.order('fecha_creacion', ascending: false);
          break;
        case RepositorySort.oldest:
          query = query.order('fecha_creacion', ascending: true);
          break;
        case RepositorySort.title:
          query = query.order('titulo', ascending: true);
          break;
      }

      final response = await query;
      final docs = (response as List<dynamic>)
          .map((item) => RepositoryDocument.fromJson(
              Map<String, dynamic>.from(item as Map)))
          .where((doc) {
        if (filters.author.trim().isEmpty) return true;
        return doc.authorName
            .toLowerCase()
            .contains(filters.author.trim().toLowerCase());
      }).where((doc) {
        final search = filters.search.trim().toLowerCase();
        if (search.isEmpty) return true;
        return doc.title.toLowerCase().contains(search) ||
            doc.description.toLowerCase().contains(search) ||
            doc.tags.any((tag) => tag.toLowerCase().contains(search));
      }).toList();

      return docs;
    },
    fromJson: (json) => (json as List<dynamic>)
        .map((item) =>
            RepositoryDocument.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(),
    toJson: (value) => value.map((doc) => doc.toJson()).toList(),
  );
});

final myDocumentsProvider =
    FutureProvider.autoDispose<List<RepositoryDocument>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final cache = ref.read(appCacheServiceProvider);
  return cache.staleWhileRevalidate<List<RepositoryDocument>>(
    ref: ref,
    key: 'repository:my_documents:${user.id}',
    ttl: CacheTtl.repository,
    fetch: () async {
      final response = await supabase
          .from('publicaciones_repositorio')
          .select(
            'id, id_autor, id_club, titulo, descripcion, categoria, '
            'area_conocimiento, etiquetas, urls_archivos, estado, '
            'fecha_creacion, comentarios_revision, '
            'perfiles(nombre_completo), clubes(nombre)',
          )
          .eq('id_autor', user.id)
          .order('fecha_creacion', ascending: false);

      return (response as List<dynamic>)
          .map(
            (item) => RepositoryDocument.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    },
    fromJson: (json) => (json as List<dynamic>)
        .map(
          (item) => RepositoryDocument.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false),
    toJson: (documents) =>
        documents.map((document) => document.toJson()).toList(growable: false),
  );
});

final repositoryCatalogProvider = FutureProvider.autoDispose<
    ({
      Map<String, String> clubs,
      Map<String, String> categories,
      Map<String, String> areas,
    })>((ref) async {
  final cache = ref.read(appCacheServiceProvider);
  final supabase = ref.read(supabaseClientProvider);

  return cache.staleWhileRevalidate<
      ({
        Map<String, String> clubs,
        Map<String, String> categories,
        Map<String, String> areas,
      })>(
    ref: ref,
    key: 'repository:catalog',
    ttl: CacheTtl.catalogs,
    fetch: () async {
      final results = await Future.wait([
        supabase.from('clubes').select('id, nombre').order('nombre'),
        supabase
            .from('publicaciones_repositorio')
            .select('categoria')
            .order('categoria'),
        supabase
            .from('publicaciones_repositorio')
            .select('area_conocimiento')
            .order('area_conocimiento'),
      ]);

      final clubs = <String, String>{'': 'Todos los clubes'};
      for (final row in results[0]) {
        clubs[row['id'].toString()] = row['nombre'].toString();
      }

      final categories = <String, String>{'': 'Todas las categorías'};
      for (final row in results[1]) {
        final value = (row['categoria'] ?? '').toString();
        if (value.isNotEmpty) categories[value] = value;
      }

      final areas = <String, String>{'': 'Todas las áreas'};
      for (final row in results[2]) {
        final value = (row['area_conocimiento'] ?? '').toString();
        if (value.isNotEmpty) areas[value] = value;
      }

      return (clubs: clubs, categories: categories, areas: areas);
    },
    fromJson: _repositoryCatalogFromJson,
    toJson: _repositoryCatalogToJson,
  );
});

({
  Map<String, String> clubs,
  Map<String, String> categories,
  Map<String, String> areas,
}) _repositoryCatalogFromJson(Object? json) {
  final map = Map<String, dynamic>.from(json as Map);
  return (
    clubs: Map<String, String>.from(map['clubs'] as Map),
    categories: Map<String, String>.from(map['categories'] as Map),
    areas: Map<String, String>.from(map['areas'] as Map),
  );
}

Map<String, dynamic> _repositoryCatalogToJson(
  ({
    Map<String, String> clubs,
    Map<String, String> categories,
    Map<String, String> areas,
  }) value,
) {
  return {
    'clubs': value.clubs,
    'categories': value.categories,
    'areas': value.areas,
  };
}

class RepositoryUploadInput {
  const RepositoryUploadInput({
    required this.title,
    required this.description,
    required this.category,
    required this.area,
    required this.tags,
    required this.files,
  });

  final String title;
  final String description;
  final String category;
  final String area;
  final List<String> tags;
  final List<PlatformFile> files;
}

final repositoryActionsProvider = Provider<RepositoryActions>((ref) {
  return RepositoryActions(ref);
});

final canDeleteRepositoryDocumentProvider = FutureProvider.autoDispose
    .family<bool, RepositoryDocument>((ref, document) async {
  final supabase = ref.read(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return false;
  if (document.authorId == user.id) return true;

  final profile = await supabase
      .from('perfiles')
      .select('id_club, rol, estado')
      .eq('id', user.id)
      .single();

  final role = (profile['rol'] ?? '').toString();
  final status = (profile['estado'] ?? '').toString();
  return status == 'activo' &&
      document.clubId == (profile['id_club'] ?? '').toString() &&
      (role == 'coordinador' || role == 'lider');
});

class RepositoryActions {
  RepositoryActions(this.ref);

  final Ref ref;

  Future<void> reviewDocument(
    String documentId,
    bool isApproved,
  ) async {
    final supabase = ref.read(supabaseClientProvider);

    await supabase.rpc(
      'revisar_publicacion_repositorio',
      params: {
        'p_id_publicacion': documentId,
        'p_aprobada': isApproved,
      },
    );

    final cache = ref.read(appCacheServiceProvider);
    await cache.invalidatePrefix('repository:');
    await cache.invalidatePrefix('club:');
    ref.invalidate(repositoryDocumentsProvider);
  }

  Future<String> uploadDocument(RepositoryUploadInput input) async {
    if (input.files.isEmpty || input.files.length > 3) {
      throw Exception('Selecciona entre 1 y 3 archivos.');
    }

    for (final file in input.files) {
      final fileBytes = file.bytes;
      if (fileBytes == null) {
        throw Exception('No se pudo leer el archivo "${file.name}".');
      }
      if (fileBytes.length > repositoryFileLimitBytes) {
        throw Exception('El archivo "${file.name}" no puede superar 10MB.');
      }
      final extension = file.extension?.toLowerCase() ?? 'bin';
      if (!_allowedExtensions.contains(extension)) {
        throw Exception(
          'El formato de "${file.name}" no está permitido. '
          'Usa PDF, DOC, DOCX, TXT, JPG, PNG o JPEG.',
        );
      }
    }

    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Debes iniciar sesión para subir documentos.');
    }

    final profile = await supabase
        .from('perfiles')
        .select('id_club, rol')
        .eq('id', user.id)
        .single();

    final uploadId = DateTime.now().microsecondsSinceEpoch;
    final paths = <String>[
      for (var index = 0; index < input.files.length; index++)
        '${user.id}/${uploadId}_${index}_'
            '${input.files[index].name.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_')}',
    ];

    try {
      await Future.wait([
        for (var index = 0; index < input.files.length; index++)
          supabase.storage.from('repositorio').uploadBinary(
                paths[index],
                input.files[index].bytes!,
                fileOptions: FileOptions(
                  upsert: false,
                  contentType: _contentType(
                    input.files[index].extension?.toLowerCase() ?? 'bin',
                  ),
                ),
              ),
      ]);

      final urls = paths
          .map(
            (path) => supabase.storage.from('repositorio').getPublicUrl(path),
          )
          .toList(growable: false);

      await supabase.from('publicaciones_repositorio').insert({
        'titulo': input.title.trim(),
        'descripcion': input.description.trim(),
        'categoria': repositoryCategoryOptions.containsKey(input.category)
            ? input.category
            : repositoryCategoryOptions.keys.first,
        'area_conocimiento': repositoryAreaOptions.containsKey(input.area)
            ? input.area
            : repositoryAreaOptions.keys.first,
        'etiquetas': input.tags.take(4).toList(),
        'urls_archivos': urls,
        'id_autor': user.id,
        'id_club': profile['id_club'],
      });
    } catch (error) {
      try {
        await supabase.storage.from('repositorio').remove(paths);
      } catch (_) {
        // Conserva el error original si tampoco se pudo completar el rollback.
      }
      throw Exception(
        'No se pudieron subir todos los archivos. '
        'Verifica tu conexión y vuelve a intentarlo.',
      );
    }

    await ref.read(appCacheServiceProvider).invalidatePrefix('repository:');
    ref.invalidate(repositoryDocumentsProvider);
    ref.invalidate(myDocumentsProvider);
    ref.invalidate(pendingDocumentsProvider);
    return 'pendiente';
  }

  Future<void> resubmitDocument({
    required RepositoryDocument document,
    required String title,
    required String description,
    required List<PlatformFile> replacementFiles,
  }) async {
    if (title.trim().isEmpty) {
      throw Exception('Ingresa el título del documento.');
    }

    if (replacementFiles.length > 3) {
      throw Exception('Selecciona un máximo de 3 archivos.');
    }

    for (final file in replacementFiles) {
      final fileBytes = file.bytes;
      if (fileBytes == null) {
        throw Exception('No se pudo leer el archivo "${file.name}".');
      }
      if (fileBytes.length > repositoryFileLimitBytes) {
        throw Exception('El archivo "${file.name}" no puede superar 10MB.');
      }
      final extension = file.extension?.toLowerCase() ?? 'bin';
      if (!_allowedExtensions.contains(extension)) {
        throw Exception(
          'El formato de "${file.name}" no está permitido. '
          'Usa PDF, DOC, DOCX, TXT, JPG, PNG o JPEG.',
        );
      }
    }

    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Debes iniciar sesión para reenviar documentos.');
    }

    final replacementPaths = <String>[];
    var urls = document.fileUrls;

    try {
      if (replacementFiles.isNotEmpty) {
        final uploadId = DateTime.now().microsecondsSinceEpoch;
        for (var index = 0; index < replacementFiles.length; index++) {
          final file = replacementFiles[index];
          replacementPaths.add(
            '${user.id}/${uploadId}_${index}_'
            '${file.name.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_')}',
          );
        }

        await Future.wait([
          for (var index = 0; index < replacementFiles.length; index++)
            supabase.storage.from('repositorio').uploadBinary(
                  replacementPaths[index],
                  replacementFiles[index].bytes!,
                  fileOptions: FileOptions(
                    upsert: false,
                    contentType: _contentType(
                      replacementFiles[index].extension?.toLowerCase() ?? 'bin',
                    ),
                  ),
                ),
        ]);

        urls = replacementPaths
            .map(
              (path) => supabase.storage.from('repositorio').getPublicUrl(path),
            )
            .toList(growable: false);
      }

      if (urls.isEmpty) {
        throw Exception('El documento debe conservar al menos un archivo.');
      }

      await supabase.rpc(
        'reenviar_publicacion',
        params: {
          'p_id_publicacion': document.id,
          'p_nuevo_titulo': title.trim(),
          'p_nueva_descripcion': description.trim(),
          'p_nuevas_urls': urls,
        },
      );
    } catch (error) {
      if (replacementPaths.isNotEmpty) {
        try {
          await supabase.storage.from('repositorio').remove(replacementPaths);
        } catch (_) {
          // Conserva el error original si el rollback de Storage falla.
        }
      }
      rethrow;
    }

    if (replacementFiles.isNotEmpty) {
      final previousPaths = document.fileUrls
          .map(_storagePathFromPublicUrl)
          .whereType<String>()
          .toList(growable: false);
      if (previousPaths.isNotEmpty) {
        try {
          await supabase.storage.from('repositorio').remove(previousPaths);
        } catch (_) {
          // El reenvío ya fue confirmado; una limpieza fallida no lo revierte.
        }
      }
    }

    await ref.read(appCacheServiceProvider).invalidatePrefix('repository:');
    ref.invalidate(repositoryDocumentsProvider);
    ref.invalidate(myDocumentsProvider);
    ref.invalidate(pendingDocumentsProvider);
  }

  Future<void> deleteDocument(RepositoryDocument document) async {
    final supabase = ref.read(supabaseClientProvider);

    // 🛡️ 1. PRIMERO: Intentar borrar el registro de la base de datos
    await supabase
        .from('publicaciones_repositorio')
        .delete()
        .eq('id', document.id);

    // 🛡️ 2. SEGUNDO: Si la BD tuvo éxito, procedemos a limpiar Storage
    final paths = <String>[];
    for (final fileUrl in document.fileUrls) {
      final path = _storagePathFromPublicUrl(fileUrl);
      if (path != null) paths.add(path);
    }

    if (paths.isNotEmpty) {
      try {
        await supabase.storage.from('repositorio').remove(paths);
      } catch (_) {
        // Ignorar falla silenciosa: Es preferible tener un archivo huérfano que romper el flujo
      }
    }

    // 3. Invalida cachés
    await ref.read(appCacheServiceProvider).invalidatePrefix('repository:');
    await ref
        .read(appCacheServiceProvider)
        .invalidate('club:${document.clubId}:docs_count');
    ref.invalidate(repositoryDocumentsProvider);
    ref.invalidate(myDocumentsProvider);
  }

  String? _storagePathFromPublicUrl(String url) {
    const marker = '/storage/v1/object/public/repositorio/';
    final index = url.indexOf(marker);
    if (index == -1) return null;
    final rawPath = url.substring(index + marker.length);
    return Uri.decodeComponent(rawPath);
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  static const _allowedExtensions = {
    'pdf',
    'doc',
    'docx',
    'txt',
    'jpg',
    'jpeg',
    'png',
  };
}
