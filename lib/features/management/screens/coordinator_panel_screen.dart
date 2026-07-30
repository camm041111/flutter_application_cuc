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
                  _MembersManagementTab(),
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

class _MembersManagementTab extends ConsumerWidget {
  const _MembersManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingMembersProvider);
    final activeAsync = ref.watch(activeMembersProvider);
    final historicalAsync = ref.watch(historicalMembersProvider);

    return CustomScrollView(
      slivers: [
        // ─── SECCIÓN 1: SOLICITUDES PENDIENTES ───
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              'SOLICITUDES DE INGRESO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        pendingAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          ),
          error: (e, s) => SliverToBoxAdapter(
            child: Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: AppColors.error))),
          ),
          data: (users) {
            if (users.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text('No hay solicitudes pendientes.',
                      style: TextStyle(color: AppColors.muted)),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final user = users[index];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: _ManagementTile(
                      icon: Icons.person_add_outlined,
                      title: user['nombre_completo'],
                      subtitle: 'Matrícula: ${user['matricula']}',
                      actions: [
                        IconButton(
                          tooltip: 'Aprobar Ingreso',
                          icon: const Icon(Icons.check_circle,
                              color: AppColors.primary),
                          onPressed: () async {
                            final success =
                                await CoordinatorActions.approveMember(
                                    ref, user['id']);
                            if (!context.mounted) return;
                            _showResult(context, success,
                                'Miembro activado correctamente');
                          },
                        ),
                      ],
                    ),
                  );
                },
                childCount: users.length,
              ),
            );
          },
        ),

        // ─── SECCIÓN 2: PLANTILLA ACTIVA (GESTIÓN DE ROLES) ───
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
            child: Text(
              'PLANTILLA DEL CLUB',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        activeAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          ),
          error: (e, s) => SliverToBoxAdapter(
            child: Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: AppColors.error))),
          ),
          data: (users) {
            if (users.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text('No hay otros miembros activos.',
                      style: TextStyle(color: AppColors.muted)),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final user = users[index];
                  final isLeader = user['rol'] == 'lider';
                  final isCoordinator = user['rol'] == 'coordinador';

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: _ManagementTile(
                      icon: Icons.person_outline,
                      title: user['nombre_completo'],
                      subtitle:
                          'Rol actual: ${user['rol'].toString().toUpperCase()}',
                      actions: [
                        if (!isCoordinator) // El UI bloquea interactuar con coordinadores por higiene visual
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                color: AppColors.muted),
                            color: AppColors.surface,
                            onSelected: (value) async {
                              bool success = false;
                              String msg = '';

                              if (value == 'ascender_lider') {
                                success = await CoordinatorActions.updateMember(
                                    ref, user['id'], 'lider', 'activo');
                                msg = 'Ascendido a Líder';
                              } else if (value == 'degradar_miembro') {
                                success = await CoordinatorActions.updateMember(
                                    ref, user['id'], 'miembro', 'activo');
                                msg = 'Degradado a Miembro';
                              } else if (value == 'estado_inactivo') {
                                success = await CoordinatorActions.updateMember(
                                    ref, user['id'], user['rol'], 'inactivo');
                                msg = 'Marcado como Inactivo (Solo Lectura)';
                              } else if (value == 'estado_baja') {
                                success = await CoordinatorActions.updateMember(
                                    ref, user['id'], user['rol'], 'baja');
                                msg = 'Dado de baja (Sin Acceso)';
                              }

                              if (!context.mounted) return;
                              _showResult(context, success, msg);
                            },
                            itemBuilder: (BuildContext context) => [
                              if (!isLeader)
                                const PopupMenuItem(
                                  value: 'ascender_lider',
                                  child: Text('Ascender a Líder',
                                      style:
                                          TextStyle(color: AppColors.primary)),
                                ),
                              if (isLeader)
                                const PopupMenuItem(
                                  value: 'degradar_miembro',
                                  child: Text('Degradar a Miembro',
                                      style: TextStyle(color: AppColors.error)),
                                ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'estado_inactivo',
                                child: Text('Marcar Inactivo (Egreso)'),
                              ),
                              const PopupMenuItem(
                                value: 'estado_baja',
                                child: Text('Dar de Baja (Expulsión)',
                                    style: TextStyle(color: AppColors.error)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
                childCount: users.length,
              ),
            );
          },
        ),

        // ─── SECCIÓN 3: HISTORIAL DE MIEMBROS ───
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
            child: Text(
              'MIEMBROS INACTIVOS O DADOS DE BAJA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        historicalAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, s) => SliverToBoxAdapter(
            child: Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
          data: (users) {
            if (users.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Text(
                    'No hay miembros inactivos o dados de baja.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final user = users[index];
                  final status = user['estado'].toString().toUpperCase();

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: _ManagementTile(
                      icon: Icons.person_off_outlined,
                      title: user['nombre_completo'],
                      subtitle: 'Estado actual: $status',
                      actions: [
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: AppColors.muted,
                          ),
                          color: AppColors.surface,
                          onSelected: (value) async {
                            if (value != 'restaurar') return;

                            final success =
                                await CoordinatorActions.updateMember(
                              ref,
                              user['id'],
                              'miembro',
                              'activo',
                            );
                            if (!context.mounted) return;
                            _showResult(
                              context,
                              success,
                              'Miembro restaurado correctamente',
                            );
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'restaurar',
                              child: Text(
                                'Restaurar a Miembro Activo',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                childCount: users.length,
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
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
                  onPressed: () => _showRejectDialog(context, ref, doc),
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
                    _showResult(
                        context, success, 'Documento aprobado oficialmente');
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

// 🛡️ DIALOGO DE RECHAZO (Obliga al coordinador a dar feedback)
Future<void> _showRejectDialog(
    BuildContext context, WidgetRef ref, dynamic doc) async {
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
          title: const Text('Rechazar Documento',
              style: TextStyle(color: AppColors.error)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Documento: ${doc.title}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
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
                        borderRadius: BorderRadius.circular(8)),
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
              child: const Text('CANCELAR',
                  style: TextStyle(color: AppColors.muted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white),
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
                              : 'Fallo en la base de datos');
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('RECHAZAR'),
            ),
          ],
        );
      },
    ),
  );
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
