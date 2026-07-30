import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/coordinator_providers.dart';
import '../widgets/empty_panel_message.dart';
import '../widgets/management_tile.dart';

class MembersManagementTab extends ConsumerWidget {
  const MembersManagementTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingMembersProvider);
    final activeAsync = ref.watch(activeMembersProvider);
    final historicalAsync = ref.watch(historicalMembersProvider);

    return CustomScrollView(
      slivers: [
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
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: EmptyPanelMessage(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    child: ManagementTile(
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
                              ref,
                              user['id'],
                            );
                            if (!context.mounted) return;
                            _showResult(
                              context,
                              success,
                              'Miembro activado correctamente',
                            );
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
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: EmptyPanelMessage(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    child: ManagementTile(
                      icon: Icons.person_outline,
                      title: user['nombre_completo'],
                      subtitle:
                          'Rol actual: ${user['rol'].toString().toUpperCase()}',
                      actions: [
                        if (!isCoordinator)
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
                              bool success = false;
                              String msg = '';

                              if (value == 'ascender_lider') {
                                success = await CoordinatorActions.updateMember(
                                  ref,
                                  user['id'],
                                  'lider',
                                  'activo',
                                );
                                msg = 'Ascendido a Líder';
                              } else if (value == 'degradar_miembro') {
                                success = await CoordinatorActions.updateMember(
                                  ref,
                                  user['id'],
                                  'miembro',
                                  'activo',
                                );
                                msg = 'Degradado a Miembro';
                              } else if (value == 'estado_inactivo') {
                                success = await CoordinatorActions.updateMember(
                                  ref,
                                  user['id'],
                                  user['rol'],
                                  'inactivo',
                                );
                                msg = 'Marcado como Inactivo (Solo Lectura)';
                              } else if (value == 'estado_baja') {
                                success = await CoordinatorActions.updateMember(
                                  ref,
                                  user['id'],
                                  user['rol'],
                                  'baja',
                                );
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
                                        style: TextStyle(
                                          color: AppColors.primary,
                                        ),
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
                                        style: TextStyle(
                                          color: AppColors.error,
                                        ),
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
                  child: EmptyPanelMessage(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    child: ManagementTile(
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
                                    style: TextStyle(
                                      color: AppColors.primary,
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
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
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
