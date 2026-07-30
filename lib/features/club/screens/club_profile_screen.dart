import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cuc_app_bar.dart';
import '../../profile/providers/profile_providers.dart';
import '../widgets/club_header.dart';
import '../widgets/club_metrics_row.dart';
import '../widgets/club_heatmap_section.dart';
import '../widgets/club_directory_tabs.dart';

class ClubProfileScreen extends ConsumerWidget {
  final String clubId;

  const ClubProfileScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentProfileAsync = ref.watch(currentUserProfileProvider);
    final canViewHistory = currentProfileAsync.maybeWhen(
      data: (profile) =>
          profile != null &&
          profile.clubId == clubId &&
          (profile.rol == 'coordinador' || profile.rol == 'lider'),
      orElse: () => false,
    );

    return DefaultTabController(
      length: canViewHistory ? 2 : 1,
      child: Scaffold(
        backgroundColor: AppColors.background,
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
                      const SizedBox(height: 16),
                      ClubMetricsRow(clubId: clubId),
                      const SizedBox(height: 24),
                      ClubHeatmapSection(clubId: clubId),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    indicator: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.muted,
                    labelStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                    tabs: [
                      const Tab(text: 'MIEMBROS ACTIVOS'),
                      if (canViewHistory) const Tab(text: 'HISTÓRICO'),
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: _tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
