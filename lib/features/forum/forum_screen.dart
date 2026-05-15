import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/app_cache_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cuc_app_bar.dart';
import '../repository/providers/repository_providers.dart';
import '../social/social_providers.dart';

class ForumScreen extends ConsumerWidget {
  const ForumScreen({super.key});

  void _openThreadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ThreadComposerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(forumThreadsProvider);
    final profileAsync = ref.watch(currentSocialProfileProvider);

    return Scaffold(
      appBar: const CucAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(appCacheServiceProvider)
              .invalidatePrefix('social:forum');
          ref.invalidate(forumThreadsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _ForumFiltersBar()),
            threadsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (error, _) => SliverFillRemaining(
                child: _ForumEmptyState(
                  title: 'No se pudo cargar el foro',
                  subtitle: '$error',
                ),
              ),
              data: (threads) {
                if (threads.isEmpty) {
                  return const SliverFillRemaining(
                    child: _ForumEmptyState(
                      title: 'Sin hilos de discusion',
                      subtitle:
                          'Las preguntas tecnicas de la comunidad apareceran aqui.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList.separated(
                    itemCount: threads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) =>
                        _ForumThreadCard(thread: threads[index]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: profileAsync.maybeWhen(
        data: (profile) => profile?.isActive == true
            ? FloatingActionButton(
                onPressed: () => _openThreadSheet(context),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                child: const Icon(Icons.add_comment_outlined),
              )
            : null,
        orElse: () => null,
      ),
    );
  }
}

class _ForumFiltersBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(forumFiltersProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar hilos, etiquetas o contenido...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) =>
                ref.read(forumFiltersProvider.notifier).setSearch(value),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: filters.area,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Todas las areas',
                          overflow: TextOverflow.ellipsis),
                    ),
                    ...repositoryAreaOptions.entries.map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child:
                            Text(entry.value, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) => ref
                      .read(forumFiltersProvider.notifier)
                      .setArea(value ?? ''),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<ForumSort>(
                  initialValue: filters.sort,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: ForumSort.values
                      .map(
                        (sort) => DropdownMenuItem(
                          value: sort,
                          child:
                              Text(sort.label, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(forumFiltersProvider.notifier).setSort(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ForumThreadCard extends StatelessWidget {
  const _ForumThreadCard({required this.thread});

  final ForumThread thread;

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ThreadDetailSheet(thread: thread),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _areaColor(thread.area);
    return InkWell(
      onTap: () => _openDetail(context),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ForumUserAvatar(
                    name: thread.authorName,
                    imageUrl: thread.authorAvatarUrl,
                    size: 36,
                    color: color,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(thread.authorName,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis),
                        Text(
                          '${thread.authorMeta} • ${_relativeTime(thread.createdAt)}',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(thread.title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                thread.content,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.muted, height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Chip(
                      label:
                          Text(thread.area.isEmpty ? 'General' : thread.area)),
                  ...thread.tags.map((tag) => Chip(label: Text(tag))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 16, color: AppColors.muted),
                  const SizedBox(width: 5),
                  Text('${thread.replyCount} comentarios',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted)),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

class _ReplyTile extends ConsumerWidget {
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
                    ref.read(socialActionsProvider).voteReply(reply, up: true),
              ),
              _CompactReplyAction(
                icon: Icons.thumb_down_alt_outlined,
                tooltip: 'No me gusta',
                count: reply.downVotes,
                muted: true,
                onPressed: () =>
                    ref.read(socialActionsProvider).voteReply(reply, up: false),
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

class _ThreadComposerSheet extends ConsumerStatefulWidget {
  const _ThreadComposerSheet();

  @override
  ConsumerState<_ThreadComposerSheet> createState() =>
      _ThreadComposerSheetState();
}

class _ThreadComposerSheetState extends ConsumerState<_ThreadComposerSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _tags = <String>[];
  String _area = repositoryAreaOptions.keys.first;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _addTag(String value) {
    final tag = value.trim();
    if (tag.isEmpty || _tags.contains(tag) || _tags.length >= 3) return;
    setState(() {
      _tags.add(tag);
      _tagCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(socialActionsProvider).createThread(
            ForumThreadInput(
              title: _titleCtrl.text,
              content: _contentCtrl.text,
              area: _area,
              tags: _tags,
            ),
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hilo publicado.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo publicar: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nuevo hilo',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleCtrl,
                  decoration:
                      const InputDecoration(hintText: 'Titulo de la duda'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa un titulo'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _area,
                  isExpanded: true,
                  items: repositoryAreaOptions.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value,
                              overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _area = value ?? _area),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contentCtrl,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                      hintText: 'Describe el problema o hallazgo'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa el contenido'
                      : null,
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    ..._tags.map(
                      (tag) => InputChip(
                        label: Text(tag),
                        onDeleted: () => setState(() => _tags.remove(tag)),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: _tagCtrl,
                  decoration: const InputDecoration(
                      hintText: 'Agregar etiqueta, maximo 3'),
                  onSubmitted: _addTag,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_outlined),
                    label: const Text('PUBLICAR HILO'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

class ForumUserAvatar extends StatelessWidget {
  const ForumUserAvatar({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.size,
    this.color = AppColors.primary,
  });

  final String name;
  final String imageUrl;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    final hasImage = imageUrl.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              imageUrl.trim(),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _AvatarInitials(
                initials: initials,
                color: color,
              ),
            )
          : _AvatarInitials(initials: initials, color: color),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  const _AvatarInitials({required this.initials, required this.color});

  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'CU';
  if (parts.length == 1) {
    return parts.first
        .substring(0, parts.first.length.clamp(1, 2))
        .toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

Color _areaColor(String area) {
  if (area.contains('Salud')) return const Color(0xFF6BD6FF);
  if (area.contains('Agro')) return const Color(0xFFFFC857);
  if (area.contains('Sociales')) return const Color(0xFFFF8C6B);
  if (area.contains('Naturales')) return const Color(0xFFB18CFF);
  if (area.contains('Econ')) return const Color(0xFFFFB86B);
  if (area.contains('Educ')) return const Color(0xFFFF7AB6);
  return AppColors.primary;
}

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Ahora';
  if (diff.inHours < 1) return 'Hace ${diff.inMinutes}m';
  if (diff.inDays < 1) return 'Hace ${diff.inHours}h';
  if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
