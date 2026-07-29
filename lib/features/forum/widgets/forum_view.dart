import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/app_cache_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cuc_app_bar.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/forum_providers.dart';
import 'forum_empty_state.dart';
import 'forum_filters_bar.dart';
import 'forum_thread_card.dart';
import 'thread_composer_sheet.dart';

class ForumView extends ConsumerWidget {
  const ForumView({super.key});

  void _openThreadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ThreadComposerSheet(),
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
            const SliverToBoxAdapter(child: ForumFiltersBar()),
            threadsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (error, _) => SliverFillRemaining(
                child: ForumEmptyState(
                  title: 'No se pudo cargar el foro',
                  subtitle: '$error',
                ),
              ),
              data: (threads) {
                if (threads.isEmpty) {
                  return const SliverFillRemaining(
                    child: ForumEmptyState(
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
                        ForumThreadCard(thread: threads[index]),
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
