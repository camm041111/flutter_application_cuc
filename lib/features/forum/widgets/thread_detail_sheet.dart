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
      // 🛡️ ARQUITECTURA: Delegamos la transacción al Action unificado del Foro
      await ref.read(forumActionsProvider).createReply(
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

    final profileAsync = ref.watch(currentUserProfileProvider);

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
              color: AppColors.background, // Gris oscuro definido en tu tema
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    // 🛡️ Padding ajustado para permitir que el macro-divisor abarque todo el ancho
                    padding: const EdgeInsets.only(bottom: 18),
                    children: [
                      // ─── ZONA 1: LA FUENTE DE LA VERDAD (PREGUNTA PRINCIPAL) ───
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.thread.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),

                      // Metadatos consolidados del autor del hilo
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            ForumUserAvatar(
                              name: widget.thread.authorName,
                              imageUrl: widget.thread.authorAvatarUrl,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.thread.authorName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    widget.thread.authorMeta,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Cuerpo Markdown de la pregunta
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: MarkdownBody(
                          data: widget.thread.content,
                          selectable: true,
                          onTapLink: (text, href, title) async {
                            if (href != null) {
                              final url = Uri.parse(href);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            }
                          },
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              fontSize: 14.5,
                              height: 1.6,
                              color: AppColors.onSurface,
                            ),
                            a: const TextStyle(
                              color: AppColors.primary, // Acento visual con color institucional
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                            strong: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                            em: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: AppColors.muted,
                            ),
                            code: const TextStyle(
                              backgroundColor: AppColors.background,
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                          ),
                        ),
                      ),


                      Container(
                        width: double.infinity,
                        height: 6,
                        color: AppColors.border.withValues(alpha: 0.3),
                      ),


                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        child: Row(
                          children: [
                            const Icon(Icons.forum_outlined, size: 18, color: AppColors.muted),
                            const SizedBox(width: 8),
                            Text(
                              'Discusión (${widget.thread.replyCount})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.muted,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: repliesAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          ),
                          error: (error, _) => Text(
                            '$error',
                            style: const TextStyle(color: AppColors.error),
                          ),
                          data: (replies) {
                            if (replies.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                  child: Text(
                                    'No hay respuestas aún.\nSé el primero en aportar.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.muted, height: 1.5),
                                  ),
                                ),
                              );
                            }
                            return _ForumRepliesSection(
                              replies: replies,
                              expandedReplyIds: _expandedReplyIds,
                              showAllReplies: _showAllReplies,
                              onShowAllReplies: () => setState(() => _showAllReplies = true),
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

  // 🛡️ ARQUITECTURA: Se asegura un tipado estricto hacia la clase oficial UserProfile
  final AsyncValue<UserProfile?> profileAsync;
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
              // 🛡️ ARQUITECTURA: Zero Trust UI. Validación estricta usando el estado de UserProfile
              if (profile?.estado != 'activo') {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Tu perfil está en modo solo lectura.',
                    style: TextStyle(color: AppColors.muted),
                    textAlign: TextAlign.center,
                  ),
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