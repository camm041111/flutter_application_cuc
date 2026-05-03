import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cuc_app_bar.dart';
import '../widgets/club_header.dart';
import '../widgets/club_metrics_row.dart';
import '../widgets/club_heatmap_section.dart';
import '../widgets/club_directory_tabs.dart';

class ClubProfileScreen extends ConsumerWidget {
  final String clubId;

  const ClubProfileScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2, // Activos | Histórico
      child: Scaffold(
        appBar: const CucAppBar(),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      ClubHeader(clubId: clubId),
                      ClubMetricsRow(clubId: clubId),
                      const SizedBox(height: 16),
                      ClubHeatmapSection(clubId: clubId),
                    ],
                  ),
                ),
              ),
              const SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.muted,
                    tabs: [
                      Tab(text: 'MIEMBROS ACTIVOS'),
                      Tab(text: 'HISTÓRICO'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: ClubDirectoryTabs(clubId: clubId),
        ),
      ),
    );
  }
}

// Delegado necesario para anclar el TabBar al hacer scroll
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  const _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background, // Mantiene el fondo oscuro impecable
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}