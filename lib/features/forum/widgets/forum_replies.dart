part of 'forum_view.dart';

class _ForumRepliesSection extends StatelessWidget {
  const _ForumRepliesSection({
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
  // 🧠 MICRO-ESTADO: Controlamos los votos en la memoria RAM del Widget
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
    if (_isProcessing) return;

    // 1. Mutación Optimista: UI instantánea
    setState(() {
      _isProcessing = true;
      if (up) {
        _localUpVotes++;
      } else {
        _localDownVotes++;
      }
    });

    // 2. Ejecución asíncrona en Supabase
    final success = await ref.read(forumActionsProvider).voteReply(widget.reply, up: up);

    if (mounted) {
      // 3. Rollback en caso de fallo de red (Fail-Safe)
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
    return Container(
      margin: EdgeInsets.only(left: widget.depth * 18.0, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface, // Asumiendo tu gris oscuro de fondo (no negro puro)
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: widget.depth == 0
                ? AppColors.border
                : AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ForumUserAvatar(
                name: widget.reply.authorName,
                imageUrl: widget.reply.authorAvatarUrl,
                size: 32,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.reply.authorName,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis),
                    Text(widget.reply.authorMeta,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.muted),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.reply.content,
              style: const TextStyle(fontSize: 13, height: 1.45)),
          const SizedBox(height: 8),
          Row(
            children: [
              _CompactReplyAction(
                icon: Icons.thumb_up_alt_outlined,
                tooltip: 'Me gusta',
                count: _localUpVotes,
                onPressed: () => _handleVote(up: true),
              ),
              _CompactReplyAction(
                icon: Icons.thumb_down_alt_outlined,
                tooltip: 'No me gusta',
                count: _localDownVotes,
                muted: true,
                onPressed: () => _handleVote(up: false),
              ),
              if (widget.onReply != null)
                TextButton.icon(
                  onPressed: widget.onReply,
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
          if (widget.childCount > 0) ...[
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: widget.onToggleChildren,
                icon: Icon(
                  widget.childrenExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                label: Text(
                  widget.childrenExpanded
                      ? 'Ocultar comentarios'
                      : widget.childCount == 1
                      ? 'Ver 1 comentario'
                      : 'Ver ${widget.childCount} comentarios',
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
