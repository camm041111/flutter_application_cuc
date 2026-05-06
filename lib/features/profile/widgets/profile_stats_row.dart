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
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: statsAsync.when(
              loading: () => const _StatCard(label: 'PUBLICACIONES', value: '...', isLoading: true),
              error: (_, __) => const _StatCard(label: 'PUBLICACIONES', value: '0'),
              data: (stats) => _StatCard(label: 'PUBLICACIONES', value: stats.publicaciones.toString()),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: statsAsync.when(
              loading: () => const _StatCard(label: 'ACTIVIDAD EN EL FORO', value: '...', isLoading: true),
              error: (_, __) => const _StatCard(label: 'ACTIVIDAD EN EL FORO', value: '0'),
              data: (stats) => _StatCard(label: 'ACTIVIDAD EN EL FORO', value: stats.foro.toString()),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          const SizedBox(height: 6),
          if (isLoading)
            const SizedBox(height: 28, width: 28, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
          else
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.onBackground)),
        ],
      ),
    );
  }
}