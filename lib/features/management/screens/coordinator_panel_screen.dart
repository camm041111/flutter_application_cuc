// lib/features/management/screens/coordinator_panel_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cuc_app_bar.dart';
import '../providers/coordinator_providers.dart';

class CoordinatorPanelScreen extends ConsumerWidget {
  const CoordinatorPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CucAppBar(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(18, 24, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Panel de Gestión',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Aprobación para líderes y coordinadores',
                      style: TextStyle(fontSize: 13, color: AppColors.primary)),
                ],
              ),
            ),
            TabBar(
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.muted,
              tabs: [
                Tab(text: 'MIEMBROS'),
                Tab(text: 'DOCUMENTOS'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _PendingMembersTab(),
                  _PendingDocumentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingMembersTab extends ConsumerWidget {
  const _PendingMembersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingMembersProvider);

    return pendingAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (users) {
        if (users.isEmpty) {
          return const _EmptyPanelMessage(
              text: 'Sin solicitudes de miembros pendientes.');
        }

        return ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final user = users[index];
            return _ManagementTile(
              icon: Icons.person,
              title: user['nombre_completo'],
              subtitle: 'Matrícula: ${user['matricula']}',
              actions: [
                IconButton(
                  tooltip: 'Aprobar miembro',
                  icon:
                      const Icon(Icons.check_circle, color: AppColors.primary),
                  onPressed: () async {
                    final success =
                        await CoordinatorActions.approveMember(ref, user['id']);
                    if (!context.mounted) return;
                    _showResult(
                        context, success, 'Miembro activado correctamente');
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PendingDocumentsTab extends ConsumerWidget {
  const _PendingDocumentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingDocumentsProvider);

    return pendingAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (docs) {
        if (docs.isEmpty) {
          return const _EmptyPanelMessage(text: 'Sin documentos pendientes.');
        }

        return ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            return _ManagementTile(
              icon: Icons.description_outlined,
              title: doc.title,
              subtitle: '${doc.category} · ${doc.authorName}',
              actions: [
                IconButton(
                  tooltip: 'Rechazar documento',
                  icon: const Icon(Icons.cancel, color: AppColors.error),
                  onPressed: () async {
                    final success = await CoordinatorActions.reviewDocument(
                      ref,
                      doc.id,
                      approved: false,
                    );
                    if (!context.mounted) return;
                    _showResult(context, success, 'Documento rechazado');
                  },
                ),
                IconButton(
                  tooltip: 'Aprobar documento',
                  icon:
                      const Icon(Icons.check_circle, color: AppColors.primary),
                  onPressed: () async {
                    final success = await CoordinatorActions.reviewDocument(
                      ref,
                      doc.id,
                      approved: true,
                    );
                    if (!context.mounted) return;
                    _showResult(context, success, 'Documento aprobado');
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ManagementTile extends StatelessWidget {
  const _ManagementTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.surfaceVariant,
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _EmptyPanelMessage extends StatelessWidget {
  const _EmptyPanelMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text, style: const TextStyle(color: AppColors.muted)),
    );
  }
}

void _showResult(BuildContext context, bool success, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(success ? message : 'Error al procesar la solicitud'),
      backgroundColor: success ? const Color(0xFF007A33) : Colors.red,
    ),
  );
}
