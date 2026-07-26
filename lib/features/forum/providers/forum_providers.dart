import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/app_cache_service.dart';
import '../../../core/constants/areas.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../social/social_providers.dart';
import '../models/forum_reply.dart';
import '../models/forum_thread.dart';

const forumMaxReplyDepth = 2;

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
        case ForumSort.oldest:
          query = query.order('fecha_creacion', ascending: true);
        case ForumSort.top:
          query = query.order('votos_positivos', ascending: false);
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

final forumActionsProvider = Provider<ForumActions>((ref) => ForumActions(ref));

class ForumActions {
  ForumActions(this.ref);
  final Ref ref;

  Future<void> createThread(ForumThreadInput input) async {
    final profile = await _requireActiveProfile();
    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('preguntas_foro').insert({
      'id_autor': profile.id,
      'titulo': input.title.trim(),
      'contenido': input.content.trim(),
      'area_conocimiento':
          areaOptions.containsKey(input.area) ? input.area : areaOptions.keys.first,
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

  Future<Map<String, dynamic>?> voteQuestion(
      String questionId, int value) async {
    final supabase = ref.read(supabaseClientProvider);
    if (value != 1 && value != -1) return null;
    try {
      final response = await supabase.rpc(
        'votar_pregunta_foro',
        params: {'p_id_pregunta': questionId, 'p_valor': value},
      );
      await ref.read(appCacheServiceProvider).invalidatePrefix('forum:');
      return Map<String, dynamic>.from(response as Map);
    } on PostgrestException {
      return null;
    } catch (_) {
      return null;
    }
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
