import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/app_cache_service.dart';
import '../../core/providers/supabase_provider.dart';

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

class NewsInput {
  const NewsInput({required this.title, required this.content, this.imageUrl});
  final String title;
  final String content;
  final String? imageUrl;
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
