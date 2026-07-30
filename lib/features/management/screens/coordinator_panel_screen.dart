// lib/features/management/screens/coordinator_panel_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cuc_app_bar.dart';
import '../../../core/widgets/cuc_pill_tab_bar.dart';
import '../providers/coordinator_providers.dart';

class CoordinatorPanelScreen extends ConsumerWidget {
  const CoordinatorPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CucAppBar(),
        body: ColoredBox(
          color: AppColors.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20, 26, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panel de Gestión',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Aprobación para líderes y coordinadores',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              CucPillTabBar(
                labels: ['MIEMBROS', 'DOCUMENTOS'],
              ),
              SizedBox(height: 8),
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
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: _EmptyPanelMessage(
                    icon: Icons.person_add_alt_1_outlined,
                    text: 'No hay solicitudes pendientes.',
                  ),
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
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.14),
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
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
                              letterSpacing: 0.8,
                            ),
                          ),
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
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: _EmptyPanelMessage(
                    icon: Icons.groups_outlined,
                    text: 'No hay otros miembros activos.',
                  ),
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
                            elevation: 12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: AppColors.border.withValues(alpha: 0.5),
                              ),
                            ),
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
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.trending_up_rounded,
                                        color: AppColors.primary,
                                        size: 19,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Ascender a Líder',
                                        style:
                                            TextStyle(color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              if (isLeader)
                                const PopupMenuItem(
                                  value: 'degradar_miembro',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person_remove_outlined,
                                        color: AppColors.error,
                                        size: 19,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Degradar a Miembro',
                                        style:
                                            TextStyle(color: AppColors.error),
                                      ),
                                    ],
                                  ),
                                ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'estado_inactivo',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.pause_circle_outline,
                                      color: AppColors.muted,
                                      size: 19,
                                    ),
                                    SizedBox(width: 10),
                                    Text('Marcar Inactivo (Egreso)'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'estado_baja',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: AppColors.error,
                                      size: 21,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Dar de Baja (Expulsión)',
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
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
                  padding: EdgeInsets.fromLTRB(18, 8, 18, 24),
                  child: _EmptyPanelMessage(
                    icon: Icons.history_rounded,
                    text: 'No hay miembros inactivos o dados de baja.',
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
                          elevation: 12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: AppColors.border.withValues(alpha: 0.5),
                            ),
                          ),
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
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.restore_rounded,
                                    color: AppColors.primary,
                                    size: 19,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Restaurar a Miembro Activo',
                                    style: TextStyle(color: AppColors.primary),
                                  ),
                                ],
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
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, s) => _EmptyPanelMessage(
        icon: Icons.cloud_off_outlined,
        text: 'No se pudieron cargar los documentos.\n$e',
        isError: true,
      ),
      data: (docs) {
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(18),
            child: _EmptyPanelMessage(
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
            return _ManagementTile(
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
              child: const Text('CANCELAR',
                  style: TextStyle(color: AppColors.muted)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(
              color: AppColors.border.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: actions,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyPanelMessage extends StatelessWidget {
  const _EmptyPanelMessage({
    required this.icon,
    required this.text,
    this.isError = false,
  });

  final IconData icon;
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: (isError ? AppColors.error : AppColors.border)
                .withValues(alpha: isError ? 0.35 : 0.45),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: isError ? AppColors.error : AppColors.muted,
            ),
            const SizedBox(height: 14),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isError ? AppColors.error : AppColors.muted,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
