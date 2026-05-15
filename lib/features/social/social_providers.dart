import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/app_cache_service.dart';
import '../../core/providers/supabase_provider.dart';
import '../repository/providers/repository_providers.dart';

const forumMaxReplyDepth = 2;

class SocialProfile {
  const SocialProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.clubId,
    required this.clubName,
    required this.divisionAcronym,
  });

  final String id;
  final String name;
  final String role;
  final String status;
  final String clubId;
  final String clubName;
  final String divisionAcronym;

  bool get isActive => status == 'activo';
  bool get canPublishOfficial =>
      isActive && (role == 'lider' || role == 'coordinador');
}

SocialProfile _profileFromJson(Map<String, dynamic> json) {
  final club = json['clubes'] as Map<String, dynamic>?;
  final division = json['divisiones_academicas'] as Map<String, dynamic>?;
  return SocialProfile(
    id: (json['id'] ?? '').toString(),
    name: (json['nombre_completo'] ?? 'Usuario CUC').toString(),
    role: (json['rol'] ?? 'miembro').toString(),
    status: (json['estado'] ?? 'registrado').toString(),
    clubId: (json['id_club'] ?? '').toString(),
    clubName: (club?['nombre'] ?? 'Club sin asignar').toString(),
    divisionAcronym: (division?['acronimo'] ?? 'CUC').toString(),
  );
}

final currentSocialProfileProvider =
    FutureProvider.autoDispose<SocialProfile?>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return null;

  final response = await supabase
      .from('perfiles')
      .select(
          'id, nombre_completo, rol, estado, id_club, clubes(nombre), divisiones_academicas(acronimo)')
      .eq('id', user.id)
      .maybeSingle();
  if (response == null) return null;
  return _profileFromJson(response);
});

class NewsPost {
  const NewsPost({
    required this.id,
    required this.clubId,
    required this.authorId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.authorName,
    required this.clubName,
    this.imageUrl,
  });

  final String id;
  final String clubId;
  final String authorId;
  final String title;
  final String content;
  final DateTime createdAt;
  final String authorName;
  final String clubName;
  final String? imageUrl;

  factory NewsPost.fromJson(Map<String, dynamic> json) {
    final author = json['perfiles'] as Map<String, dynamic>?;
    final club = json['clubes'] as Map<String, dynamic>?;
    return NewsPost(
      id: json['id'].toString(),
      clubId: (json['id_club'] ?? '').toString(),
      authorId: (json['id_autor'] ?? '').toString(),
      title: (json['titulo'] ?? 'Noticia sin titulo').toString(),
      content: (json['contenido'] ?? '').toString(),
      imageUrl: json['url_imagen']?.toString(),
      createdAt: DateTime.tryParse((json['fecha_creacion'] ?? '').toString()) ??
          DateTime.now(),
      authorName: (author?['nombre_completo'] ?? 'CUC').toString(),
      clubName: (club?['nombre'] ?? 'Club CUC').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'id_club': clubId,
        'id_autor': authorId,
        'titulo': title,
        'contenido': content,
        'url_imagen': imageUrl,
        'fecha_creacion': createdAt.toIso8601String(),
        'perfiles': {'nombre_completo': authorName},
        'clubes': {'nombre': clubName},
      };
}

final newsSearchProvider =
    NotifierProvider<NewsSearchNotifier, String>(NewsSearchNotifier.new);

class NewsSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setSearch(String value) => state = value;
}

