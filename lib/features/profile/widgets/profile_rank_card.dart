import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ProfileRankCard extends StatelessWidget {
  const ProfileRankCard({super.key});

  @override
  Widget build(BuildContext context) {
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top 5%',
                  style: TextStyle(
                    fontSize: 27,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onBackground,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 7),
                Text(
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'ÉLITE',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
