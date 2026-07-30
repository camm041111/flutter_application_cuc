import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/repository_providers.dart';
import '../widgets/repository_document_card.dart';
import '../widgets/repository_upload_sheet.dart';

class MyContributionsScreen extends ConsumerWidget {
  const MyContributionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(myDocumentsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MIS APORTACIONES'),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.muted,
            labelStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
            tabs: [
              Tab(text: 'APROBADOS'),
              Tab(text: 'EN REVISIÓN'),
              Tab(text: 'RECHAZADOS'),
            ],
          ),
        ),
        body: documentsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, _) => _ContributionsError(
            message: error.toString(),
            onRetry: () => ref.invalidate(myDocumentsProvider),
          ),
          data: (documents) => TabBarView(
            children: [
              _ContributionsTab(
                documents: _withStatus(documents, 'aprobado'),
                emptyMessage: 'Aún no tienes documentos aprobados.',
              ),
              _ContributionsTab(
                documents: _withStatus(documents, 'pendiente'),
                emptyMessage: 'No tienes documentos en revisión.',
              ),
              _ContributionsTab(
                documents: _withStatus(documents, 'rechazado'),
                emptyMessage: 'No tienes documentos rechazados.',
                showReviewFeedback: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static List<RepositoryDocument> _withStatus(
    List<RepositoryDocument> documents,
    String status,
  ) {
    return documents
        .where((document) => document.status.toLowerCase() == status)
        .toList(growable: false);
  }
}

class _ContributionsTab extends ConsumerWidget {
  const _ContributionsTab({
    required this.documents,
    required this.emptyMessage,
    this.showReviewFeedback = false,
  });

  final List<RepositoryDocument> documents;
  final String emptyMessage;
  final bool showReviewFeedback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.refresh(myDocumentsProvider.future).then<void>((_) {});
      },
      child: documents.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 100),
                Icon(
                  showReviewFeedback
                      ? Icons.task_alt_outlined
                      : Icons.folder_off_outlined,
                  size: 52,
                  color: AppColors.muted,
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              itemCount: documents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _ContributionCard(
                document: documents[index],
                showReviewFeedback: showReviewFeedback,
              ),
            ),
    );
  }
}

class _ContributionCard extends StatelessWidget {
  const _ContributionCard({
    required this.document,
    required this.showReviewFeedback,
  });

  final RepositoryDocument document;
  final bool showReviewFeedback;

  Future<void> _openCorrectionForm(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RepositoryUploadSheet(documentToEdit: document),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = document.status.toLowerCase() == 'rechazado';
    final accent = isRejected ? AppColors.error : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: isRejected ? 0.65 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  repositoryCategoryIcon(document.category),
                  color: accent,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      repositoryCategoryOptions[document.category] ??
                          document.category,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: document.status),
            ],
          ),
          if (document.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              document.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
          if (showReviewFeedback) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.feedback_outlined,
                        color: AppColors.error,
                        size: 18,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'COMENTARIOS DE REVISIÓN',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    document.reviewComments?.trim().isNotEmpty == true
                        ? document.reviewComments!.trim()
                        : 'El coordinador no agregó comentarios.',
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openCorrectionForm(context),
                icon: const Icon(Icons.edit_document, size: 18),
                label: const Text('CORREGIR Y REENVIAR'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isRejected = normalized == 'rechazado';
    final color = isRejected ? AppColors.error : AppColors.primary;
    final label = switch (normalized) {
      'aprobado' => 'APROBADO',
      'rechazado' => 'RECHAZADO',
      _ => 'EN REVISIÓN',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ContributionsError extends StatelessWidget {
  const _ContributionsError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.error,
              size: 44,
            ),
            const SizedBox(height: 12),
            const Text(
              'No se pudieron cargar tus aportaciones.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('REINTENTAR'),
            ),
          ],
        ),
      ),
    );
  }
}
