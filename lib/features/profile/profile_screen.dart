// lib/features/profile/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      appBar: const CucAppBar(),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (profile) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(profileProvider(userId));
            ref.invalidate(statsProvider(userId));
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              ProfileHeader(profile: profile),

              // 🛡️ PASO 1: Lógica de Acceso al Panel de Gestión
              if (isOwner && profile.rol == 'coordinador')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B2B20),
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('PANEL DE GESTIÓN DEL CLUB',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CoordinatorPanelScreen()),
                  ),
                ),
              ),

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