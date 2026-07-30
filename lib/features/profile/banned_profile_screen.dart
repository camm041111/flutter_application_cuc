import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class BannedProfileScreen extends ConsumerWidget {
  const BannedProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(
                Icons.block_flipped,
                size: 80,
                color: AppColors.error,
              ),
              const SizedBox(height: 24),
              const Text(
                'ACCESO DENEGADO',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tu cuenta ha sido dada de baja del club. Si consideras que '
                'esto es un error, por favor contacta inmediatamente a tu '
                'Coordinador de División Académica.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.muted,
                  height: 1.6,
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => ref.read(authServiceProvider).cerrarSesion(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Text(
                  'CERRAR SESIÓN',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
