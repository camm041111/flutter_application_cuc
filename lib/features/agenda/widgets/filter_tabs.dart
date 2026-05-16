import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class FilterTabs extends StatelessWidget {
  const FilterTabs({
    super.key,
    required this.showFuture,
    required this.onChanged
  });

  final bool showFuture;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Eventos Futuros',
              icon: Icons.upcoming_outlined,
              active: showFuture,
              onTap: () => onChanged(true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TabButton(
              label: 'Eventos Pasados',
              icon: Icons.history,
              active: !showFuture,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 200);
    final currentTextColor = active ? AppColors.background : AppColors.muted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: duration,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: currentTextColor,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: AnimatedDefaultTextStyle( // Sugerencia 3: Transición tipográfica limpia
                duration: duration,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: currentTextColor,
                ),
                overflow: TextOverflow.ellipsis,
                child: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}