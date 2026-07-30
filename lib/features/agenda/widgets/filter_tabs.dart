import 'package:flutter/material.dart';

import '../../../core/widgets/cuc_pill_tab_bar.dart';

class FilterTabs extends StatelessWidget {
  const FilterTabs({
    super.key,
    required this.showFuture,
    required this.onChanged,
  });

  final bool showFuture;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: showFuture ? 0 : 1,
      child: CucPillTabBar(
        labels: const ['EVENTOS FUTUROS', 'EVENTOS PASADOS'],
        icons: const [Icons.upcoming_outlined, Icons.history_rounded],
        onTap: (index) => onChanged(index == 0),
      ),
    );
  }
}
