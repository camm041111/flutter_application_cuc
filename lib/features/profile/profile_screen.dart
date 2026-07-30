// lib/features/profile/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/cache/app_cache_service.dart';
import '../../core/providers/auth_providers.dart';
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
      backgroundColor: AppColors.background,
      appBar: const CucAppBar(),
      body: profileAsync.when(
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
            child: Text(
              'Error: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        data: (profile) => RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            await ref
                .read(appCacheServiceProvider)
                .invalidate('profile:$userId');
            ref.invalidate(profileProvider(userId));
            ref.invalidate(statsProvider(userId));
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              ProfileHeader(profile: profile, isOwner: isOwner),
              const SizedBox(height: 16),

              // 🛡️ PASO 1: Lógica de Acceso al Panel de Gestión
              if (isOwner &&
                  (profile.rol == 'coordinador' || profile.rol == 'lider'))
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 20,
                    ),
                    label: const Text(
                      'PANEL DE GESTIÓN DEL CLUB',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CoordinatorPanelScreen(),
                      ),
                    ),
                  ),
                ),

              ProfileStatsRow(userId: userId),
              ProfileRankCard(userId: userId),
              const SizedBox(height: 24),
              ActivityHeatmapSection(userId: userId),
              const SizedBox(height: 24),
              RecentPostsSection(userId: userId),
            ],
          ),
        ),
      ),
    );
  }
}
