import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/forum_providers.dart';
import 'forum_user_avatar.dart' as forum_widgets;

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
        _ReplyTile(
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

class _ReplyTile extends ConsumerStatefulWidget {
  const _ReplyTile({
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
  ConsumerState<_ReplyTile> createState() => _ReplyTileState();
}

class _ReplyTileState extends ConsumerState<_ReplyTile> {
  late int _localUpVotes;
  late int _localDownVotes;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _syncWithProvider();
  }

  @override
  void didUpdateWidget(covariant _ReplyTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reply.id != widget.reply.id ||
        oldWidget.reply.upVotes != widget.reply.upVotes ||
        oldWidget.reply.downVotes != widget.reply.downVotes) {
      _syncWithProvider();
    }
  }

  void _syncWithProvider() {
    _localUpVotes = widget.reply.upVotes;
    _localDownVotes = widget.reply.downVotes;
  }

  Future<void> _handleVote({required bool up}) async {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
      if (up) {
        _localUpVotes++;
      } else {
        _localDownVotes++;
      }
    });

    final success =
        await ref.read(forumActionsProvider).voteReply(widget.reply, up: up);

    if (mounted) {
      if (!success) {
        setState(() {
          if (up) {
            _localUpVotes--;
          } else {
            _localDownVotes--;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fallo de conexión al servidor.')),
        );
      }
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(currentUserProfileProvider).value;
    final isReadOnly = userProfile?.estado != 'activo';
    // Definimos el color de la línea de jerarquía.
    // Usamos el verde institucional primario para respuestas directas y un gris tenue para sub-respuestas.
    final depthColor = widget.depth == 1
        ? AppColors.primary.withValues(alpha: 0.5)
        : AppColors.border;

    return Container(
      margin: EdgeInsets.only(
        left: widget.depth == 0 ? 0 : 16.0,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        // Borde izquierdo minimalista para indicar la profundidad del comentario
        border: widget.depth > 0
            ? Border(left: BorderSide(color: depthColor, width: 2.0))
            : null,
      ),
      padding: EdgeInsets.only(
        left: widget.depth > 0 ? 12.0 : 0,
        top: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              forum_widgets.ForumUserAvatar(
                name: widget.reply.authorName,
                imageUrl: widget.reply.authorAvatarUrl,
                size: 28, // Reducido para mayor elegancia
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.reply.authorName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2, // Estética moderna
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 6),
                    const Text('•',
                        style: TextStyle(color: AppColors.muted, fontSize: 10)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.reply.authorMeta,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.reply.content,
            style: const TextStyle(
              fontSize:
                  14, // Aumentado ligeramente para mejor lectura científica
              height: 1.5,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          // todoen una sola línea horizontal
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!isReadOnly) ...[
                _CompactActionBtn(
                  icon: Icons.keyboard_arrow_up_rounded,
                  count: _localUpVotes,
                  onPressed: () => _handleVote(up: true),
                  isActive: false,
                ),
                _CompactActionBtn(
                  icon: Icons.keyboard_arrow_down_rounded,
                  count: _localDownVotes,
                  onPressed: () => _handleVote(up: false),
                  isMuted: true,
                ),
              ],
              const Spacer(), // Empuja las respuestas a la derecha
              if (widget.childCount > 0)
                _TextActionBtn(
                  icon: widget.childrenExpanded
                      ? Icons.unfold_less_rounded
                      : Icons.chat_bubble_outline_rounded,
                  label: widget.childrenExpanded
                      ? 'Ocultar'
                      : '${widget.childCount} res',
                  onPressed: widget.onToggleChildren,
                  color: AppColors.muted,
                ),
              if (!isReadOnly && widget.onReply != null)
                _TextActionBtn(
                  icon: Icons.reply_rounded,
                  label: 'Responder',
                  onPressed: widget.onReply,
                  color: AppColors.primary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Botón estandarizado para Upvotes / Downvotes
class _CompactActionBtn extends StatelessWidget {
  const _CompactActionBtn({
    required this.icon,
    required this.onPressed,
    required this.count,
    this.isMuted = false,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final int count;
  final bool isMuted;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? AppColors.primary
        : (isMuted
            ? AppColors.muted
            : AppColors.onSurface.withValues(alpha: 0.7));

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón estandarizado para Texto (Responder, Ver comentarios)
class _TextActionBtn extends StatelessWidget {
  const _TextActionBtn({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12, // 🛡️ Tipografía estrictamente alineada
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
