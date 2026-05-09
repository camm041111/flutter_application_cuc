import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ContributionHeatmap extends StatelessWidget {
  const ContributionHeatmap({
    super.key,
    required this.data,
    this.weekCount = 26,
  });

  final Map<DateTime, int> data;
  final int weekCount;

  static const _colors = [
    Color(0xFF1B2B20),
    Color(0xFF007A33),
    Color(0xFF509E2F),
    Color(0xFF84BD00),
    AppColors.primary,
  ];

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final firstDay = today.subtract(Duration(days: weekCount * 7 - 1));
    final days = List.generate(
      weekCount * 7,
      (index) => firstDay.add(Duration(days: index)),
    );

    return Container(
      height: 132,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 3.0;
          final maxWidthCell =
              (constraints.maxWidth - gap * (weekCount - 1)) / weekCount;
          final maxHeightCell = (constraints.maxHeight - gap * 6) / 7;
          final cellSize = maxWidthCell
              .clamp(6.0, 13.0)
              .clamp(6.0, maxHeightCell)
              .toDouble();

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(weekCount, (weekIndex) {
              return Padding(
                padding: EdgeInsets.only(
                    right: weekIndex == weekCount - 1 ? 0 : gap),
                child: Column(
                  children: List.generate(7, (dayIndex) {
                    final day = days[weekIndex * 7 + dayIndex];
                    final level = (data[_dateOnly(day)] ?? 0).clamp(0, 4);

                    return Tooltip(
                      message: '${_formatDate(day)}: $level contribuciones',
                      child: Container(
                        width: cellSize,
                        height: cellSize,
                        margin: EdgeInsets.only(
                          bottom: dayIndex == 6 ? 0 : gap,
                        ),
                        decoration: BoxDecoration(
                          color: _colors[level],
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.03),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  static List<Widget> legend() {
    return _colors
        .map(
          (color) => Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(left: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        )
        .toList();
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}
