import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CucPillTabBar extends StatelessWidget implements PreferredSizeWidget {
  const CucPillTabBar({
    super.key,
    required this.labels,
    this.icons,
    this.onTap,
    this.horizontalPadding = 20,
  }) : assert(icons == null || icons.length == labels.length);

  final List<String> labels;
  final List<IconData?>? icons;
  final ValueChanged<int>? onTap;
  final double horizontalPadding;

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 0.7,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: TabBar(
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: AppColors.background,
            unselectedLabelColor: AppColors.muted,
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
            onTap: onTap,
            tabs: [
              for (var index = 0; index < labels.length; index++)
                Tab(
                  height: 42,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icons?[index] != null) ...[
                        Icon(icons![index], size: 17),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          labels[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
