import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ProfileRankCard extends StatelessWidget {
  const ProfileRankCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top 5%', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.onBackground)),
          SizedBox(height: 2),
          Text('EN CONTRIBUCIONES', style: TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: 0.8)),
        ],
      ),
    );
  }
}