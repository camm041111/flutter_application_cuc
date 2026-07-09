import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/cache/app_cache_service.dart';

// ─── MODELOS ─────────────────────────────────────────────────────────────

class NewsPost {
  const NewsPost({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.clubName,
    required this.authorName,
    required this.authorId,
    required this.clubId,
    required this.tags,
    required this.likesCount,
    required this.isLikedByMe,
  });

  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final String clubName;
  final String authorName;
  final String authorId;
  final String clubId;
  final List<String> tags;
  final int likesCount;
  final bool isLikedByMe;

  factory NewsPost.fromJson(Map<String, dynamic> json, String currentUserId) {
    final club = json['clubes'] as Map<String, dynamic>?;
    final autor = json['perfiles'] as Map<String, dynamic>?;
    final likesArray = json['likes_noticias'] as List<dynamic>? ?? [];

    return NewsPost(
      id: json['id'].toString(),
      title: (json['titulo'] ?? '').toString(),
      content: (json['contenido'] ?? '').toString(),
      imageUrl: json['url_imagen']?.toString(),
      createdAt: DateTime.tryParse((json['fecha_creacion'] ?? '').toString()) ?? DateTime.now(),
      clubName: (club?['nombre'] ?? 'Club Desconocido').toString(),
      authorName: (autor?['nombre_completo'] ?? 'Autor').toString(),
      authorId: (json['id_autor'] ?? '').toString(),
      clubId: (json['id_club'] ?? '').toString(),
      tags: (json['etiquetas'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      likesCount: (json['likes_count'] ?? 0) as int,
      isLikedByMe: likesArray.isNotEmpty,
    );
  }
}

class NewsInput {
  final String title;
  final String content;
  final XFile? imageFile;
  final List<String> tags;

  NewsInput({
    required this.title,
    required this.content,
    this.imageFile,
    this.tags = const [],
  });
}

// ─── PROVIDERS DE ESTADO MODERNIZADOS ────────────────────────────────────

// Reemplazamos StateProvider por un Notifier robusto para el buscador
final newsSearchProvider = NotifierProvider<NewsSearchNotifier, String>(NewsSearchNotifier.new);

class NewsSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setSearch(String query) {
    state = query;
  }
}

final canPublishNewsProvider = FutureProvider.autoDispose<bool>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return false;

  final profile = await supabase.from('perfiles').select('rol, estado').eq('id', user.id).single();
  final role = (profile['rol'] ?? '').toString();
  final status = (profile['estado'] ?? '').toString();

  return status == 'activo' && (role == 'coordinador' || role == 'lider');
});

final newsProvider = FutureProvider.autoDispose<List<NewsPost>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final cache = ref.read(appCacheServiceProvider);
  final user = supabase.auth.currentUser;
  final searchQuery = ref.watch(newsSearchProvider).toLowerCase();

  if (user == null) return [];

  return cache.staleWhileRevalidate<List<NewsPost>>(
    ref: ref,
    key: 'explore:news_feed_$searchQuery',
    ttl: const Duration(minutes: 5),
    fetch: () async {
      // ARQUITECTURA SEGURA: Instanciamos la consulta base
      var query = supabase
          .from('noticias')
          .select('''
            id, titulo, contenido, url_imagen, fecha_creacion, id_autor, id_club, etiquetas, likes_count,
            perfiles:perfiles!noticias_id_autor_fkey(nombre_completo),
            clubes(nombre),
            likes_noticias(id_usuario)
          ''');

      // 1. Aplicamos filtros (.eq, .ilike) SIEMPRE antes que el .order y el .limit
      query = query.eq('likes_noticias.id_usuario', user.id);

      if (searchQuery.isNotEmpty) {
        query = query.ilike('titulo', '%$searchQuery%');
      }

      // 2. Aplicamos modificadores al final y disparamos la petición
      final response = await query.order('fecha_creacion', ascending: false).limit(50);

      return (response as List<dynamic>)
          .map((item) => NewsPost.fromJson(Map<String, dynamic>.from(item as Map), user.id))
          .toList();
    },
    fromJson: (json) => (json as List<dynamic>).map((item) => NewsPost.fromJson(item, user.id)).toList(),
    toJson: (value) => [],
  );
});

// ─── ACCIONES (Lógica de Negocio) ────────────────────────────────────────

final exploreActionsProvider = Provider<ExploreActions>((ref) => ExploreActions(ref));

class ExploreActions {
  ExploreActions(this.ref);
  final Ref ref;

  Future<bool> toggleLike(String newsId) async {
    final supabase = ref.read(supabaseClientProvider);
    try {
      await supabase.rpc('toggle_like_noticia', params: {'p_id_noticia': newsId});
      ref.invalidate(newsProvider);
      return true;
    } catch (e) {
      debugPrint('Error al dar like: $e');
      return false;
    }
  }

  Future<bool> deleteNews(String newsId) async {
    final supabase = ref.read(supabaseClientProvider);
    try {
      await supabase.from('noticias').delete().eq('id', newsId);
      ref.invalidate(newsProvider);
      return true;
    } catch (e) {
      debugPrint('Bloqueo por RLS al intentar borrar noticia: $e');
      return false;
    }
  }

  Future<void> createNews(NewsInput input) async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('No autenticado');

    final profile = await supabase.from('perfiles').select('id_club, rol, estado').eq('id', user.id).single();
    if (profile['estado'] != 'activo' || (profile['rol'] != 'coordinador' && profile['rol'] != 'lider')) {
      throw Exception('Permisos insuficientes para publicar.');
    }

    String? imageUrl;
    if (input.imageFile != null) {
      final bytes = await input.imageFile!.readAsBytes();
      final fileExt = input.imageFile!.path.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${user.id}.$fileExt';

      await supabase.storage.from('noticias').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      imageUrl = supabase.storage.from('noticias').getPublicUrl(fileName);
    }

    await supabase.from('noticias').insert({
      'titulo': input.title.trim(),
      'contenido': input.content.trim(),
      'id_autor': user.id,
      'id_club': profile['id_club'],
      'url_imagen': imageUrl,
      'etiquetas': input.tags,
    });

    ref.read(appCacheServiceProvider).invalidatePrefix('explore:news');
    ref.invalidate(newsProvider);
  }
}