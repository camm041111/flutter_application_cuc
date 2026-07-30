import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/profile_providers.dart';

class ProfileStatsRow extends ConsumerWidget {
  final String userId;
  const ProfileStatsRow({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider(userId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: statsAsync.when(
              loading: () => const _StatCard(
                label: 'PUBLICACIONES',
                value: '...',
                isLoading: true,
              ),
              error: (_, __) => const _StatCard(
                label: 'PUBLICACIONES',
                value: '0',
              ),
              data: (stats) => _StatCard(
                label: 'PUBLICACIONES',
                value: stats.publicaciones.toString(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: statsAsync.when(
              loading: () => const _StatCard(
                label: 'ACTIVIDAD EN EL FORO',
                value: '...',
                isLoading: true,
              ),
              error: (_, __) => const _StatCard(
                label: 'ACTIVIDAD EN EL FORO',
                value: '0',
              ),
              data: (stats) => _StatCard(
                label: 'ACTIVIDAD EN EL FORO',
                value: stats.foro.toString(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sub-componente privado, solo se usa aquí.
class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.isLoading = false});

  final String label;
  final String value;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 152,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.75),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  label == 'PUBLICACIONES'
                      ? Icons.science_outlined
                      : Icons.forum_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const SizedBox(
              height: 32,
              width: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                height: 1,
                fontWeight: FontWeight.w800,
                color: AppColors.onBackground,
              ),
            ),
          const SizedBox(height: 9),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              height: 1.25,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
