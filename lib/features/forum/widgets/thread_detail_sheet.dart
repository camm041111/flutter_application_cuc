part of 'forum_view.dart';

class _ThreadDetailSheet extends ConsumerStatefulWidget {
  const _ThreadDetailSheet({required this.thread});

  final ForumThread thread;

  @override
  ConsumerState<_ThreadDetailSheet> createState() => _ThreadDetailSheetState();
}

class _ThreadDetailSheetState extends ConsumerState<_ThreadDetailSheet> {
  final _replyCtrl = TextEditingController();
  final _replyFocusNode = FocusNode();
  final _expandedReplyIds = <String>{};
  String? _parentReplyId;
  String? _parentReplyAuthor;
  bool _showAllReplies = false;
  bool _saving = false;

  @override
  void dispose() {
    _replyFocusNode.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(socialActionsProvider).createReply(
            threadId: widget.thread.id,
            content: text,
            parentReplyId: _parentReplyId,
          );
      _replyCtrl.clear();
      setState(() {
        if (_parentReplyId != null) {
          _expandedReplyIds.add(_parentReplyId!);
        }
        _parentReplyId = null;
        _parentReplyAuthor = null;
        _showAllReplies = true;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo responder: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repliesAsync = ref.watch(forumRepliesProvider(widget.thread.id));
    final profileAsync = ref.watch(currentSocialProfileProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.thread.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      Text(
                        widget.thread.authorMeta,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.thread.content,
                        style: const TextStyle(height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Respuestas',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      repliesAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        error: (error, _) => Text(
                          '$error',
                          style: const TextStyle(color: AppColors.error),
                        ),
                        data: (replies) {
                          if (replies.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'Se el primero en responder.',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            );
                          }
                          return _ForumRepliesSection(
                            replies: replies,
                            expandedReplyIds: _expandedReplyIds,
                            showAllReplies: _showAllReplies,
                            onShowAllReplies: () =>
                                setState(() => _showAllReplies = true),
                            onToggleChildren: (replyId) {
                              setState(() {
                                if (_expandedReplyIds.contains(replyId)) {
                                  _expandedReplyIds.remove(replyId);
                                } else {
                                  _expandedReplyIds.add(replyId);
                                }
                              });
                            },
                            onReply: (reply) {
                              setState(() {
                                _parentReplyId = reply.id;
                                _parentReplyAuthor = reply.authorName;
                                _expandedReplyIds.add(reply.id);
                              });
                              _replyFocusNode.requestFocus();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                _ReplyComposerBar(
                  profileAsync: profileAsync,
                  controller: _replyCtrl,
                  focusNode: _replyFocusNode,
                  parentReplyAuthor: _parentReplyAuthor,
                  saving: _saving,
                  onClearParent: () => setState(() {
                    _parentReplyId = null;
                    _parentReplyAuthor = null;
                  }),
                  onSubmit: _submitReply,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReplyComposerBar extends StatelessWidget {
  const _ReplyComposerBar({
    required this.profileAsync,
    required this.controller,
    required this.focusNode,
    required this.parentReplyAuthor,
    required this.saving,
    required this.onClearParent,
    required this.onSubmit,
  });

  final AsyncValue<SocialProfile?> profileAsync;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? parentReplyAuthor;
  final bool saving;
  final VoidCallback onClearParent;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: profileAsync.maybeWhen(
            data: (profile) {
              if (profile?.isActive != true) {
                return const Text(
                  'Tu perfil esta en modo solo lectura.',
                  style: TextStyle(color: AppColors.muted),
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (parentReplyAuthor != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InputChip(
                        label: Text('Respondiendo a $parentReplyAuthor'),
                        onDeleted: onClearParent,
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: 'Escribe un comentario...',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Enviar comentario',
                        onPressed: saving ? null : onSubmit,
                        icon: saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.background,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                      ),
                    ],
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
