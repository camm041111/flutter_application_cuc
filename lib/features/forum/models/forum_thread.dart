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

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const [];
}
