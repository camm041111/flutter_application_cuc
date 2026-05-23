import 'package:flutter/material.dart';
import '../theme/app_theme.dart'; // Asegúrate de ajustar la ruta relativa según corresponda

class CucSnackBar {
  /// Muestra un SnackBar premium con la estética unificada del CUC.
  static void show(
      BuildContext context, {
        required String message,
        IconData icon = Icons.check_circle_outline,
        Color iconColor = AppColors.primary,
        //Color borderColor = AppColors.primary,
      }) {
    // Limpia cualquier SnackBar activo previo para evitar acumulaciones en cola
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.fondo,
        //flota
        //behavior: SnackBarBehavior.floating,
        //elevation: 4,
        //

        //shape: RoundedRectangleBorder(
          //borderRadius: BorderRadius.circular(12), //flota
          //side: BorderSide(color: borderColor, width: 1),
          //side: BorderSide(color: borderColor, width: 1),
        //),

        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}