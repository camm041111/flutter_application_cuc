import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/cuc_app_bar.dart';
import 'providers/events_providers.dart';

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});

  void _openCreateEventSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateEventSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showFuture = ref.watch(showFutureEventsProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final canManageAsync = ref.watch(canManageEventsProvider);

    return Scaffold(
      appBar: const CucAppBar(),
      body: Column(
        children: [
          _FilterTabs(
            showFuture: showFuture,
            onChanged: (value) => ref
                .read(showFutureEventsProvider.notifier)
                .setShowFuture(value),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(eventsProvider),
              child: eventsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, s) => _AgendaEmptyState(
                  title: 'No se pudieron cargar los eventos',
                  subtitle: '$e',
                ),
                data: (events) => _EventsList(
                  events: events,
                  showFuture: showFuture,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: canManageAsync.maybeWhen(
        data: (canManage) => canManage
            ? FloatingActionButton(
                onPressed: () => _openCreateEventSheet(context),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                child: const Icon(Icons.add),
              )
            : null,
        orElse: () => null,
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.showFuture, required this.onChanged});

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18, color: active ? AppColors.primary : AppColors.muted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.primary : AppColors.muted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventsList extends StatelessWidget {
  const _EventsList({
    required this.events,
    required this.showFuture,
  });

  final List<ClubEvent> events;
  final bool showFuture;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _AgendaEmptyState(
        title: showFuture ? 'Sin próximos eventos' : 'Sin eventos pasados',
        subtitle: 'Cuando haya registros en la base de datos aparecerán aquí.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          showFuture ? 'Próximos Eventos' : 'Eventos Pasados',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...events.map(
          (event) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SmallEventCard(event: event, past: !showFuture),
          ),
        ),
      ],
    );
  }
}

class _SmallEventCard extends ConsumerStatefulWidget {
  const _SmallEventCard({
    required this.event,
    this.past = false,
  });

  final ClubEvent event;
  final bool past;

  @override
  ConsumerState<_SmallEventCard> createState() => _SmallEventCardState();
}

class _SmallEventCardState extends ConsumerState<_SmallEventCard> {
  bool _deleting = false;

  void _openEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateEventSheet(event: widget.event),
    );
  }

  Future<void> _deleteEvent() async {
    if (_deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: Text('¿Quieres eliminar "${widget.event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento eliminado.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el evento: $e')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final past = widget.past;
    final canManageAsync = ref.watch(canManageEventProvider(event));

    return Opacity(
      opacity: past ? 0.58 : 1.0,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: past
                      ? AppColors.surface
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_month(event.startsAt),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: past ? AppColors.muted : AppColors.primary)),
                    Text(event.startsAt.day.toString().padLeft(2, '0'),
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: past ? AppColors.muted : AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis),
                    Text(event.clubName,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 12,
                            color: past ? AppColors.muted : AppColors.primary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            event.location,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color:
                                    past ? AppColors.muted : AppColors.primary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: past ? AppColors.muted : AppColors.primary),
              canManageAsync.maybeWhen(
                data: (canManage) => canManage
                    ? PopupMenuButton<String>(
                        tooltip: 'Acciones del evento',
                        icon: _deleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'edit') _openEditSheet();
                          if (value == 'delete') _deleteEvent();
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Editar'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete_outline),
                              title: Text('Eliminar'),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaEmptyState extends StatelessWidget {
  const _AgendaEmptyState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Icon(Icons.event_busy, color: AppColors.muted, size: 36),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreateEventSheet extends ConsumerStatefulWidget {
  const _CreateEventSheet({this.event});

  final ClubEvent? event;

  @override
  ConsumerState<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends ConsumerState<_CreateEventSheet> {
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);
  bool _saving = false;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    if (event == null) return;

    _titleCtrl.text = event.title;
    _descriptionCtrl.text = event.description;
    _locationCtrl.text = event.location;
    _date = DateTime(
      event.startsAt.year,
      event.startsAt.month,
      event.startsAt.day,
    );
    _start = TimeOfDay.fromDateTime(event.startsAt);
    _end = TimeOfDay.fromDateTime(event.endsAt);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (value != null) setState(() => _date = value);
  }

  Future<void> _pickTime({required bool start}) async {
    final value = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (value == null) return;
    setState(() {
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final startDateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _start.hour,
      _start.minute,
    );
    final endDateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _end.hour,
      _end.minute,
    );

    if (!endDateTime.isAfter(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La hora de fin debe ser posterior.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final input = EventInput(
        title: _titleCtrl.text,
        description: _descriptionCtrl.text,
        location: _locationCtrl.text,
        date: _date,
        startTime: startDateTime,
        endTime: endDateTime,
      );
      final actions = ref.read(eventActionsProvider);
      if (_isEditing) {
        await actions.updateEvent(widget.event!, input);
      } else {
        await actions.createEvent(input);
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Evento actualizado.' : 'Evento creado.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'No se pudo actualizar el evento: $e'
                : 'No se pudo crear el evento: $e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Editar evento' : 'Crear evento',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(hintText: 'Título'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Ingresa un título'
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(hintText: 'Descripción'),
                  minLines: 2,
                  maxLines: 4,
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Ingresa una descripción'
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(hintText: 'Ubicación'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Ingresa una ubicación'
                          : null,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_formatDate(_date)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            _saving ? null : () => _pickTime(start: true),
                        icon: const Icon(Icons.schedule, size: 16),
                        label: Text('Inicio ${_start.format(context)}'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            _saving ? null : () => _pickTime(start: false),
                        icon: const Icon(Icons.schedule, size: 16),
                        label: Text('Fin ${_end.format(context)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_isEditing ? Icons.save_outlined : Icons.add),
                    label: Text(
                      _isEditing ? 'GUARDAR CAMBIOS' : 'CREAR EVENTO',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _month(DateTime date) {
  const months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic'
  ];
  return months[date.month - 1];
}
