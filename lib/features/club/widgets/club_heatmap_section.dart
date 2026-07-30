import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/contribution_heatmap.dart';
import '../providers/club_providers.dart';

class ClubHeatmapSection extends ConsumerWidget {
  final String clubId;
  const ClubHeatmapSection({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapAsync = ref.watch(clubHeatmapProvider(clubId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACTIVIDAD COLECTIVA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.onBackground,
                ),
              ),
              Row(children: ContributionHeatmap.legend()),
            ],
          ),
          const SizedBox(height: 12),
          heatmapAsync.when(
            loading: () => const SizedBox(
                height: 120,
                child: Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))),
            error: (e, s) => Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Error cargando actividad grupal',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            data: (data) => ContributionHeatmap(data: data),
          ),
        ],
      ),
    );
  }
}
