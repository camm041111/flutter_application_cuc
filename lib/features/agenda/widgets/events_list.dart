import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/events_providers.dart';
import 'agenda_empty_state.dart';
import 'event_card.dart';
import 'create_event_sheet.dart';
import 'event_details_sheet.dart'; // Importación requerida

class EventsList extends StatelessWidget {
  const EventsList({
    super.key,
    required this.events,
    required this.showFuture,
  });

  final List<ClubEvent> events;
  final bool showFuture;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return AgendaEmptyState(
        title: showFuture ? 'Sin próximos eventos' : 'Sin eventos pasados',
        subtitle: 'Cuando haya registros en la base de datos aparecerán aquí.',
      );
    }

    final hasFeatured = showFuture && events.isNotEmpty;
    final featuredEvent = hasFeatured ? events.first : null;
    final listEvents = hasFeatured ? events.skip(1).toList() : events;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (hasFeatured) ...[
          const Text('Próximo evento...',
              style: TextStyle(fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          const SizedBox(height: 12),
          _FeaturedEventCard(event: featuredEvent!),
          const SizedBox(height: 24),
        ],
        Text(
          showFuture && listEvents.isNotEmpty ? 'Siguientes Eventos...' : (!showFuture ? 'Eventos Pasados' : ''),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        if (listEvents.isNotEmpty) const SizedBox(height: 12),
        ...listEvents.map(
              (event) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: EventCard(event: event, past: !showFuture),
          ),
        ),
      ],
    );
  }
}

class _FeaturedEventCard extends ConsumerStatefulWidget {
  const _FeaturedEventCard({required this.event});
  final ClubEvent event;

  @override
  ConsumerState<_FeaturedEventCard> createState() => _FeaturedEventCardState();
}

class _FeaturedEventCardState extends ConsumerState<_FeaturedEventCard> {
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: AppColors.muted))),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade800),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')
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
        SnackBar(backgroundColor: Colors.red.shade800, content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $amPm';
  }

  String _month(DateTime date) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return months[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final canManageAsync = ref.watch(canManageEventProvider(event));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                ),
                canManageAsync.maybeWhen(
                  data: (canManage) => canManage
                      ? PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: _deleting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.more_vert, color: AppColors.muted),
                    onSelected: (value) {
                      if (value == 'edit') _openEditSheet();
                      if (value == 'delete') _deleteEvent();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar'))),
                      PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Eliminar', style: TextStyle(color: Colors.red)))),
                    ],
                  )
                      : const SizedBox(width: 24),
                  orElse: () => const SizedBox(width: 24),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              event.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text('${event.startsAt.day.toString().padLeft(2, '0')} ${_month(event.startsAt)}, ${event.startsAt.year}',
                        style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(width: 20),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text(_formatTime(event.startsAt),
                        style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.location.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => showEventDetails(context, event),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'VER DETALLES',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}