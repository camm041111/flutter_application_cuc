import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/repository_providers.dart';
import 'repository_detail_sheet.dart';
import 'repository_filter_sheet.dart';

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

class RepositoryDocumentCardState
    extends ConsumerState<RepositoryDocumentCard> {
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
    if (document.fileUrl.isEmpty || _downloading) {
      return;
    }

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
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el documento: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
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
    return File(
      '${repositoryDirectory.path}/${widget.document.id}_$safeName',
    );
  }

  Future<void> _confirmDelete() async {
    if (_deleting) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar documento'),
        content: Text(
          '¿Quieres borrar "${widget.document.title}" del repositorio?',
        ),
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

    if (confirmed != true) {
      return;
    }

    setState(() => _deleting = true);
    try {
      await ref.read(repositoryActionsProvider).deleteDocument(widget.document);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento borrado.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo borrar el documento: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final canDeleteAsync = ref.watch(
      canDeleteRepositoryDocumentProvider(document),
    );

    return InkWell(
      onTap: _openDetail,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          document.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (document.status.toLowerCase() != 'aprobado') ...[
                        const SizedBox(width: 8),
                        RepositoryDocumentStatusBadge(
                          status: document.status,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (document.description.isNotEmpty) ...[
                    Text(
                      document.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    '${repositoryCategoryOptions[document.category] ?? document.category} · ${document.authorName}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatRepositoryDate(document.createdAt)} · ${document.clubName}'
                    '${document.area.isEmpty ? '' : ' · ${repositoryAreaOptions[document.area] ?? document.area}'}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (document.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: document.tags
                          .map(
                            (tag) => RepositoryDocumentTag(label: tag),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Descargar o abrir',
              onPressed: document.fileUrl.isEmpty || _downloading
                  ? null
                  : _downloadOrOpen,
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
                  borderRadius: BorderRadius.circular(8),
                ),
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
                        backgroundColor: AppColors.error.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
