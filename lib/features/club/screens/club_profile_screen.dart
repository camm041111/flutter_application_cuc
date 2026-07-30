import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cuc_app_bar.dart';
import '../../../core/widgets/cuc_pill_tab_bar.dart';
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
                  CucPillTabBar(
                    labels: [
                      'MIEMBROS ACTIVOS',
                      if (canViewHistory) 'HISTÓRICO',
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
  final PreferredSizeWidget _tabBar;
  const _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: AppColors.background,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
