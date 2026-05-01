import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AuthDivider extends StatelessWidget {
  final String label;

  const AuthDivider({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Línea izquierda
        Expanded(
          child: Divider(
            color: AppColors.primary.withOpacity(0.1),
            thickness: 1,
          ),
        ),
        // Texto central
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label.toUpperCase(), // Mantenemos la estética de mayúsculas del proyecto
            style: TextStyle(
              fontSize: 10,
              color: AppColors.muted,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Línea derecha
        Expanded(
          child: Divider(
            color: AppColors.primary.withOpacity(0.1),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}