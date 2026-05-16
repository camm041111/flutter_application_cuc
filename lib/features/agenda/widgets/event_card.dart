import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/events_providers.dart';
import 'create_event_sheet.dart';
import 'event_details_sheet.dart';

class EventCard extends ConsumerStatefulWidget {
  const EventCard({super.key, required this.event, this.past = false});

  final ClubEvent event;
  final bool past;

  @override
  ConsumerState<EventCard> createState() => _EventCardState();
}

class _EventCardState extends ConsumerState<EventCard> {
  bool _deleting = false;

  void _openEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateEventSheet(event: widget.event),
    );
  }

  Future<void> _deleteEvent() async {
    if (_deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Eliminar evento'),
        content: Text('¿Quieres eliminar "${widget.event.title}" de la agenda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.muted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade800),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await ref.read(eventActionsProvider).deleteEvent(widget.event);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  // Función corregida para mostrar formato de 12 horas (AM/PM) en las tarjetas pequeñas
  String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final past = widget.past;
    final canManageAsync = ref.watch(canManageEventProvider(event));

    return Card(
      elevation: past ? 0 : 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: past ? const BorderSide(color: AppColors.border, width: 1) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => showEventDetails(context, event),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: past ? AppColors.surface : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_month(event.startsAt), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: past ? AppColors.muted : AppColors.primary)),
                    Text(event.startsAt.day.toString().padLeft(2, '0'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: past ? AppColors.muted : AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${_formatTime(event.startsAt)} • ${event.clubName}', style: const TextStyle(fontSize: 11, color: AppColors.muted), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: past ? AppColors.muted : AppColors.primary),
                        const SizedBox(width: 3),
                        Expanded(child: Text(event.location, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: past ? AppColors.muted : AppColors.primary), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
              canManageAsync.maybeWhen(
                data: (canManage) => canManage && !past
                    ? PopupMenuButton<String>(
                  icon: _deleting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') _openEditSheet();
                    if (value == 'delete') _deleteEvent();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar'))),
                    PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Eliminar', style: TextStyle(color: Colors.red)))),
                  ],
                )
                    : const Icon(Icons.chevron_right, color: AppColors.muted),
                orElse: () => const Icon(Icons.chevron_right, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _month(DateTime date) {
  const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
  return months[date.month - 1];
}