import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/repository_providers.dart';

class RepositoryFilterSheet extends ConsumerStatefulWidget {
  const RepositoryFilterSheet({super.key});

  @override
  ConsumerState<RepositoryFilterSheet> createState() =>
      RepositoryFilterSheetState();
}

class RepositoryFilterSheetState extends ConsumerState<RepositoryFilterSheet> {
  late final TextEditingController _authorController;
  late DateTime? _selectedDate;
  late String _club;
  late String _category;
  late String _area;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(repositoryFiltersProvider);
    _authorController = TextEditingController(text: filters.author);
    _selectedDate = filters.date;
    _club = filters.clubId;
    _category = filters.category;
    _area = filters.area;
  }

  @override
  void dispose() {
    _authorController.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _authorController.clear();
      _selectedDate = null;
      _club = '';
      _category = '';
      _area = '';
    });
  }

  void _apply() {
    final current = ref.read(repositoryFiltersProvider);
    ref.read(repositoryFiltersProvider.notifier).setFilters(
          current.copyWith(
            author: _authorController.text,
            date: _selectedDate,
            clearDate: _selectedDate == null,
            clubId: _club,
            category: _category,
            area: _area,
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(repositoryCatalogProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 10, 12),
                child: Row(
                  children: [
                    const Text(
                      'FILTROS AVANZADOS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    RepositoryFilterField(
                      label: 'NOMBRE DEL AUTOR',
                      hint: 'Ej: María García...',
                      controller: _authorController,
                    ),
                    const SizedBox(height: 16),
                    const RepositoryFilterLabel(
                      label: 'FECHA DE PUBLICACIÓN',
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _selectedDate == null
                            ? 'Seleccionar fecha'
                            : formatRepositoryDate(_selectedDate!),
                      ),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    const SizedBox(height: 16),
                    catalogAsync.when(
                      loading: () => const LinearProgressIndicator(
                        color: AppColors.primary,
                      ),
                      error: (error, stackTrace) => Text(
                        'No se pudo cargar catálogo: $error',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      data: (catalog) => Column(
                        children: [
                          RepositoryFilterDropdown(
                            label: 'CLUB',
                            value: _club,
                            options: catalog.clubs,
                            onChanged: (value) =>
                                setState(() => _club = value ?? ''),
                          ),
                          const SizedBox(height: 16),
                          RepositoryFilterDropdown(
                            label: 'CATEGORÍA',
                            value: _category,
                            options: catalog.categories,
                            onChanged: (value) =>
                                setState(() => _category = value ?? ''),
                          ),
                          const SizedBox(height: 16),
                          RepositoryFilterDropdown(
                            label: 'ÁREA DE CONOCIMIENTO',
                            value: _area,
                            options: catalog.areas,
                            onChanged: (value) =>
                                setState(() => _area = value ?? ''),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clear,
                        child: const Text('Limpiar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _apply,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('APLICAR FILTROS'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class RepositoryFilterLabel extends StatelessWidget {
  const RepositoryFilterLabel({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.muted,
      ),
    );
  }
}

class RepositoryFilterField extends StatelessWidget {
  const RepositoryFilterField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
  });

  final String label;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RepositoryFilterLabel(label: label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13),
          decoration: repositoryInputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class RepositoryFilterDropdown extends StatelessWidget {
  const RepositoryFilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final currentValue = options.containsKey(value) ? value : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RepositoryFilterLabel(label: label),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: currentValue,
          dropdownColor: AppColors.background,
          style: const TextStyle(color: AppColors.onSurface, fontSize: 13),
          decoration: repositoryInputDecoration(),
          items: options.entries
              .map(
                (entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

InputDecoration repositoryInputDecoration({
  String? hintText,
  String? counterText,
  String? helperText,
  String? errorText,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    borderSide: BorderSide.none,
  );

  return InputDecoration(
    hintText: hintText,
    counterText: counterText,
    helperText: helperText,
    errorText: errorText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.background,
    border: border,
    enabledBorder: border,
    focusedBorder: border,
  );
}

String formatRepositoryDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
