import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';

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
  });

  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final String clubName;
  final String authorName;

  factory NewsPost.fromJson(Map<String, dynamic> json) {
    final club = json['clubes'] as Map<String, dynamic>?;
    final autor = json['perfiles'] as Map<String, dynamic>?;

    return NewsPost(
      id: json['id'].toString(),
      title: (json['titulo'] ?? '').toString(),
      content: (json['contenido'] ?? '').toString(),
      imageUrl: json['url_imagen']?.toString(),
      createdAt: DateTime.tryParse((json['fecha_creacion'] ?? '').toString()) ?? DateTime.now(),
      clubName: (club?['nombre'] ?? 'Club Desconocido').toString(),
      authorName: (autor?['nombre_completo'] ?? 'Usuario').toString(),
    );
  }
}

class NewsInput {
  const NewsInput({
    required this.title,
    required this.content,
    this.imageUrl,
  });

  final String title;
  final String content;
  final String? imageUrl;
}

// ─── ESTADOS Y PERMISOS ──────────────────────────────────────────────────

// En Riverpod 3, abandonamos StateProvider. Usamos Notifier de forma limpia.
class NewsSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setSearch(String query) {
    state = query;
  }
}

final newsSearchProvider = NotifierProvider<NewsSearchNotifier, String>(NewsSearchNotifier.new);

// FutureProvider nativo (En Riverpod 3 se optimiza la recolección de basura)
final canPublishNewsProvider = FutureProvider<bool>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return false;

  final profile = await supabase
      .from('perfiles')
      .select('rol, estado, id_club')
      .eq('id', user.id)
      .single();

  final role = (profile['rol'] ?? '').toString();
  final status = (profile['estado'] ?? '').toString();
  final clubId = profile['id_club'];

  return status == 'activo' && clubId != null && (role == 'coordinador' || role == 'lider');
});

// ─── PAGINACIÓN Y FEED PRINCIPAL ─────────────────────────────────────────

// En Riverpod 3, AutoDisposeAsyncNotifier se fusionó en AsyncNotifier.
class NewsNotifier extends AsyncNotifier<List<NewsPost>> {
  int _page = 0;
  final int _pageSize = 10;
  bool hasReachedMax = false;

  @override
  Future<List<NewsPost>> build() async {
    _page = 0;
    hasReachedMax = false;
    return _fetchPage(0);
  }

  Future<List<NewsPost>> _fetchPage(int pageIndex) async {
    final supabase = ref.read(supabaseClientProvider);
    final search = ref.watch(newsSearchProvider);

    int start = pageIndex * _pageSize;
    int end = start + _pageSize - 1;

    // 1. Consulta base (PostgrestFilterBuilder)
    var query = supabase
        .from('noticias')
        .select('id, titulo, contenido, url_imagen, fecha_creacion, clubes(nombre), perfiles(nombre_completo)');

    // 2. Aplicamos los filtros condicionales
    if (search.trim().isNotEmpty) {
      query = query.ilike('titulo', '%${search.trim()}%');
    }

    // 3. Finalmente aplicamos el ordenamiento y la paginación
    final response = await query
        .order('fecha_creacion', ascending: false)
        .range(start, end);

    final data = response as List<dynamic>;

    if (data.length < _pageSize) {
      hasReachedMax = true;
    }

    return data.map((item) => NewsPost.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<void> loadMore() async {
    if (state.isLoading || hasReachedMax) return;

    final currentList = state.value ?? [];

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      _page++;
      final newPosts = await _fetchPage(_page);
      return [...currentList, ...newPosts];
    });
  }
}

// Declaración limpia del provider usando el constructor .new (característica de Dart moderno + Riverpod 3)
final newsProvider = AsyncNotifierProvider<NewsNotifier, List<NewsPost>>(NewsNotifier.new);

// ─── ACCIONES (MUTACIONES) ───────────────────────────────────────────────

final exploreActionsProvider = Provider<ExploreActions>((ref) => ExploreActions(ref));

class ExploreActions {
  ExploreActions(this.ref);
  final Ref ref;

  Future<void> createNews(NewsInput input) async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Debes iniciar sesión.');

    final profile = await supabase
        .from('perfiles')
        .select('id_club, rol, estado')
        .eq('id', user.id)
        .single();

    final role = (profile['rol'] ?? '').toString();
    final status = (profile['estado'] ?? '').toString();
    final clubId = profile['id_club'];

    if (status != 'activo' || clubId == null || (role != 'coordinador' && role != 'lider')) {
      throw Exception('No tienes permisos para publicar noticias.');
    }

    if (input.title.trim().isEmpty || input.content.trim().isEmpty) {
      throw Exception('El título y el contenido son obligatorios.');
    }

    await supabase.from('noticias').insert({
      'id_club': clubId,
      'id_autor': user.id,
      'titulo': input.title.trim(),
      'contenido': input.content.trim(),
      'url_imagen': input.imageUrl?.trim(),
    });

    ref.invalidate(newsProvider);
  }
}