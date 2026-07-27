part of 'forum_view.dart';

class _ForumFiltersBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(forumFiltersProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar hilos, etiquetas o contenido...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) =>
                ref.read(forumFiltersProvider.notifier).setSearch(value),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: filters.area,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Todas las areas',
                          overflow: TextOverflow.ellipsis),
                    ),
                    ...repositoryAreaOptions.entries.map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child:
                            Text(entry.value, overflow: TextOverflow.ellipsis),
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
                child: DropdownButtonFormField<ForumSort>(
                  initialValue: filters.sort,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: ForumSort.values
                      .map(
                        (sort) => DropdownMenuItem(
                          value: sort,
                          child:
                              Text(sort.label, overflow: TextOverflow.ellipsis),
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
