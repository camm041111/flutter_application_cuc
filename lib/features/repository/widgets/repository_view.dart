import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/app_cache_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cuc_app_bar.dart';
import '../providers/repository_providers.dart';
import 'repository_document_card.dart';
import 'repository_filter_sheet.dart';
import 'repository_search_bar.dart';
import 'repository_upload_sheet.dart';

class RepositoryView extends ConsumerWidget {
  const RepositoryView({super.key});

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RepositoryFilterSheet(),
    );
  }

  void _openUploadSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RepositoryUploadSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(repositoryFiltersProvider);
    final documentsAsync = ref.watch(repositoryDocumentsProvider);

    return Scaffold(
      appBar: const CucAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(appCacheServiceProvider)
              .invalidatePrefix('repository:');
          return ref
              .refresh(repositoryDocumentsProvider.future)
              .then((documents) {});
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            const RepositorySearchBar(),
            const SizedBox(height: 10),
            RepositoryFilterLauncher(
              activeFilters: filters.activeCount,
              onTap: () => _openFilterSheet(context),
            ),
            const SizedBox(height: 10),
            RepositorySortBar(
              value: filters.sort,
              onChanged: (sort) {
                ref.read(repositoryFiltersProvider.notifier).setFilters(
                      filters.copyWith(sort: sort),
                    );
              },
            ),
            const SizedBox(height: 16),
            documentsAsync.when(
              loading: () => const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (error, stackTrace) => RepositoryEmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'No se pudo cargar el repositorio',
                subtitle: '$error',
              ),
              data: (documents) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RepositoryResultsHeader(count: documents.length),
                  const SizedBox(height: 12),
                  if (documents.isEmpty)
                    const RepositoryEmptyState(
                      icon: Icons.folder_off_outlined,
                      title: 'Sin documentos',
                      subtitle:
                          'Ajusta los filtros o sube una nueva publicación.',
                    )
                  else
                    ...documents.map(
                      (document) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: RepositoryDocumentCard(document: document),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openUploadSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.upload_file),
      ),
    );
  }
}

class RepositoryFilterLauncher extends StatelessWidget {
  const RepositoryFilterLauncher({
    super.key,
    required this.activeFilters,
    required this.onTap,
  });

  final int activeFilters;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.tune, size: 18, color: AppColors.muted),
            const SizedBox(width: 6),
            const Text(
              'Filtros avanzados',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (activeFilters > 0) ...[
              const SizedBox(width: 6),
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$activeFilters',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RepositorySortBar extends StatelessWidget {
  const RepositorySortBar({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final RepositorySort value;
  final ValueChanged<RepositorySort> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: RepositorySort.values.map((sort) {
          final selected = value == sort;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(sort.label),
              selected: selected,
              onSelected: (selected) => onChanged(sort),
              selectedColor: AppColors.primary.withValues(alpha: 0.18),
              labelStyle: TextStyle(
                color: selected ? AppColors.primary : AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class RepositoryResultsHeader extends StatelessWidget {
  const RepositoryResultsHeader({
    super.key,
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'RECIENTES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          '$count resultados',
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }
}

class RepositoryEmptyState extends StatelessWidget {
  const RepositoryEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.muted, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
