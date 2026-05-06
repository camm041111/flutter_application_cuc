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
    final pendingAsync = ref.watch(pendingMembersProvider);

    return Scaffold(
      appBar: const CucAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 24, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Panel de Gestión',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('Aprobación manual de nuevos registros',
                    style: TextStyle(fontSize: 13, color: AppColors.primary)),
              ],
            ),
          ),

          Expanded(
            child: pendingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
              data: (users) {
                if (users.isEmpty) {
                  return const Center(child: Text('Sin solicitudes pendientes.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(child: Icon(Icons.person)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user['nombre_completo'],
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Matrícula: ${user['matricula']}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                              ],
                            ),
                          ),
                          // 🛡️ PASO 3: Botón con feedback de SnackBar
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: AppColors.primary),
                            onPressed: () async {
                              final success = await CoordinatorActions.approveMember(ref, user['id']);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? 'Miembro activado correctamente'
                                        : 'Error al procesar aprobación'),
                                    backgroundColor: success ? const Color(0xFF007A33) : Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}