import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_routes.dart';
import 'auth_divider.dart'; // Importamos el nuevo componente

class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AuthDivider(label: '¿Aún no estás registrado?'),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/register'),
            icon: const Icon(Icons.science_outlined, size: 18),
            label: const Text('CREAR CUENTA'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
            ),
          ),
        ),
      ],
    );
  }
}