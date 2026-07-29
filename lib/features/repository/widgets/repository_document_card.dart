import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../explore/widgets/news_tag.dart';
import '../providers/repository_providers.dart';
import 'repository_detail_sheet.dart';
import 'repository_file_download_tile.dart';

class RepositoryDocumentCard extends StatefulWidget {
  const RepositoryDocumentCard({
    super.key,
    required this.document,
  });

  final RepositoryDocument document;

  @override
  State<RepositoryDocumentCard> createState() => RepositoryDocumentCardState();
}

class RepositoryDocumentCardState extends State<RepositoryDocumentCard> {
  bool _downloading = false;

  void _openDetail() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RepositoryDetailSheet(document: widget.document),
    );
  }

  Future<void> _downloadOrOpen() async {
    final urls = widget.document.fileUrls;
    if (urls.isEmpty || _downloading) return;

    setState(() => _downloading = true);
    try {
      if (urls.length == 1) {
        // 🛡️ Flujo 1: Un solo archivo. Abrimos directo con visor nativo
        final file = await downloadRepositoryFile(urls.single);
        final result = await OpenFilex.open(file.path);

        if (result.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message)),
          );
        }
      } else {
        // 🛡️ Flujo 2: Múltiples archivos. Delegamos al Share Sheet
        final downloadedFiles = await Future.wait(urls.map(downloadRepositoryFile));
        final xFiles = downloadedFiles.map((file) => XFile(file.path)).toList();

        final result = await Share.shareXFiles(
          xFiles,
          subject: widget.document.title,
          text: 'Anexos del documento: ${widget.document.title}',
        );

        if (result.status == ShareResultStatus.success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Archivos procesados correctamente.')),
          );
        }
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

  @override
  Widget build(BuildContext context) {
    final document = widget.document;

    return InkWell(
      onTap: _openDetail,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.border.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Icon(
                repositoryCategoryIcon(document.category),
                color: AppColors.primary,
                size: 20,
              ),
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
                      document.description.replaceAll(
                        RegExp(r'(\*\*|_|\[|\]|\(.*?\))'),
                        '',
                      ),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _MetaChip(
                          icon: Icons.person_outline,
                          label: document.authorName),
                      const Text('•',
                          style:
                          TextStyle(color: AppColors.border, fontSize: 10)),
                      _MetaChip(
                        icon: Icons.category_outlined,
                        label: repositoryCategoryOptions[document.category] ??
                            document.category,
                      ),
                    ],
                  ),
                  if (document.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: document.tags
                          .map((tag) => NewsTag(label: tag))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Descargar',
              onPressed: document.fileUrls.isEmpty || _downloading
                  ? null
                  : _downloadOrOpen,
              icon: _downloading
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.download_rounded, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.border.withValues(alpha: 0.2),
                foregroundColor: AppColors.primary,
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
              ),
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
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.muted,
                fontWeight: FontWeight.w500)),
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
        style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5),
      ),
    );
  }
}

IconData repositoryCategoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'investigacion':
      return Icons.science_outlined;
    case 'manuales':
      return Icons.menu_book_outlined;
    case 'actas':
      return Icons.assignment_outlined;
    case 'divulgacion':
      return Icons.campaign_outlined;
    default:
      return Icons.description_outlined;
  }
}