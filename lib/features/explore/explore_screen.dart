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
          // 1. Limpiamos la caché de Supabase
          await ref.read(appCacheServiceProvider).invalidatePrefix('explore:news');

          // 2. ARQUITECTURA SEGURA:
          // Retornamos ref.refresh().future. Esto le dice al RefreshIndicator
          // que siga girando hasta que lleguen los datos, sin destruir la lista actual.
          return await ref.refresh(newsProvider.future);
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
                      final noticia = posts[index];
                      return NewsCard(
                        // 🛡️ EL BLINDAJE: Esto evita que Flutter confunda los estados al refrescar
                        key: ValueKey(noticia.id),
                        post: noticia,);
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