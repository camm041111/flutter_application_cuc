import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';

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
  'Ciencias Económico Administrativas':
      'Ciencias Económico Administrativas',
  'Educación y Artes': 'Educación y Artes',
};

class RepositoryFilters {
  const RepositoryFilters({
    this.search = '',
    this.author = '',
    this.date,
    this.clubId = '',
    this.category = '',
  });

  final String search;
  final String author;
  final DateTime? date;
  final String clubId;
  final String category;

  int get activeCount {
    return [
      search.trim(),
      author.trim(),
      date,
      clubId.trim(),
      category.trim(),
    ].where((value) {
      if (value == null) return false;
      return value is String ? value.isNotEmpty : true;
    }).length;
  }
}

class RepositoryDocument {
  const RepositoryDocument({
    required this.id,
    required this.title,
    required this.category,
    required this.createdAt,
    required this.fileUrl,
    required this.authorId,
    required this.clubId,
    required this.authorName,
    required this.clubName,
    required this.status,
  });

  final String id;
  final String title;
  final String category;
  final DateTime createdAt;
  final String fileUrl;
  final String authorId;
  final String clubId;
  final String authorName;
  final String clubName;
  final String status;

  factory RepositoryDocument.fromJson(Map<String, dynamic> json) {
    final profile = json['perfiles'] as Map<String, dynamic>?;
    final club = json['clubes'] as Map<String, dynamic>?;

    return RepositoryDocument(
      id: json['id'].toString(),
      title: (json['titulo'] ?? 'Documento sin título').toString(),
      category: (json['categoria'] ?? 'General').toString(),
      createdAt: DateTime.tryParse((json['fecha_creacion'] ?? '').toString()) ??
          DateTime.now(),
      fileUrl: _firstFileUrl(json['urls_archivos']),
      authorId: (json['id_autor'] ?? '').toString(),
      clubId: (json['id_club'] ?? '').toString(),
      authorName:
          (profile?['nombre_completo'] ?? 'Autor no disponible').toString(),
      clubName: (club?['nombre'] ?? 'Club no disponible').toString(),
      status: (json['estado'] ?? 'pendiente').toString(),
    );
  }

  static String _firstFileUrl(dynamic value) {
    if (value is List && value.isNotEmpty) {
      return value.first.toString();
    }
    return '';
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
  final supabase = ref.read(supabaseClientProvider);

  dynamic query = supabase
      .from('publicaciones_repositorio')
      .select(
          'id, id_autor, id_club, titulo, categoria, urls_archivos, estado, fecha_creacion, perfiles(nombre_completo), clubes(nombre)')
      .eq('estado', 'aprobado');

  if (filters.search.trim().isNotEmpty) {
    query = query.ilike('titulo', '%${filters.search.trim()}%');
  }
  if (filters.date != null) {
    final start =
        DateTime(filters.date!.year, filters.date!.month, filters.date!.day);
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

  final response = await query.order('fecha_creacion', ascending: false);
  final docs = (response as List<dynamic>)
      .map((item) =>
          RepositoryDocument.fromJson(Map<String, dynamic>.from(item as Map)))
      .where((doc) {
    if (filters.author.trim().isEmpty) return true;
    return doc.authorName
        .toLowerCase()
        .contains(filters.author.trim().toLowerCase());
  }).toList();

  return docs;
});

final repositoryCatalogProvider = FutureProvider.autoDispose<
    ({Map<String, String> clubs, Map<String, String> categories})>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final results = await Future.wait([
    supabase.from('clubes').select('id, nombre').order('nombre'),
    supabase
        .from('publicaciones_repositorio')
        .select('categoria')
        .order('categoria'),
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

  return (clubs: clubs, categories: categories);
});

class RepositoryUploadInput {
  const RepositoryUploadInput({
    required this.title,
    required this.category,
    required this.area,
    required this.file,
  });

  final String title;
  final String category;
  final String area;
  final PlatformFile file;
}

final repositoryActionsProvider = Provider<RepositoryActions>((ref) {
  return RepositoryActions(ref);
});

final canDeleteRepositoryDocumentProvider =
    FutureProvider.autoDispose.family<bool, RepositoryDocument>((ref, document) async {
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

  Future<String> uploadDocument(RepositoryUploadInput input) async {
    final fileBytes = input.file.bytes;
    if (fileBytes == null) {
      throw Exception('No se pudo leer el archivo seleccionado.');
    }
    if (fileBytes.length > repositoryFileLimitBytes) {
      throw Exception('El archivo no puede superar 10MB.');
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
    final role = (profile['rol'] ?? '').toString();
    final status =
        role == 'coordinador' || role == 'lider' ? 'aprobado' : 'pendiente';

    final extension = input.file.extension?.toLowerCase() ?? 'bin';
    final safeName =
        input.file.name.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    final path =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    await supabase.storage.from('repositorio').uploadBinary(
          path,
          fileBytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: _contentType(extension),
          ),
        );

    final url = supabase.storage.from('repositorio').getPublicUrl(path);
    await supabase.from('publicaciones_repositorio').insert({
      'titulo': input.title.trim(),
      'descripcion': '',
      'categoria': repositoryCategoryOptions.containsKey(input.category)
          ? input.category
          : repositoryCategoryOptions.keys.first,
      'area_conocimiento': repositoryAreaOptions.containsKey(input.area)
          ? input.area
          : repositoryAreaOptions.keys.first,
      'etiquetas': <String>[],
      'urls_archivos': [url],
      'id_autor': user.id,
      'id_club': profile['id_club'],
      'estado': status,
    });

    ref.invalidate(repositoryDocumentsProvider);
    return status;
  }

  Future<void> deleteDocument(RepositoryDocument document) async {
    final supabase = ref.read(supabaseClientProvider);
    final paths = <String>[];
    if (document.fileUrl.isNotEmpty) {
      final path = _storagePathFromPublicUrl(document.fileUrl);
      if (path != null) paths.add(path);
    }

    if (paths.isNotEmpty) {
      await supabase.storage.from('repositorio').remove(paths);
    }

    await supabase
        .from('publicaciones_repositorio')
        .delete()
        .eq('id', document.id);

    ref.invalidate(repositoryDocumentsProvider);
  }

  String? _storagePathFromPublicUrl(String url) {
    final marker = '/storage/v1/object/public/repositorio/';
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
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }
}
