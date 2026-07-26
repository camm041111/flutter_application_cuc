import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../models/forum_reply.dart';
import '../providers/forum_providers.dart';
import 'forum_user_avatar.dart';

class ForumReplyTile extends ConsumerWidget {
  const ForumReplyTile({
    super.key,
    required this.reply,
    required this.depth,
    required this.childCount,
    required this.childrenExpanded,
    required this.onToggleChildren,
    required this.onReply,
  });

  final ForumReply reply;
  final int depth;
  final int childCount;
  final bool childrenExpanded;
  final VoidCallback? onToggleChildren;
  final VoidCallback? onReply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: EdgeInsets.only(left: depth * 18.0, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: depth == 0
                ? AppColors.border
                : AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ForumUserAvatar(
                name: reply.authorName,
                imageUrl: reply.authorAvatarUrl,
                size: 32,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reply.authorName,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis),
                    Text(reply.authorMeta,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.muted),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(reply.content,
              style: const TextStyle(fontSize: 13, height: 1.45)),
          const SizedBox(height: 8),
          Row(
            children: [
              _CompactReplyAction(
                icon: Icons.thumb_up_alt_outlined,
                tooltip: 'Me gusta',
                count: reply.upVotes,
                onPressed: () =>
                    ref.read(forumActionsProvider).voteReply(reply, up: true),
              ),
              _CompactReplyAction(
                icon: Icons.thumb_down_alt_outlined,
                tooltip: 'No me gusta',
                count: reply.downVotes,
                muted: true,
                onPressed: () =>
                    ref.read(forumActionsProvider).voteReply(reply, up: false),
              ),
              if (onReply != null)
                TextButton.icon(
                  onPressed: onReply,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Responder'),
                ),
            ],
          ),
          if (childCount > 0) ...[
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onToggleChildren,
                icon: Icon(
                  childrenExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                label: Text(
                  childrenExpanded
                      ? 'Ocultar comentarios'
                      : childCount == 1
                          ? 'Ver 1 comentario'
                          : 'Ver $childCount comentarios',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactReplyAction extends StatelessWidget {
  const _CompactReplyAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.count,
    this.muted = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final int count;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? AppColors.muted : AppColors.primary;
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        foregroundColor: color,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      icon: Icon(icon, size: 17),
      label: Text(count.toString()),
    );
  }
}
