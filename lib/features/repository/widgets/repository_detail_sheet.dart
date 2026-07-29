import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../explore/widgets/news_tag.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/repository_providers.dart';
import 'repository_file_download_tile.dart';

class RepositoryDetailSheet extends ConsumerStatefulWidget {
  const RepositoryDetailSheet({super.key, required this.document});
  final RepositoryDocument document;

  @override
  ConsumerState<RepositoryDetailSheet> createState() =>
      RepositoryDetailSheetState();
}

class RepositoryDetailSheetState extends ConsumerState<RepositoryDetailSheet> {
  bool _reviewing = false;
  bool _downloadingAll = false;

  Future<void> _downloadAll() async {
    final urls = widget.document.fileUrls;
    if (_downloadingAll || urls.isEmpty) return;

    setState(() => _downloadingAll = true);
    try {
      // 1. Descargamos los binarios concurrentemente a la caché segura
      final downloadedFiles = await Future.wait(urls.map(downloadRepositoryFile));

      // 2. Mapeamos a XFile, el estándar transversal exigido por share_plus
      final xFiles = downloadedFiles.map((file) => XFile(file.path)).toList();

      // 3. Delegamos el manejo de los binarios al Share Sheet nativo
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
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron descargar todos los archivos: $error'),
        ),
      );
    } finally {
      if (mounted) setState(() => _downloadingAll = false);
    }
  }

  Future<void> _review(bool isApproved) async {
    if (_reviewing) return;
    setState(() => _reviewing = true);
    try {
      await ref
          .read(repositoryActionsProvider)
          .reviewDocument(widget.document.id, isApproved);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $error')));
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final doc = widget.document;
    final canReview = profileAsync.maybeWhen(
      data: (profile) =>
      doc.status.toLowerCase() == 'pendiente' &&
          profile != null &&
          (profile.rol == 'coordinador' || profile.rol == 'lider') &&
          profile.clubId == doc.clubId,
      orElse: () => false,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 16),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(99)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              doc.title.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  height: 1.2,
                                  letterSpacing: 0.4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                    if (doc.tags.isNotEmpty ||
                        doc.status.toLowerCase() != 'aprobado')
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...doc.tags.map((tag) => NewsTag(label: tag)),
                            if (doc.status.toLowerCase() != 'aprobado')
                              _DetailStatusBadge(status: doc.status),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        children: [
                          _DataRow(label: 'AUTOR', value: doc.authorName),
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child:
                              Divider(height: 1, color: AppColors.border)),
                          _DataRow(label: 'CLUB ASOCIADO', value: doc.clubName),
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child:
                              Divider(height: 1, color: AppColors.border)),
                          _DataRow(
                            label: 'FECHA',
                            value: formatRepositoryDetailDate(doc.createdAt),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, color: AppColors.border),
                          ),
                          _DataRow(
                            label: 'CATEGORÍA',
                            value: repositoryCategoryOptions[doc.category] ??
                                doc.category,
                          ),
                          if (doc.area.isNotEmpty) ...[
                            const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(
                                    height: 1, color: AppColors.border)),
                            _DataRow(
                                label: 'ÁREA DE CONOCIMIENTO',
                                value: repositoryAreaOptions[doc.area] ??
                                    doc.area),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'RESUMEN / ABSTRACT',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: MarkdownBody(
                        data: doc.description.isEmpty
                            ? 'Este documento no incluye una descripción general.'
                            : doc.description,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            fontSize: 14.5,
                            height: 1.6,
                            color: AppColors.onSurface,
                          ),
                          strong: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                          em: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppColors.muted,
                          ),
                          code: const TextStyle(
                            backgroundColor: AppColors.surface,
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'ARCHIVOS ADJUNTOS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: doc.downloadableFileUrls.isEmpty
                          ? const Text(
                        'Este documento no tiene archivos disponibles.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      )
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: FractionallySizedBox(
                              widthFactor: 0.5,
                              child: ElevatedButton.icon(
                                onPressed:
                                _downloadingAll ? null : _downloadAll,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.background,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 9,
                                  ),
                                  minimumSize: const Size(0, 38),
                                ),
                                icon: _downloadingAll
                                    ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.background,
                                  ),
                                )
                                    : const Icon(
                                  Icons.download_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  doc.fileUrls.length == 1
                                      ? 'DESCARGAR'
                                      : 'DESCARGAR TODOS',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (var index = 0;
                          index < doc.downloadableFileUrls.length;
                          index++) ...[
                            if (index > 0) const SizedBox(height: 8),
                            RepositoryFileDownloadTile(
                              fileUrl: doc.downloadableFileUrls[index],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (canReview)
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _reviewing ? null : () => _review(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('RECHAZAR',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _reviewing ? null : () => _review(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.background,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _reviewing
                                ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.background))
                                : const Text('APROBAR PUBLICACIÓN',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.muted)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

class _DetailStatusBadge extends StatelessWidget {
  const _DetailStatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isRejected = status.toLowerCase() == 'rechazado';
    final color = isRejected ? AppColors.error : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        isRejected ? 'RECHAZADO' : 'EN REVISIÓN',
        style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0),
      ),
    );
  }
}

String formatRepositoryDetailDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}