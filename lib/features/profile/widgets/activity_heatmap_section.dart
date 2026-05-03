import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/profile_providers.dart';

class ActivityHeatmapSection extends ConsumerWidget {
  final String userId;
  const ActivityHeatmapSection({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapAsync = ref.watch(heatmapProvider(userId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Actividad', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              Row(
                children: [
                  _LegendDot(color: Color(0xFF1B2B20)), // Nulo
                  SizedBox(width: 3),
                  _LegendDot(color: Color(0xFF007A33)), // PANTONE 356 C
                  SizedBox(width: 3),
                  _LegendDot(color: Color(0xFF509E2F)), // PANTONE 362 C
                  SizedBox(width: 3),
                  _LegendDot(color: Color(0xFF84BD00)), // PANTONE 376 C
                  SizedBox(width: 3),
                  _LegendDot(color: AppColors.primary), // Máximo
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          heatmapAsync.when(
            loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
            error: (e, s) => Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
              child: const Text('Error cargando actividad', style: TextStyle(color: AppColors.muted)),
            ),
            data: (data) => _ActivityHeatmap(data: data),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)));
  }
}

class _ActivityHeatmap extends StatelessWidget {
  final Map<DateTime, int> data;
  const _ActivityHeatmap({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text('Días activos: ${data.length}', style: const TextStyle(color: AppColors.muted)),
      ),
    );
  }
}