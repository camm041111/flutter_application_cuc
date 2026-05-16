import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/events_providers.dart';

void showEventDetails(BuildContext context, ClubEvent event) {
  // Función interna para formatear el objeto DateTime nativo a 12 horas (AM/PM)
  String formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $amPm';
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              event.clubName,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            const Divider(color: AppColors.border, height: 30),

            // Horario unificado con formato de 12 horas (Inicio - Fin)
            Row(
              children: [
                const Icon(Icons.schedule, color: AppColors.muted, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Horario: ${formatTime(event.startsAt)} - ${formatTime(event.endsAt)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.muted, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.location,
                    style: const TextStyle(color: AppColors.muted, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'Descripción',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 14),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            )
          ],
        ),
      ),
    ),
  );
}