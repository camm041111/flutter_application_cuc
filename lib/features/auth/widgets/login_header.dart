import 'package:flutter/material.dart'; // Soluciona errores de StatelessWidget, Widget, etc.
import '../../../core/theme/app_theme.dart'; // Soluciona errores de AppColors

class LoginHeader extends StatelessWidget {
  final VoidCallback onBack;
  const LoginHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton( // Usamos IconButton estándar temporalmente o importa tu CircleIconButton
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'CLUBES UNIVERSITARIOS DE CIENCIAS',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2.5,
            color: AppColors.primary.withOpacity(0.6),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'INICIAR SESIÓN',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}