import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/cuc_app_bar.dart';
import 'providers/repository_providers.dart';

class RepositoryScreen extends ConsumerStatefulWidget {
  const RepositoryScreen({super.key});

  @override
  ConsumerState<RepositoryScreen> createState() => _RepositoryScreenState();
}

class _RepositoryScreenState extends ConsumerState<RepositoryScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applySearch(String value) {
    final current = ref.read(repositoryFiltersProvider);
    ref.read(repositoryFiltersProvider.notifier).setFilters(
          RepositoryFilters(
            search: value,
            author: current.author,
            date: current.date,
            clubId: current.clubId,
            category: current.category,
          ),
        );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FilterSheet(),
    );
  }

  void _openUploadSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _UploadDocumentSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(repositoryFiltersProvider);
    final docsAsync = ref.watch(repositoryDocumentsProvider);

    return Scaffold(
      appBar: const CucAppBar(),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async => ref.invalidate(repositoryDocumentsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: _applySearch,
                  decoration: const InputDecoration(
                    hintText: 'Buscar investigaciones...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 10),
                _FilterLauncher(
                  activeFilters: filters.activeCount,
                  onTap: _openFilterSheet,
                ),
                const SizedBox(height: 16),
                docsAsync.when(
                  loading: () => const SizedBox(
                    height: 220,
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)),
                  ),
                  error: (e, s) => _EmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'No se pudo cargar el repositorio',
                    subtitle: '$e',
                  ),
                  data: (items) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ResultsHeader(count: items.length),
                      const SizedBox(height: 12),
                      if (items.isEmpty)
                        const _EmptyState(
                          icon: Icons.folder_off_outlined,
                          title: 'Sin documentos',
                          subtitle:
                              'Ajusta los filtros o sube una nueva publicación.',
                        )
                      else
                        ...items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RepoCard(item: item),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _openUploadSheet,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              child: const Icon(Icons.upload_file),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterLauncher extends StatelessWidget {
  const _FilterLauncher({required this.activeFilters, required this.onTap});

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
                  fontWeight: FontWeight.w500),
            ),
            if (activeFilters > 0) ...[
              const SizedBox(width: 6),
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    '$activeFilters',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.background),
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

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.count});

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
              letterSpacing: 1.5),
        ),
        Text('$count resultados',
            style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ],
    );
  }
}

class _RepoCard extends ConsumerStatefulWidget {
  const _RepoCard({required this.item});

  final RepositoryDocument item;

  @override
  ConsumerState<_RepoCard> createState() => _RepoCardState();
}

class _RepoCardState extends ConsumerState<_RepoCard> {
  bool _downloading = false;
  bool _deleting = false;

  Future<void> _downloadOrOpen() async {
    final item = widget.item;
    if (item.fileUrl.isEmpty || _downloading) return;

    setState(() => _downloading = true);
    try {
      final file = await _localFileForUrl(item.fileUrl);
      if (!await file.exists()) {
        final request = await HttpClient().getUrl(Uri.parse(item.fileUrl));
        final response = await request.close();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception('No se pudo descargar el archivo.');
        }
        await response.pipe(file.openWrite());
      }

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el documento: $e')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<File> _localFileForUrl(String url) async {
    final directory = await getApplicationDocumentsDirectory();
    final repoDirectory = Directory('${directory.path}/repositorio');
    if (!await repoDirectory.exists()) {
      await repoDirectory.create(recursive: true);
    }

    final uri = Uri.parse(url);
    final rawName = uri.pathSegments.isEmpty
        ? widget.item.id
        : Uri.decodeComponent(uri.pathSegments.last);
    final safeName = rawName.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    return File('${repoDirectory.path}/${widget.item.id}_$safeName');
  }

