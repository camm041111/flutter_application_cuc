import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/app_cache_service.dart';
import '../../../core/providers/supabase_provider.dart';
// 🛡️ Importación del núcleo oficial de identidad
import '../../profile/providers/profile_providers.dart';
import '../../repository/providers/repository_providers.dart';
const int forumMaxReplyDepth = 2;
// ─── MODELOS DEL FORO ──────────────────────────────────────────────────

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
      title: (json['titulo'] ?? 'Hilo sin título').toString(),
      content: (json['contenido'] ?? '').toString(),
      area: (json['area_conocimiento'] ?? '').toString(),
      tags: _stringList(json['etiquetas']).take(3).toList(),
      upVotes: int.tryParse((json['votos_positivos'] ?? 0).toString()) ?? 0,
      downVotes: int.tryParse((json['votos_negativos'] ?? 0).toString()) ?? 0,
      createdAt: DateTime.tryParse((json['fecha_creacion'] ?? '').toString()) ?? DateTime.now(),
      authorName: (profile?['nombre_completo'] ?? 'Usuario CUC').toString(),
      authorMeta: '${club?['nombre'] ?? 'Club CUC'} • ${division?['acronimo'] ?? 'CUC'}',
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
      createdAt: DateTime.tryParse((json['fecha_creacion'] ?? '').toString()) ?? DateTime.now(),
      authorName: (profile?['nombre_completo'] ?? 'Usuario CUC').toString(),
      authorMeta: '${club?['nombre'] ?? 'Club CUC'} • ${division?['acronimo'] ?? 'CUC'}',
      authorAvatarUrl: (profile?['url_avatar'] ?? '').toString(),
      parentReplyId: parent?.toString(),
    );
  }
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

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList();
  }
  return const [];
}

// ─── FILTROS Y ESTADOS DEL FORO ────────────────────────────────────────

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

  String get cacheKey => '${Uri.encodeComponent(search.trim().toLowerCase())}|$area|${sort.name}';

  ForumFilters copyWith({String? search, String? area, ForumSort? sort}) {
    return ForumFilters(
      search: search ?? this.search,
      area: area ?? this.area,
      sort: sort ?? this.sort,
    );
  }
}

final forumFiltersProvider = NotifierProvider<ForumFiltersNotifier, ForumFilters>(ForumFiltersNotifier.new);

class ForumFiltersNotifier extends Notifier<ForumFilters> {
  @override
  ForumFilters build() => const ForumFilters();

  void setSearch(String value) => state = state.copyWith(search: value);
  void setArea(String value) => state = state.copyWith(area: value);
  void setSort(ForumSort value) => state = state.copyWith(sort: value);
}

// ─── PROVIDERS DE DATOS ────────────────────────────────────────────────

final forumThreadsProvider = FutureProvider.autoDispose<List<ForumThread>>((ref) async {
  final filters = ref.watch(forumFiltersProvider);
  final cache = ref.read(appCacheServiceProvider);
  final supabase = ref.read(supabaseClientProvider);

  return cache.staleWhileRevalidate<List<ForumThread>>(
    ref: ref,
    key: 'forum:threads:${filters.cacheKey}',
    ttl: CacheTtl.repository,
    fetch: () async {
// FASE 1: Construcción y Filtrado (PostgrestFilterBuilder)
      var filterBuilder = supabase.from('preguntas_foro').select(
          'id, id_autor, titulo, contenido, area_conocimiento, etiquetas, votos_positivos, votos_negativos, fecha_creacion, perfiles(nombre_completo, url_avatar, clubes(nombre), divisiones_academicas(acronimo)), respuestas_foro(id)');

      if (filters.area.isNotEmpty) {
        filterBuilder = filterBuilder.eq('area_conocimiento', filters.area);
      }

      // FASE 2: Transformación y Ordenamiento (PostgrestTransformBuilder)
      // Declaramos explícitamente el tipo de la variable final
      PostgrestTransformBuilder<List<Map<String, dynamic>>> transformBuilder;

      switch (filters.sort) {
        case ForumSort.newest:
          transformBuilder = filterBuilder.order('fecha_creacion', ascending: false);
          break;
        case ForumSort.oldest:
          transformBuilder = filterBuilder.order('fecha_creacion', ascending: true);
          break;
        case ForumSort.top:
          transformBuilder = filterBuilder.order('votos_positivos', ascending: false);
          break;
      }

      // FASE 3: Ejecución atómica
      final response = await transformBuilder;
      return (response as List<dynamic>)
          .map((row) => ForumThread.fromJson(Map<String, dynamic>.from(row as Map)))
          .where((thread) {
        final search = filters.search.trim().toLowerCase();
        if (search.isEmpty) return true;
        return thread.title.toLowerCase().contains(search) ||
            thread.content.toLowerCase().contains(search) ||
            thread.tags.any((tag) => tag.toLowerCase().contains(search));
      }).toList();
    },
    fromJson: (json) => (json as List<dynamic>).map((row) => ForumThread.fromJson(Map<String, dynamic>.from(row as Map))).toList(),
    toJson: (threads) => threads.map((thread) => {
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
      'respuestas_foro': List.generate(thread.replyCount, (index) => {'id': index}),
    }).toList(),
  );
});

final forumRepliesProvider = FutureProvider.autoDispose.family<List<ForumReply>, String>((ref, threadId) async {
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

// ─── LOGICA DE NEGOCIO Y ACCIONES ──────────────────────────────────────

final forumActionsProvider = Provider<ForumActions>((ref) => ForumActions(ref));

class ForumActions {
  ForumActions(this.ref);
  final Ref ref;

  /// 🛡️ INYECCIÓN DE IDENTIDAD: Usamos el provider oficial del núcleo
  Future<UserProfile> _requireActiveProfile() async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Debes iniciar sesión.');
    }

    // Leemos tu perfil oficial directamente[cite: 24]
    final profile = await ref.read(profileProvider(user.id).future);

    if (profile.estado != 'activo') {
      throw Exception('Tu perfil está en modo solo lectura. No puedes participar en el foro.');
    }

    return profile;
  }

  Future<void> createThread(ForumThreadInput input) async {
    final profile = await _requireActiveProfile();
    final supabase = ref.read(supabaseClientProvider);

    await supabase.from('preguntas_foro').insert({
      'id_autor': profile.id, // Obtenido de UserProfile[cite: 24]
      'titulo': input.title.trim(),
      'contenido': input.content.trim(),
      'area_conocimiento': repositoryAreaOptions.containsKey(input.area)
          ? input.area
          : repositoryAreaOptions.keys.first,
      'etiquetas': input.tags.take(3).toList(),
    });

    await ref.read(appCacheServiceProvider).invalidatePrefix('forum:threads');
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
      'id_autor': profile.id, // Obtenido de UserProfile[cite: 24]
      'contenido': content.trim(),
      'id_respuesta_padre': parentReplyId,
    });

    await ref.read(appCacheServiceProvider).invalidatePrefix('forum:threads');
    ref.invalidate(forumThreadsProvider);
    ref.invalidate(forumRepliesProvider(threadId));
  }

  Future<bool> voteReply(ForumReply reply, {required bool up}) async {
    await _requireActiveProfile();
    final supabase = ref.read(supabaseClientProvider);

    try {
      await supabase.rpc('votar_respuesta_foro', params: {
        'p_id_respuesta': reply.id,
        'p_valor': up ? 1 : -1,
      });
      ref.invalidate(forumRepliesProvider(reply.threadId));
      return true;
    } catch (e) {
      debugPrint('Error arquitectónico/BD al votar: $e');
      return false;
    }
  }
}