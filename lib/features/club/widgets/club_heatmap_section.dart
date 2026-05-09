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
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Actividad Colectiva',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              Row(children: ContributionHeatmap.legend()),
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
              decoration:
                  BoxDecoration(border: Border.all(color: AppColors.border)),
              child:
                  const Center(child: Text('Error cargando actividad grupal')),
            ),
            data: (data) => ContributionHeatmap(data: data),
          ),
        ],
      ),
    );
  }
}
