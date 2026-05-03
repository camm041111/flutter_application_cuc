import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/club_providers.dart';

class ClubDirectoryTabs extends ConsumerWidget {
  final String clubId;
  const ClubDirectoryTabs({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directoryAsync = ref.watch(clubDirectoryProvider(clubId));

    return directoryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, s) => const Center(child: Text('Error al cargar directorio', style: TextStyle(color: AppColors.muted))),
      data: (directory) {
        return TabBarView(
          children: [
            // Pestaña 1: Activos
            _MemberList(members: directory.activos),
            // Pestaña 2: Bajas / Histórico
            _MemberList(members: directory.historico, isHistorical: true),
          ],
        );
      },
    );
  }
}

class _MemberList extends StatelessWidget {
  final List<dynamic> members;
  final bool isHistorical;

  const _MemberList({required this.members, this.isHistorical = false});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Center(
        child: Text(
          isHistorical ? 'No hay registros históricos.' : 'No hay miembros activos.',
          style: const TextStyle(color: AppColors.muted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: members.length,
      separatorBuilder: (_, __) => const Divider(color: AppColors.border),
      itemBuilder: (context, index) {
        final user = members[index];
        final isCoordinator = user['rol'] == 'coordinador';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF1B2B20),
            backgroundImage: user['url_avatar'] != null ? NetworkImage(user['url_avatar']) : null,
            child: user['url_avatar'] == null ? const Icon(Icons.person, color: AppColors.primary) : null,
          ),
          title: Text(
            user['nombre_completo'],
            style: TextStyle(
              fontWeight: isCoordinator ? FontWeight.w700 : FontWeight.w500,
              color: isHistorical ? AppColors.muted : AppColors.onBackground,
            ),
          ),
          subtitle: Text(
            isCoordinator ? 'COORDINADOR' : 'INVESTIGADOR',
            style: const TextStyle(fontSize: 11, color: AppColors.primary, letterSpacing: 0.5),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
          onTap: () {
            // Lógica de navegación hacia el perfil personal inyectando user['id']
          },
        );
      },
    );
  }
}