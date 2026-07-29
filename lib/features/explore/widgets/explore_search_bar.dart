import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/dashboard_search_field.dart';
import '../providers/explore_providers.dart';

class ExploreSearchBar extends ConsumerStatefulWidget {
  const ExploreSearchBar({super.key});

  @override
  ConsumerState<ExploreSearchBar> createState() => ExploreSearchBarState();
}

class ExploreSearchBarState extends ConsumerState<ExploreSearchBar> {
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
      child: DashboardSearchField(
        hintText: 'Buscar noticias, personas o matrículas...',
        onChanged: _onSearchChanged,
      ),
    );
  }
}
