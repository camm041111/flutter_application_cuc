import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../social/social_providers.dart';
import '../models/forum_thread.dart';
import '../providers/forum_providers.dart';
import 'forum_replies_section.dart';
import 'forum_reply_composer.dart';

class ForumThreadDetailSheet extends ConsumerStatefulWidget {
  const ForumThreadDetailSheet({super.key, required this.thread});

  final ForumThread thread;

  @override
  ConsumerState<ForumThreadDetailSheet> createState() =>
      _ForumThreadDetailSheetState();
}

class _ForumThreadDetailSheetState
    extends ConsumerState<ForumThreadDetailSheet> {
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
                          return ForumRepliesSection(
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
                ForumReplyComposer(
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
