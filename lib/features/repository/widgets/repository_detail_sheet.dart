import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/repository_providers.dart';
import 'repository_filter_sheet.dart';

class RepositoryDetailSheet extends ConsumerStatefulWidget {
  const RepositoryDetailSheet({
    super.key,
    required this.document,
  });

  final RepositoryDocument document;

  @override
  ConsumerState<RepositoryDetailSheet> createState() =>
      RepositoryDetailSheetState();
}

class RepositoryDetailSheetState extends ConsumerState<RepositoryDetailSheet> {
  bool _reviewing = false;

  Future<void> _review(bool isApproved) async {
    if (_reviewing) {
      return;
    }

    setState(() => _reviewing = true);
    try {
      await ref
          .read(repositoryActionsProvider)
          .reviewDocument(widget.document.id, isApproved);
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo revisar el documento: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _reviewing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final document = widget.document;
    final canReview = profileAsync.maybeWhen(
      data: (profile) =>
          document.status.toLowerCase() == 'pendiente' &&
          profile != null &&
          (profile.rol == 'coordinador' || profile.rol == 'lider') &&
          profile.clubId == document.clubId,
      orElse: () => false,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            document.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    if (document.status.toLowerCase() != 'aprobado') ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: RepositoryDocumentStatusBadge(
                          status: document.status,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    RepositoryDetailField(
                      label: 'AUTOR',
                      value: document.authorName,
                    ),
                    RepositoryDetailField(
                      label: 'CLUB',
                      value: document.clubName,
                    ),
                    RepositoryDetailField(
                      label: 'FECHA',
                      value: formatRepositoryDate(document.createdAt),
                    ),
                    RepositoryDetailField(
                      label: 'CATEGORÍA',
                      value: repositoryCategoryOptions[document.category] ??
                          document.category,
                    ),
                    if (document.area.isNotEmpty)
                      RepositoryDetailField(
                        label: 'ÁREA DE CONOCIMIENTO',
                        value: repositoryAreaOptions[document.area] ??
                            document.area,
                      ),
                    const SizedBox(height: 6),
                    const RepositoryFilterLabel(label: 'DESCRIPCIÓN'),
                    const SizedBox(height: 8),
                    Text(
                      document.description.isEmpty
                          ? 'Sin descripción.'
                          : document.description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (document.tags.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const RepositoryFilterLabel(label: 'ETIQUETAS'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
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
              if (canReview)
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(
                        top: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _reviewing ? null : () => _review(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                            child: const Text('RECHAZAR'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _reviewing ? null : () => _review(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.background,
                            ),
                            child: _reviewing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.background,
                                    ),
                                  )
                                : const Text('APROBAR'),
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

class RepositoryDetailField extends StatelessWidget {
  const RepositoryDetailField({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RepositoryFilterLabel(label: label),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class RepositoryDocumentStatusBadge extends StatelessWidget {
  const RepositoryDocumentStatusBadge({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isRejected = normalized == 'rechazado';
    final color = isRejected ? AppColors.error : AppColors.primary;
    final label = isRejected ? 'Rechazado' : 'Pendiente';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class RepositoryDocumentTag extends StatelessWidget {
  const RepositoryDocumentTag({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label.startsWith('#') ? label : '#$label',
        style: const TextStyle(fontSize: 10, color: AppColors.muted),
      ),
    );
  }
}
