import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/contribution_heatmap.dart';
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Actividad',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              Row(
                children: ContributionHeatmap.legend(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          heatmapAsync.when(
            loading: () => const SizedBox(
                height: 120,
                child: Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))),
            error: (e, s) => Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('Error cargando actividad',
                  style: TextStyle(color: AppColors.muted)),
            ),
            data: (data) => ContributionHeatmap(data: data),
          ),
        ],
      ),
    );
  }
}
