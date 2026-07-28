import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/repository_providers.dart';
import 'repository_detail_sheet.dart';

class RepositoryDocumentCard extends ConsumerStatefulWidget {
  const RepositoryDocumentCard({
    super.key,
    required this.document,
  });

  final RepositoryDocument document;

  @override
  ConsumerState<RepositoryDocumentCard> createState() =>
      RepositoryDocumentCardState();
}

class RepositoryDocumentCardState extends ConsumerState<RepositoryDocumentCard> {
  bool _downloading = false;
  bool _deleting = false;

  void _openDetail() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RepositoryDetailSheet(document: widget.document),
    );
  }

  Future<void> _downloadOrOpen() async {
    final document = widget.document;
    if (document.fileUrl.isEmpty || _downloading) return;

    setState(() => _downloading = true);
    try {
      final file = await _localFileForUrl(document.fileUrl);
      if (!await file.exists()) {
        final request = await HttpClient().getUrl(Uri.parse(document.fileUrl));
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
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el documento: $error')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<File> _localFileForUrl(String url) async {
    final directory = await getApplicationDocumentsDirectory();
    final repositoryDirectory = Directory('${directory.path}/repositorio');
    if (!await repositoryDirectory.exists()) {
      await repositoryDirectory.create(recursive: true);
    }

    final uri = Uri.parse(url);
    final rawName = uri.pathSegments.isEmpty
        ? widget.document.id
        : Uri.decodeComponent(uri.pathSegments.last);
    final safeName = rawName.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    return File('${repositoryDirectory.path}/${widget.document.id}_$safeName');
  }

  Future<void> _confirmDelete() async {
    if (_deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Borrar documento', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('¿Quieres borrar "${widget.document.title}" del repositorio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await ref.read(repositoryActionsProvider).deleteDocument(widget.document);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento borrado.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final canDeleteAsync = ref.watch(canDeleteRepositoryDocumentProvider(document));

    return InkWell(
      onTap: _openDetail,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)), // Borde más sutil
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Alineación superior para lectura natural
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.article_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          document.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (document.status.toLowerCase() != 'aprobado') ...[
                        const SizedBox(width: 8),
                        _MiniStatusBadge(status: document.status),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (document.description.isNotEmpty) ...[
                    Text(
                      document.description,
                      style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Metadatos compactos
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _MetaChip(icon: Icons.person_outline, label: document.authorName),
                      const Text('•', style: TextStyle(color: AppColors.border, fontSize: 10)),
                      _MetaChip(
                        icon: Icons.category_outlined,
                        label: repositoryCategoryOptions[document.category] ?? document.category,
                      ),
                    ],
                  ),
                  if (document.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: document.tags.map((tag) => _TagChip(label: tag)).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                IconButton(
                  tooltip: 'Descargar',
                  onPressed: document.fileUrl.isEmpty || _downloading ? null : _downloadOrOpen,
                  icon: _downloading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.download_rounded, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.border.withValues(alpha: 0.2),
                    minimumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                  ),
                ),
                canDeleteAsync.maybeWhen(
                  data: (canDelete) => canDelete
                      ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: IconButton(
                      tooltip: 'Borrar',
                      onPressed: _deleting ? null : _confirmDelete,
                      icon: _deleting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.delete_outline, size: 18),
                      color: AppColors.error,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.error.withValues(alpha: 0.1),
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  )
                      : const SizedBox.shrink(),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _MiniStatusBadge extends StatelessWidget {
  const _MiniStatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isRejected = status.toLowerCase() == 'rechazado';
    final color = isRejected ? AppColors.error : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isRejected ? 'Rechazado' : 'Pendiente',
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background, // Contraste contra el surface
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Text(
        label.startsWith('#') ? label : '#$label',
        style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w600),
      ),
    );
  }
}