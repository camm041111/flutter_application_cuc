import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ContributionHeatmap extends StatelessWidget {
  const ContributionHeatmap({
    super.key,
    required this.data,
    this.weekCount = 13,
  });

  final Map<DateTime, int> data;
  final int weekCount;

  // 🛡️ Escala Científica Institucional
  static List<Color> _getColors(BuildContext context) => [
    AppColors.border.withValues(alpha: 0.2), // Nivel 0
    const Color(0xFF84BD00).withValues(alpha: 0.5), // Nivel 1
    const Color(0xFF84BD00), // Nivel 2
    const Color(0xFF509E2F), // Nivel 3
    AppColors.primary, // Nivel 4
  ];

  static const List<String> _monthLabels = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
  ];

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final firstDay = today.subtract(Duration(days: weekCount * 7 - 1));
    final days = List.generate(
      weekCount * 7,
          (index) => firstDay.add(Duration(days: index)),
    );

    final colors = _getColors(context);

    return Container(
      // 🛡️ CORRECCIÓN: Se elimina el "height: 140" estático.
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 3.0;

          // 🛡️ ARQUITECTURA: El ancho de la pantalla manda.
          // Calculamos el tamaño de celda exacto para llenar el 100% del espacio horizontal.
          final cellSize = (constraints.maxWidth - gap * (weekCount - 1)) / weekCount;

          return Column(
            mainAxisSize: MainAxisSize.min, // 🛡️ Permite que el contenedor crezca verticalmente lo necesario
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── CABECERA DE MESES (EJE TEMPORAL) ───
              SizedBox(
                height: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(weekCount, (weekIndex) {
                    final firstDayOfWeek = days[weekIndex * 7];
                    final isFirstWeekOfMonth = firstDayOfWeek.day <= 7;

                    return Container(
                      width: weekIndex == weekCount - 1 ? cellSize : cellSize + gap,
                      alignment: Alignment.bottomLeft,
                      child: isFirstWeekOfMonth
                          ? Text(
                        _monthLabels[firstDayOfWeek.month - 1],
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                          letterSpacing: 0.5,
                        ),
                      )
                          : const SizedBox.shrink(),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 6),
              // ─── MATRIZ DE CONTRIBUCIONES ───
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(weekCount, (weekIndex) {
                  return Padding(
                    padding: EdgeInsets.only(right: weekIndex == weekCount - 1 ? 0 : gap),
                    child: Column(
                      // Se utiliza el margin en la celda para dar el gap vertical dinámico
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: List.generate(7, (dayIndex) {
                        final day = days[weekIndex * 7 + dayIndex];
                        final isFuture = day.isAfter(today);
                        final level = isFuture ? 0 : (data[_dateOnly(day)] ?? 0).clamp(0, 4);

                        final cell = Container(
                          width: cellSize,
                          height: cellSize,
                          // El espaciado vertical se aplica a cada celda excepto la última
                          margin: EdgeInsets.only(bottom: dayIndex == 6 ? 0 : gap),
                          decoration: BoxDecoration(
                            color: isFuture ? Colors.transparent : colors[level],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );

                        if (isFuture) return cell;

                        return Tooltip(
                          message: '${_formatDate(day)}: $level contribuciones',
                          preferBelow: false,
                          textStyle: const TextStyle(fontSize: 11, color: AppColors.background, fontWeight: FontWeight.w600),
                          decoration: BoxDecoration(
                            color: AppColors.onSurface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: cell,
                        );
                      }),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  static List<Widget> legend() {
    final colors = [
      AppColors.border.withValues(alpha: 0.2),
      const Color(0xFF84BD00).withValues(alpha: 0.5),
      const Color(0xFF84BD00),
      const Color(0xFF509E2F),
      AppColors.primary,
    ];

    return colors.map((color) => Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    )).toList();
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}