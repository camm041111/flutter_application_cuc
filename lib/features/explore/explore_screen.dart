import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/app_cache_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cuc_app_bar.dart';

import 'widgets/explore_search_bar.dart';
import 'widgets/news_card.dart';
import 'widgets/news_composer_sheet.dart';
import 'widgets/explore_empty_state.dart';

import 'providers/explore_providers.dart'; // Importación crucial

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  void _openNewsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NewsComposerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);
    final canPublishAsync = ref.watch(canPublishNewsProvider);

    return Scaffold(
      appBar: const CucAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(appCacheServiceProvider).invalidatePrefix('explore:news');
          ref.invalidate(newsProvider);
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: ExploreSearchBar()),

            // Consumo real de los datos
            newsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (error, _) => SliverFillRemaining(
                child: ExploreEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error al cargar noticias',
                  subtitle: error.toString(), // Este texto nos dirá si Supabase rechazó la conexión
                ),
              ),
              data: (posts) {
                if (posts.isEmpty) {
                  return const SliverFillRemaining(
                    child: ExploreEmptyState(
                      icon: Icons.campaign_outlined,
                      title: 'Sin noticias publicadas',
                      subtitle: 'Cuando los líderes publiquen anuncios aparecerán aquí.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList.separated(
                    itemCount: posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      // Disparador de paginación automática al llegar al fondo
                      if (index == posts.length - 1) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref.read(newsProvider.notifier).loadMore();
                        });
                      }
                      return NewsCard(post: posts[index]);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: canPublishAsync.maybeWhen(
        data: (canPublish) => canPublish
            ? FloatingActionButton(
          onPressed: () => _openNewsSheet(context),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          child: const Icon(Icons.campaign_outlined),
        )
            : null,
        orElse: () => null,
      ),
    );
  }
}