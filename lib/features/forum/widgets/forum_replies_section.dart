import 'package:flutter/material.dart';

import '../models/forum_reply.dart';
import '../providers/forum_providers.dart';
import 'forum_reply_tile.dart';

const _rootReplyKey = '__root__';

Map<String, List<ForumReply>> _childrenByParentId(List<ForumReply> replies) {
  final grouped = <String, List<ForumReply>>{};
  for (final reply in replies) {
    final parentKey = reply.parentReplyId ?? _rootReplyKey;
    grouped.putIfAbsent(parentKey, () => <ForumReply>[]).add(reply);
  }
  return grouped;
}

class ForumRepliesSection extends StatelessWidget {
  const ForumRepliesSection({
    super.key,
    required this.replies,
    required this.expandedReplyIds,
    required this.showAllReplies,
    required this.onShowAllReplies,
    required this.onToggleChildren,
    required this.onReply,
  });

  static const int _previewCount = 3;

  final List<ForumReply> replies;
  final Set<String> expandedReplyIds;
  final bool showAllReplies;
  final VoidCallback onShowAllReplies;
  final ValueChanged<String> onToggleChildren;
  final ValueChanged<ForumReply> onReply;

  @override
  Widget build(BuildContext context) {
    final childrenByParentId = _childrenByParentId(replies);
    final roots = childrenByParentId[_rootReplyKey] ?? const <ForumReply>[];
    final visibleRoots =
        showAllReplies ? roots : roots.take(_previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...visibleRoots.map(
          (reply) => _buildReplyBranch(
            reply: reply,
            depth: 0,
            childrenByParentId: childrenByParentId,
          ),
        ),
        if (!showAllReplies && roots.length > _previewCount)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onShowAllReplies,
              icon: const Icon(Icons.expand_more, size: 18),
              label:
                  Text('Ver ${roots.length - _previewCount} comentarios mas'),
            ),
          ),
      ],
    );
  }

  Widget _buildReplyBranch({
    required ForumReply reply,
    required int depth,
    required Map<String, List<ForumReply>> childrenByParentId,
  }) {
    final children = childrenByParentId[reply.id] ?? const <ForumReply>[];
    final isExpanded = expandedReplyIds.contains(reply.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ForumReplyTile(
          reply: reply,
          depth: depth,
          childCount: children.length,
          childrenExpanded: isExpanded,
          onToggleChildren:
              children.isEmpty ? null : () => onToggleChildren(reply.id),
          onReply: depth >= forumMaxReplyDepth ? null : () => onReply(reply),
        ),
        if (isExpanded)
          ...children.map(
            (child) => _buildReplyBranch(
              reply: child,
              depth: depth + 1,
              childrenByParentId: childrenByParentId,
            ),
          ),
      ],
    );
  }
}
