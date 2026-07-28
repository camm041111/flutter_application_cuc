import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/repository_providers.dart';

class RepositorySearchBar extends ConsumerStatefulWidget {
  const RepositorySearchBar({super.key});

  @override
  ConsumerState<RepositorySearchBar> createState() =>
      RepositorySearchBarState();
}

class RepositorySearchBarState extends ConsumerState<RepositorySearchBar> {
  Timer? _debounce;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(repositoryFiltersProvider).search,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final current = ref.read(repositoryFiltersProvider);
      ref.read(repositoryFiltersProvider.notifier).setFilters(
            current.copyWith(search: value),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onSearchChanged,
      decoration: const InputDecoration(
        hintText: 'Buscar investigaciones...',
        prefixIcon: Icon(Icons.search),
      ),
    );
  }
}
