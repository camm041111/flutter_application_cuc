import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dashboard_search_field.dart';
import '../../repository/providers/repository_providers.dart';
import '../providers/forum_providers.dart';

class ForumFiltersBar extends ConsumerStatefulWidget {
  const ForumFiltersBar({super.key});

  @override
  ConsumerState<ForumFiltersBar> createState() => ForumFiltersBarState();
}

class ForumFiltersBarState extends ConsumerState<ForumFiltersBar> {
  Timer? _debounce;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(forumFiltersProvider).search,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(forumFiltersProvider.notifier).setSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(forumFiltersProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DashboardSearchField(
            controller: _searchController,
            hintText: 'Buscar hilos, etiquetas o contenido...',
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ForumDropdownFilter<String>(
                  icon: Icons.science_outlined,
                  value: filters.area,
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text(
                        'Todas las áreas',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...repositoryAreaOptions.entries.map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(
                          entry.value,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                child: ForumDropdownFilter<ForumSort>(
                  icon: Icons.update,
                  value: filters.sort,
                  items: ForumSort.values
                      .map(
                        (sort) => DropdownMenuItem(
                          value: sort,
                          child: Text(
                            sort.label,
                            overflow: TextOverflow.ellipsis,
                          ),
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

class ForumDropdownFilter<T> extends StatelessWidget {
  const ForumDropdownFilter({
    super.key,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final IconData icon;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.muted,
                ),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
