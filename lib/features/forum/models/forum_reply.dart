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
  top('Mas votadas');

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
