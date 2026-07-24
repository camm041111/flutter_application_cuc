import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/explore_providers.dart';

class ExploreSearchBar extends ConsumerStatefulWidget {
  const ExploreSearchBar({super.key});

  @override
  ConsumerState<ExploreSearchBar> createState() => _ExploreSearchBarState();
}

class _ExploreSearchBarState extends ConsumerState<ExploreSearchBar> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(newsSearchProvider.notifier).setSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        style: const TextStyle(fontSize: 14),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar noticias, personas o matrículas...',
          hintStyle: const TextStyle(color: AppColors.muted),
          prefixIcon: const Icon(Icons.search, color: AppColors.muted),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }
}