final newsProvider = FutureProvider.autoDispose<List<NewsPost>>((ref) async {
  final search = ref.watch(newsSearchProvider).trim().toLowerCase();
  final cache = ref.read(appCacheServiceProvider);
  final supabase = ref.read(supabaseClientProvider);

  return cache.staleWhileRevalidate<List<NewsPost>>(
    ref: ref,
    key: 'social:news:$search',
    ttl: CacheTtl.repository,
    fetch: () async {
      final response = await supabase
          .from('noticias')
          .select(
              'id, id_club, id_autor, titulo, contenido, url_imagen, fecha_creacion, perfiles(nombre_completo), clubes(nombre)')
          .order('fecha_creacion', ascending: false);
      return (response as List<dynamic>)
          .map(
              (row) => NewsPost.fromJson(Map<String, dynamic>.from(row as Map)))
          .where((post) {
        if (search.isEmpty) return true;
        return post.title.toLowerCase().contains(search) ||
            post.content.toLowerCase().contains(search) ||
            post.clubName.toLowerCase().contains(search);
      }).toList();
    },
    fromJson: (json) => (json as List<dynamic>)
        .map((row) => NewsPost.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(),
    toJson: (posts) => posts.map((post) => post.toJson()).toList(),
  );
});

final canPublishNewsProvider = FutureProvider.autoDispose<bool>((ref) async {
  final profile = await ref.watch(currentSocialProfileProvider.future);
  return profile?.canPublishOfficial == true && profile!.clubId.isNotEmpty;
});

class ForumThread {
  const ForumThread({
    required this.id,
    required this.authorId,
    required this.title,
    required this.content,
    required this.area,
    required this.tags,
    required this.upVotes,
    required this.downVotes,
    required this.createdAt,
    required this.authorName,
    required this.authorMeta,
    required this.authorAvatarUrl,
    required this.replyCount,
  });

  final String id;
  final String authorId;
  final String title;
  final String content;
  final String area;
  final List<String> tags;
  final int upVotes;
  final int downVotes;
  final DateTime createdAt;
  final String authorName;
  final String authorMeta;
  final String authorAvatarUrl;
  final int replyCount;

  int get score => upVotes - downVotes;

  factory ForumThread.fromJson(Map<String, dynamic> json) {
    final profile = json['perfiles'] as Map<String, dynamic>?;
    final club = profile?['clubes'] as Map<String, dynamic>?;
    final division = profile?['divisiones_academicas'] as Map<String, dynamic>?;
    final replies = json['respuestas_foro'];
    return ForumThread(
      id: json['id'].toString(),
      authorId: (json['id_autor'] ?? '').toString(),
      title: (json['titulo'] ?? 'Hilo sin titulo').toString(),
      content: (json['contenido'] ?? '').toString(),
      area: (json['area_conocimiento'] ?? '').toString(),
      tags: _stringList(json['etiquetas']).take(3).toList(),
      upVotes: int.tryParse((json['votos_positivos'] ?? 0).toString()) ?? 0,
      downVotes: int.tryParse((json['votos_negativos'] ?? 0).toString()) ?? 0,
      createdAt: DateTime.tryParse((json['fecha_creacion'] ?? '').toString()) ??
          DateTime.now(),
      authorName: (profile?['nombre_completo'] ?? 'Usuario CUC').toString(),
      authorMeta:
          '${club?['nombre'] ?? 'Club CUC'} • ${division?['acronimo'] ?? 'CUC'}',
      authorAvatarUrl: (profile?['url_avatar'] ?? '').toString(),
      replyCount: replies is List ? replies.length : 0,
    );
  }
}

class ForumReply {
  const ForumReply({
    required this.id,
    required this.threadId,
    required this.authorId,
    required this.content,
    required this.upVotes,
    required this.downVotes,
    required this.isCorrect,
    required this.createdAt,
    required this.authorName,
    required this.authorMeta,
    required this.authorAvatarUrl,
    this.parentReplyId,
  });

  final String id;
  final String threadId;
  final String authorId;
  final String content;
  final int upVotes;
  final int downVotes;
  final bool isCorrect;
  final DateTime createdAt;
  final String authorName;
  final String authorMeta;
  final String authorAvatarUrl;
  final String? parentReplyId;

  int get score => upVotes - downVotes;

  factory ForumReply.fromJson(Map<String, dynamic> json) {
    final profile = json['perfiles'] as Map<String, dynamic>?;
    final club = profile?['clubes'] as Map<String, dynamic>?;
    final division = profile?['divisiones_academicas'] as Map<String, dynamic>?;
    final parent = json['id_respuesta_padre'];
    return ForumReply(
      id: json['id'].toString(),
      threadId: (json['id_pregunta'] ?? '').toString(),
      authorId: (json['id_autor'] ?? '').toString(),
      content: (json['contenido'] ?? '').toString(),
      upVotes: int.tryParse((json['votos_positivos'] ?? 0).toString()) ?? 0,
      downVotes: int.tryParse((json['votos_negativos'] ?? 0).toString()) ?? 0,
      isCorrect: json['es_correcta'] == true,
      createdAt: DateTime.tryParse((json['fecha_creacion'] ?? '').toString()) ??
          DateTime.now(),
      authorName: (profile?['nombre_completo'] ?? 'Usuario CUC').toString(),
      authorMeta:
          '${club?['nombre'] ?? 'Club CUC'} • ${division?['acronimo'] ?? 'CUC'}',
      authorAvatarUrl: (profile?['url_avatar'] ?? '').toString(),
      parentReplyId: parent?.toString(),
    );
  }
}

enum ForumSort {
  newest('Recientes'),
  oldest('Antiguas'),
  top('Más votadas');

  const ForumSort(this.label);
  final String label;
}

class ForumFilters {
  const ForumFilters({
    this.search = '',
    this.area = '',
    this.sort = ForumSort.newest,
  });

  final String search;
  final String area;
  final ForumSort sort;

  String get cacheKey =>
      '${Uri.encodeComponent(search.trim().toLowerCase())}|$area|${sort.name}';

  ForumFilters copyWith({String? search, String? area, ForumSort? sort}) {
    return ForumFilters(
      search: search ?? this.search,
      area: area ?? this.area,
      sort: sort ?? this.sort,
    );
  }
}

final forumFiltersProvider =
    NotifierProvider<ForumFiltersNotifier, ForumFilters>(
        ForumFiltersNotifier.new);

class ForumFiltersNotifier extends Notifier<ForumFilters> {
  @override
  ForumFilters build() => const ForumFilters();

  void setSearch(String value) => state = state.copyWith(search: value);
  void setArea(String value) => state = state.copyWith(area: value);
  void setSort(ForumSort value) => state = state.copyWith(sort: value);
}

final forumThreadsProvider =
    FutureProvider.autoDispose<List<ForumThread>>((ref) async {
  final filters = ref.watch(forumFiltersProvider);
  final cache = ref.read(appCacheServiceProvider);
  final supabase = ref.read(supabaseClientProvider);

  return cache.staleWhileRevalidate<List<ForumThread>>(
    ref: ref,
    key: 'social:forum:${filters.cacheKey}',
    ttl: CacheTtl.repository,
    fetch: () async {
      dynamic query = supabase.from('preguntas_foro').select(
          'id, id_autor, titulo, contenido, area_conocimiento, etiquetas, votos_positivos, votos_negativos, fecha_creacion, perfiles(nombre_completo, url_avatar, clubes(nombre), divisiones_academicas(acronimo)), respuestas_foro(id)');
      if (filters.area.isNotEmpty) {
        query = query.eq('area_conocimiento', filters.area);
      }
      switch (filters.sort) {
        case ForumSort.newest:
          query = query.order('fecha_creacion', ascending: false);
          break;
        case ForumSort.oldest:
          query = query.order('fecha_creacion', ascending: true);
          break;
        case ForumSort.top:
          query = query.order('votos_positivos', ascending: false);
          break;
      }

      final response = await query;
      return (response as List<dynamic>)
          .map((row) =>
              ForumThread.fromJson(Map<String, dynamic>.from(row as Map)))
          .where((thread) {
        final search = filters.search.trim().toLowerCase();
        if (search.isEmpty) return true;
        return thread.title.toLowerCase().contains(search) ||
            thread.content.toLowerCase().contains(search) ||
            thread.tags.any((tag) => tag.toLowerCase().contains(search));
      }).toList();
    },
    fromJson: (json) => (json as List<dynamic>)
        .map((row) =>
            ForumThread.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(),
    toJson: (threads) => threads
        .map((thread) => {
              'id': thread.id,
              'id_autor': thread.authorId,
              'titulo': thread.title,
              'contenido': thread.content,
              'area_conocimiento': thread.area,
              'etiquetas': thread.tags,
              'votos_positivos': thread.upVotes,
              'votos_negativos': thread.downVotes,
              'fecha_creacion': thread.createdAt.toIso8601String(),
              'perfiles': {
                'nombre_completo': thread.authorName,
                'url_avatar': thread.authorAvatarUrl,
              },
              'respuestas_foro':
                  List.generate(thread.replyCount, (index) => {'id': index}),
            })
        .toList(),
  );
});

final forumRepliesProvider = FutureProvider.autoDispose
    .family<List<ForumReply>, String>((ref, threadId) async {
  final supabase = ref.read(supabaseClientProvider);
  final response = await supabase
      .from('respuestas_foro')
      .select(
          'id, id_pregunta, id_autor, contenido, votos_positivos, votos_negativos, es_correcta, fecha_creacion, id_respuesta_padre, perfiles(nombre_completo, url_avatar, clubes(nombre), divisiones_academicas(acronimo))')
      .eq('id_pregunta', threadId)
      .order('fecha_creacion', ascending: true);
  return (response as List<dynamic>)
      .map((row) => ForumReply.fromJson(Map<String, dynamic>.from(row as Map)))
      .toList();
});

class NewsInput {
  const NewsInput({required this.title, required this.content, this.imageUrl});
  final String title;
  final String content;
  final String? imageUrl;
}

class ForumThreadInput {
  const ForumThreadInput({
    required this.title,
    required this.content,
    required this.area,
    required this.tags,
  });

  final String title;
  final String content;
  final String area;
  final List<String> tags;
}

final socialActionsProvider =
    Provider<SocialActions>((ref) => SocialActions(ref));

class SocialActions {
  SocialActions(this.ref);
  final Ref ref;

  Future<void> createNews(NewsInput input) async {
    final profile = await _requireActiveProfile();
    if (!profile.canPublishOfficial || profile.clubId.isEmpty) {
      throw Exception(
          'Solo lideres y coordinadores activos pueden publicar noticias.');
    }
    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('noticias').insert({
      'id_club': profile.clubId,
      'id_autor': profile.id,
      'titulo': input.title.trim(),
      'contenido': input.content.trim(),
      'url_imagen': input.imageUrl?.trim().isEmpty == true
          ? null
          : input.imageUrl?.trim(),
    });
    await ref.read(appCacheServiceProvider).invalidatePrefix('social:news');
    ref.invalidate(newsProvider);
  }

  Future<void> createThread(ForumThreadInput input) async {
    final profile = await _requireActiveProfile();
    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('preguntas_foro').insert({
      'id_autor': profile.id,
      'titulo': input.title.trim(),
      'contenido': input.content.trim(),
      'area_conocimiento': repositoryAreaOptions.containsKey(input.area)
          ? input.area
          : repositoryAreaOptions.keys.first,
      'etiquetas': input.tags.take(3).toList(),
    });
    await ref.read(appCacheServiceProvider).invalidatePrefix('social:forum');
    ref.invalidate(forumThreadsProvider);
  }

  Future<void> createReply({
    required String threadId,
    required String content,
    String? parentReplyId,
  }) async {
    final profile = await _requireActiveProfile();
    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('respuestas_foro').insert({
      'id_pregunta': threadId,
      'id_autor': profile.id,
      'contenido': content.trim(),
      'id_respuesta_padre': parentReplyId,
    });
    await ref.read(appCacheServiceProvider).invalidatePrefix('social:forum');
    ref.invalidate(forumThreadsProvider);
    ref.invalidate(forumRepliesProvider(threadId));
  }

  Future<void> voteReply(ForumReply reply, {required bool up}) async {
    await _requireActiveProfile();
    final supabase = ref.read(supabaseClientProvider);
    await supabase.rpc('votar_respuesta_foro', params: {
      'p_id_respuesta': reply.id,
      'p_valor': up ? 1 : -1,
    });
    ref.invalidate(forumRepliesProvider(reply.threadId));
  }

  Future<SocialProfile> _requireActiveProfile() async {
    final profile = await ref.read(currentSocialProfileProvider.future);
    if (profile == null) {
      throw Exception('Debes iniciar sesion.');
    }
    if (!profile.isActive) {
      throw Exception('Tu perfil esta en modo solo lectura.');
    }
    return profile;
  }
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const [];
}
