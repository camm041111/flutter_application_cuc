part of 'forum_view.dart';


class _ForumFiltersBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ForumFiltersBar> createState() => _ForumFiltersBarState();
}

class _ForumFiltersBarState extends ConsumerState<_ForumFiltersBar> {
  Timer? _debounce;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // 🛡️ Inicializamos con el valor existente por si el widget se reconstruye
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
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // 🛡️ BARRERA ARQUITECTÓNICA: Retenemos la petición 500ms
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
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Buscar hilos, etiquetas o contenido...',
              prefixIcon: Icon(Icons.search),
              // Sostenemos la estética minimalista, asegurando que los inputs no sean ruidosos visualmente
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: filters.area,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Todas las áreas', overflow: TextOverflow.ellipsis),
                    ),
                    ...repositoryAreaOptions.entries.map(
                          (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) => ref.read(forumFiltersProvider.notifier).setArea(value ?? ''),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<ForumSort>(
                  initialValue: filters.sort,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ForumSort.values.map(
                        (sort) => DropdownMenuItem(
                      value: sort,
                      child: Text(sort.label, overflow: TextOverflow.ellipsis),
                    ),
                  ).toList(),
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