  Future<void> _confirmDelete() async {
    if (_deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar documento'),
        content: Text('¿Quieres borrar "${widget.item.title}" del repositorio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await ref.read(repositoryActionsProvider).deleteDocument(widget.item);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento borrado.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo borrar el documento: $e')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final canDeleteAsync = ref.watch(canDeleteRepositoryDocumentProvider(item));

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
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.description_outlined,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.category} · ${item.authorName}',
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatDate(item.createdAt)} · ${item.clubName}',
                    style:
                        const TextStyle(fontSize: 10, color: AppColors.muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Descargar o abrir',
              onPressed:
                  item.fileUrl.isEmpty || _downloading ? null : _downloadOrOpen,
              icon: _downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.border.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            canDeleteAsync.maybeWhen(
              data: (canDelete) => canDelete
                  ? IconButton(
                      tooltip: 'Borrar documento',
                      onPressed: _deleting ? null : _confirmDelete,
                      icon: _deleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_outline, size: 20),
                      color: AppColors.error,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            AppColors.error.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late final TextEditingController _authorCtrl;
  late DateTime? _selectedDate;
  late String _club;
  late String _category;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(repositoryFiltersProvider);
    _authorCtrl = TextEditingController(text: filters.author);
    _selectedDate = filters.date;
    _club = filters.clubId;
    _category = filters.category;
  }

  @override
  void dispose() {
    _authorCtrl.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _authorCtrl.clear();
      _selectedDate = null;
      _club = '';
      _category = '';
    });
  }

  void _apply() {
    final current = ref.read(repositoryFiltersProvider);
    ref.read(repositoryFiltersProvider.notifier).setFilters(
          RepositoryFilters(
            search: current.search,
            author: _authorCtrl.text,
            date: _selectedDate,
            clubId: _club,
            category: _category,
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
      builder: (_, ctrl) {
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
                    borderRadius: BorderRadius.circular(99)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 10, 12),
                child: Row(
                  children: [
                    const Text('Filtros avanzados',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
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
                  controller: ctrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _FilterField(
                      label: 'NOMBRE DEL AUTOR',
                      hint: 'Ej: María García...',
                      controller: _authorCtrl,
                    ),
                    const SizedBox(height: 16),
                    const _FilterLabel(label: 'FECHA DE PUBLICACIÓN'),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _selectedDate = date);
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_selectedDate == null
                          ? 'Seleccionar fecha'
                          : _formatDate(_selectedDate!)),
                      style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft),
                    ),
                    const SizedBox(height: 16),
                    catalogAsync.when(
                      loading: () => const LinearProgressIndicator(
                          color: AppColors.primary),
                      error: (e, s) => Text('No se pudo cargar catálogo: $e',
                          style: const TextStyle(color: AppColors.muted)),
                      data: (catalog) => Column(
                        children: [
                          _FilterDropdown(
                            label: 'CLUB',
                            value: _club,
                            options: catalog.clubs,
                            onChanged: (v) => setState(() => _club = v ?? ''),
                          ),
                          const SizedBox(height: 16),
                          _FilterDropdown(
                            label: 'CATEGORÍA',
                            value: _category,
                            options: catalog.categories,
                            onChanged: (v) =>
                                setState(() => _category = v ?? ''),
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
                            onPressed: _clear, child: const Text('Limpiar'))),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _apply,
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

class _UploadDocumentSheet extends ConsumerStatefulWidget {
  const _UploadDocumentSheet();

  @override
  ConsumerState<_UploadDocumentSheet> createState() =>
      _UploadDocumentSheetState();
}

class _UploadDocumentSheetState extends ConsumerState<_UploadDocumentSheet> {
  final _titleCtrl = TextEditingController();
  String _category = repositoryCategoryOptions.keys.first;
  String _area = repositoryAreaOptions.keys.first;
  PlatformFile? _file;
  bool _uploading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    final file = result?.files.single;
    if (file == null) return;

    if (file.size > repositoryFileLimitBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El archivo no puede superar 10MB.')),
      );
      return;
    }

    setState(() => _file = file);
  }

  Future<void> _submit() async {
    final file = _file;
    if (_titleCtrl.text.trim().isEmpty || file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega título y archivo.')),
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      final status = await ref.read(repositoryActionsProvider).uploadDocument(
            RepositoryUploadInput(
              title: _titleCtrl.text,
              category: _category,
              area: _area,
              file: file,
            ),
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'aprobado'
                ? 'Documento publicado.'
                : 'Documento enviado a revisión.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Subir documento',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(hintText: 'Título'),
              ),
              const SizedBox(height: 12),
              _FilterDropdown(
                label: 'CATEGORÍA',
                value: _category,
                options: repositoryCategoryOptions,
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 12),
              _FilterDropdown(
                label: 'ÁREA DE CONOCIMIENTO',
                value: _area,
                options: repositoryAreaOptions,
                onChanged: (value) {
                  if (value != null) setState(() => _area = value);
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _uploading ? null : _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(_file == null
                    ? 'Seleccionar archivo (máx. 10MB)'
                    : _file!.name),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _uploading ? null : _submit,
                  icon: _uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Text('ENVIAR A REVISIÓN'),
                ),
              ),
            ],
          ),
        ),
      ),
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
      style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.primary),
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField(
      {required this.label, required this.hint, required this.controller});

  final String label;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterLabel(label: label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
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
        _FilterLabel(label: label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: currentValue,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
