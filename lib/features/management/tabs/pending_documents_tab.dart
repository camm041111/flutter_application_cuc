import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/coordinator_providers.dart';
import '../widgets/empty_panel_message.dart';
import '../widgets/management_tile.dart';

class PendingDocumentsTab extends ConsumerWidget {
  const PendingDocumentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingDocumentsProvider);

    return pendingAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, s) => EmptyPanelMessage(
        icon: Icons.cloud_off_outlined,
        text: 'No se pudieron cargar los documentos.\n$e',
        isError: true,
      ),
      data: (docs) {
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(18),
            child: EmptyPanelMessage(
              icon: Icons.task_alt_rounded,
              text: 'No hay documentos pendientes de revisión.',
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            return ManagementTile(
              icon: Icons.description_outlined,
              title: doc.title,
              subtitle: '${doc.category} · ${doc.authorName}',
              actions: [
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error.withValues(alpha: 0.14),
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 17),
                  label: const Text(
                    'RECHAZAR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  onPressed: () => _showRejectDialog(context, ref, doc),
                ),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 17),
                  label: const Text(
                    'APROBAR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  onPressed: () async {
                    final success = await CoordinatorActions.reviewDocument(
                      ref,
                      doc.id,
                      approved: true,
                    );
                    if (!context.mounted) return;
                    _showResult(
                      context,
                      success,
                      'Documento aprobado oficialmente',
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showRejectDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic doc,
  ) async {
    final commentController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: 23,
                ),
                SizedBox(width: 10),
                Text(
                  'Rechazar Documento',
                  style: TextStyle(color: AppColors.error),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Documento: ${doc.title}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Explica los motivos del rechazo (Obligatorio)...',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 10
                            ? 'Proporciona al menos 10 caracteres de feedback.'
                            : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    isSubmitting ? null : () => Navigator.pop(dialogContext),
                child: const Text(
                  'CANCELAR',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setState(() => isSubmitting = true);

                        final success = await CoordinatorActions.reviewDocument(
                          ref,
                          doc.id,
                          approved: false,
                          comment: commentController.text.trim(),
                        );

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        _showResult(
                          dialogContext,
                          success,
                          success
                              ? 'Documento devuelto con comentarios'
                              : 'Fallo en la base de datos',
                        );
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('RECHAZAR'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResult(BuildContext context, bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? message : 'Error al procesar la solicitud'),
        backgroundColor: success ? const Color(0xFF007A33) : Colors.red,
      ),
    );
  }
}
