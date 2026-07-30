import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/profile_providers.dart';

class ProfileRankCard extends ConsumerWidget {
  final String userId;
  const ProfileRankCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankAsync = ref.watch(rankProvider(userId));

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.75),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.leaderboard_outlined,
              color: AppColors.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                rankAsync.when(
                  loading: () => const Text(
                    'Top --%',
                    style: TextStyle(
                      fontSize: 27,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onBackground,
                      letterSpacing: -0.4,
                    ),
                  ),
                  error: (_, __) => const Text(
                    'Top 100%',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
                  ),
                  data: (rank) => Text(
                    'Top ${rank.percentil}%',
                    style: const TextStyle(
                      fontSize: 27,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onBackground,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'RANGO EN CONTRIBUCIONES',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          rankAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (rank) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                rank.etiqueta,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}