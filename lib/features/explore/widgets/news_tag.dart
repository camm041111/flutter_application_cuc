import 'package:flutter/material.dart';

class NewsTag extends StatelessWidget {
  const NewsTag({
    super.key,
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        decoration: BoxDecoration(
          // Equivalente a bg-surface-container-high
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(4.0),
          // Equivalente a border border-primary/20
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                // Equivalente a text-primary
                color: colorScheme.primary,
                letterSpacing: 1.2,
              ),
            ),
            // Si estuviéramos en modo edición agregaríamos el ícono de cerrar,
            // pero para lectura en el feed solo mostramos el texto.
          ],
        ),
      ),
    );
  }
}
