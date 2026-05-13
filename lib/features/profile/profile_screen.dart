// lib/features/profile/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/cache/app_cache_service.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cuc_app_bar.dart';
import '../management/screens/coordinator_panel_screen.dart'; // 👈 Importación necesaria
import 'providers/profile_providers.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_stats_row.dart';
import 'widgets/profile_rank_card.dart';
import 'widgets/activity_heatmap_section.dart';
import 'widgets/recent_posts_section.dart';

class ProfileScreen extends ConsumerWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider(userId));
    final currentUser = ref.read(supabaseClientProvider).auth.currentUser;
    final isOwner = currentUser?.id == userId;

    return Scaffold(
      appBar: const CucAppBar(),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (profile) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(appCacheServiceProvider).invalidate('profile:$userId');
            ref.invalidate(profileProvider(userId));
            ref.invalidate(statsProvider(userId));
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              ProfileHeader(profile: profile, isOwner: isOwner),

              // 🛡️ PASO 1: Lógica de Acceso al Panel de Gestión
              if (isOwner &&
                  (profile.rol == 'coordinador' || profile.rol == 'lider'))
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B2B20),
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text(
                      'PANEL DE GESTIÓN DEL CLUB',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CoordinatorPanelScreen(),
                      ),
                    ),
                  ),
                ),

              if (isOwner) _LogoutButton(ref: ref),

              ProfileStatsRow(userId: userId),
              const ProfileRankCard(),
              const SizedBox(height: 16),
              ActivityHeatmapSection(userId: userId),
              const SizedBox(height: 16),
              RecentPostsSection(userId: userId),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final WidgetRef ref;

  const _LogoutButton({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text('CERRAR SESIÓN'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => _confirmLogout(context),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres cerrar tu sesión actual?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('CERRAR SESIÓN'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;

    try {
      await ref.read(authServiceProvider).cerrarSesion();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cerrar sesión: $e')),
      );
    }
  }
}
