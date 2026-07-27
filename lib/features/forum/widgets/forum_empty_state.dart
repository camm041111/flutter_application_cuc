part of 'forum_view.dart';

class _ForumEmptyState extends StatelessWidget {
  const _ForumEmptyState({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Icon(Icons.forum_outlined,
                  color: AppColors.muted, size: 36),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }
}

const _rootReplyKey = '__root__';

Map<String, List<ForumReply>> _childrenByParentId(List<ForumReply> replies) {
  final grouped = <String, List<ForumReply>>{};
  for (final reply in replies) {
    final parentKey = reply.parentReplyId ?? _rootReplyKey;
    grouped.putIfAbsent(parentKey, () => <ForumReply>[]).add(reply);
  }
  return grouped;
}
