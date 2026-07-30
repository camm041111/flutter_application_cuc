import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/profile_screen.dart';
import '../providers/club_providers.dart';

class ClubDirectoryTabs extends ConsumerWidget {
  final String clubId;
  const ClubDirectoryTabs({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directoryAsync = ref.watch(clubDirectoryProvider(clubId));

    return directoryAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, s) => Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Text(
            'Error al cargar directorio',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
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
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            isHistorical
                ? 'No hay registros históricos.'
                : 'No hay miembros activos.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = members[index];
        final isCoordinator = user['rol'] == 'coordinador';

        return Container(
          decoration: BoxDecoration(
            color: isHistorical
                ? AppColors.surface.withValues(alpha: 0.65)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.75),
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: user['url_avatar'] != null
                    ? NetworkImage(user['url_avatar'])
                    : null,
                child: user['url_avatar'] == null
                    ? const Icon(
                        Icons.person_outline,
                        color: AppColors.primary,
                        size: 22,
                      )
                    : null,
              ),
            ),
            title: Text(
              user['nombre_completo'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isCoordinator ? FontWeight.w700 : FontWeight.w600,
                color: isHistorical ? AppColors.muted : AppColors.onBackground,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isHistorical
                        ? AppColors.border.withValues(alpha: 0.5)
                        : isCoordinator
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    isCoordinator ? 'COORDINADOR' : 'INVESTIGADOR',
                    style: TextStyle(
                      fontSize: 8,
                      color: isHistorical
                          ? AppColors.muted
                          : isCoordinator
                              ? AppColors.background
                              : AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
            trailing: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chevron_right,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            onTap: () {
              final userId = user['id'] as String?;
              if (userId == null) return;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(userId: userId),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
