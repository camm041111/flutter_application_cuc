import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import '../../../core/cache/app_cache_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/social_tag_utils.dart';
import '../../../core/widgets/cuc_app_bar.dart';
import '../../profile/providers/profile_providers.dart';
import '../../repository/providers/repository_providers.dart';
import '../providers/forum_providers.dart';

import '../../../core/widgets/correct_snackbar.dart';
import '../../../core/widgets/rich_text_editor_toolbar.dart';
import '../../explore/widgets/news_tag.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
part 'forum_filters_bar.dart';
part 'forum_replies.dart';
part 'forum_thread_card.dart';
part 'forum_user_avatar.dart';
part 'thread_detail_sheet.dart';
part 'thread_composer_sheet.dart';
part 'forum_empty_state.dart';

class ForumView extends ConsumerWidget {
  const ForumView({super.key});

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
    final profileAsync = ref.watch(currentUserProfileProvider);

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
        data: (profile) => profile?.estado == 'activo'
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
