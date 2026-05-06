import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cuc_app_bar.dart';

class RepositoryScreen extends StatefulWidget {
  const RepositoryScreen({super.key});

  @override
  State<RepositoryScreen> createState() => _RepositoryScreenState();
}

class _RepositoryScreenState extends State<RepositoryScreen> {
  int _activeFilters = 0;

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        onApply: (count) {
          setState(() => _activeFilters = count);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CucAppBar(),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar investigaciones...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _openFilterSheet,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.tune, size: 18, color: AppColors.muted),
                      const SizedBox(width: 6),
                      const Text('Filtros avanzados', style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w500)),
                      if (_activeFilters > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: Center(
                            child: Text('$_activeFilters', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.background)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('RECIENTES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1.5)),
                  Text('12 resultados', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 12),
              ..._repoItems.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RepoCard(item: r),
              )),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: _RepoFab(),
          ),
        ],
      ),
    );
  }
}

// ── Datos ────────────────────────────────────────────────────────────────────

typedef _RepoItem = ({IconData icon, String title, String date});

final _repoItems = <_RepoItem>[
  (icon: Icons.description_outlined, title: 'Análisis Sostenibilidad Urbana 2024', date: 'Actualizado: 12 Mar, 2024'),
  (icon: Icons.analytics_outlined, title: 'Dataset Redes Neuronales CUC', date: 'Actualizado: 08 Mar, 2024'),
  (icon: Icons.science_outlined, title: 'Protocolo Biotecnológico V3', date: 'Actualizado: 01 Mar, 2024'),
  (icon: Icons.history_edu_outlined, title: 'Memoria Institucional Postgrado', date: 'Actualizado: 25 Feb, 2024'),
  (icon: Icons.storage_outlined, title: 'Censo Estudiantil Ingeniería', date: 'Actualizado: 14 Feb, 2024'),
];

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _RepoCard extends StatelessWidget {
  const _RepoCard({required this.item});
  final _RepoItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(item.date, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.download_outlined, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.border.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepoFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 20)],
        ),
        child: const Icon(Icons.add, color: AppColors.background, size: 28),
      ),
    );
  }
}

// ── Filter Bottom Sheet ───────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.onApply});
  final ValueChanged<int> onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  DateTime? _selectedDate;
  String _club = '';
  String _area = '';

  int get _activeCount {
    int c = 0;
    if (_titleCtrl.text.isNotEmpty) c++;
    if (_authorCtrl.text.isNotEmpty) c++;
    if (_selectedDate != null) c++;
    if (_club.isNotEmpty) c++;
    if (_area.isNotEmpty) c++;
    return c;
  }

  void _clear() {
    setState(() {
      _titleCtrl.clear();
      _authorCtrl.clear();
      _selectedDate = null;
      _club = '';
      _area = '';
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, ctrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99)),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 10, 12),
                child: Row(
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Filtros avanzados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        Text('Refina tu búsqueda', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                      ],
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
              // Body
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _FilterField(label: 'TÍTULO', hint: 'Ej: Análisis urbano...', controller: _titleCtrl, onChanged: (_) => setState(() {})),
                    const SizedBox(height: 16),
                    _FilterField(label: 'NOMBRE DEL AUTOR', hint: 'Ej: María García...', controller: _authorCtrl, onChanged: (_) => setState(() {})),
                    const SizedBox(height: 16),
                    const _FilterLabel(label: 'FECHA DE PUBLICACIÓN'),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.primary),
                            ),
                            child: child!,
                          ),
                        );
                        if (date != null) setState(() => _selectedDate = date);
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _selectedDate == null ? 'Seleccionar fecha' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      ),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FilterDropdown(
                      label: 'CLUB',
                      value: _club,
                      options: const {'': 'Todos los clubes', 'biotecnologia': 'Club de Biotecnología', 'robotica': 'Club de Robótica', 'astrofisica': 'Club de Astrofísica', 'ia': 'Club de IA'},
                      onChanged: (v) => setState(() => _club = v ?? ''),
                    ),
                    const SizedBox(height: 16),
                    _FilterDropdown(
                      label: 'ÁREA DE CONOCIMIENTO',
                      value: _area,
                      options: const {'': 'Todas las áreas', 'ciencias-naturales': 'Ciencias Naturales', 'ingenieria': 'Ingeniería y Tecnología', 'ciencias-medicas': 'Ciencias Médicas'},
                      onChanged: (v) => setState(() => _area = v ?? ''),
                    ),
                  ],
                ),
              ),
              // Footer
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
                        onPressed: () => widget.onApply(_activeCount),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('APLICAR FILTROS'),
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

class _FilterLabel extends StatelessWidget {
  const _FilterLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.primary),
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({required this.label, required this.hint, required this.controller, this.onChanged});
  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterLabel(label: label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({required this.label, required this.value, required this.options, required this.onChanged});
  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterLabel(label: label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: AppColors.onSurface, fontSize: 13),
          decoration: const InputDecoration(),
          items: options.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
