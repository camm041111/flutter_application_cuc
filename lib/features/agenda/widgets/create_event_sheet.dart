import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importante para el HapticFeedback
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/correct_snackbar.dart';
import '../providers/events_providers.dart';

class CreateEventSheet extends ConsumerStatefulWidget {
  const CreateEventSheet({super.key, this.event});

  final ClubEvent? event;

  @override
  ConsumerState<CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends ConsumerState<CreateEventSheet> {
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);

  bool _saving = false;
  String? _inlineError;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    if (event == null) return;

    _titleCtrl.text = event.title;
    _descriptionCtrl.text = event.description;
    _locationCtrl.text = event.location;
    _date = DateTime(event.startsAt.year, event.startsAt.month, event.startsAt.day);
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

  Theme _pickerTheme(Widget? child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          onPrimary: AppColors.background,
          surface: AppColors.surface,
          onSurface: Colors.white,
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: AppColors.surface,
          dialBackgroundColor: AppColors.background,
          dayPeriodColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primary;
            return AppColors.background;
          }),
          dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.background;
            return AppColors.muted;
          }),
          dayPeriodShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.surface),
          ),
          dayPeriodBorderSide: const BorderSide(color: AppColors.surface),
        ),
        dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
      ),
      child: child!,
    );
  }

  Future<void> _pickDate() async {
    if (_saving) return;
    await HapticFeedback.lightImpact();

    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('es', 'MX'),
      builder: (context, child) => _pickerTheme(child),
    );
    if (value != null) {
      setState(() {
        _date = value;
        _inlineError = null;
      });
    }
  }

  Future<void> _pickTime({required bool start}) async {
    if (_saving) return;
    await HapticFeedback.lightImpact();

    final value = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('es', 'US'),
          child: _pickerTheme(child),
        );
      },
    );
    if (value == null) return;
    setState(() {
      if (start) _start = value; else _end = value;
      _inlineError = null;
    });
  }

  Future<void> _submit() async {
    setState(() => _inlineError = null);
    if (!_formKey.currentState!.validate()) return;

    final startDateTime = DateTime(_date.year, _date.month, _date.day, _start.hour, _start.minute);
    final endDateTime = DateTime(_date.year, _date.month, _date.day, _end.hour, _end.minute);

    if (!endDateTime.isAfter(startDateTime)) {
      setState(() => _inlineError = 'La hora de fin debe ser posterior a la de inicio.');
      return;
    }
    if (!_isEditing && startDateTime.isBefore(DateTime.now())) {
      setState(() => _inlineError = 'No puedes agendar eventos en el pasado.');
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
      //aqui ta el snackbar
      CucSnackBar.show(
        context,
        icon: Icons.check_circle_outline,
        iconColor: AppColors.primary,
        //borderColor: AppColors.fondo,
        message: _isEditing ? 'Evento guardado correctamente.' : 'Evento creado con éxito.',
      );

    } catch (e) {
      final cleanError = e.toString().replaceAll('Exception: ', '');
      setState(() => _inlineError = cleanError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: AppColors.muted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  _isEditing ? 'EDITAR EVENTO' : 'NUEVO EVENTO',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),

                _buildFieldLabel('Título del evento'),
                TextFormField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Ej. Sesión de Robótica'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa un título' : null,
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('Descripción'),
                TextFormField(
                  controller: _descriptionCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Detalles del evento...'),
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 500,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa una descripción' : null,
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('Ubicación'),
                TextFormField(
                  controller: _locationCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Ej. Edificio Y'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa una ubicación' : null,
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('Fecha del evento'),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_today, size: 20),
                      suffixIcon: Icon(Icons.arrow_drop_down, color: AppColors.muted),
                    ),
                    child: Text(
                      _formatDate(_date),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _buildFieldLabel('Horario'),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickTime(start: true),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.schedule, size: 20),
                            suffixIcon: Icon(Icons.arrow_drop_down, color: AppColors.muted, size: 20),
                          ),
                          child: Text(
                            'Inicio: ${_formatTimeOfDay(_start)}', // Cambiado a formateador de 12 horas
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickTime(start: false),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.schedule, size: 20),
                            suffixIcon: Icon(Icons.arrow_drop_down, color: AppColors.muted, size: 20),
                          ),
                          child: Text(
                            'Fin: ${_formatTimeOfDay(_end)}', // Cambiado a formateador de 12 horas
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_inlineError != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _inlineError!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(_isEditing ? Icons.save_outlined : Icons.check_circle_outline),
                    label: Text(_isEditing ? 'GUARDAR' : 'CREAR EVENTO'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Nueva función para formatear la visualización del recuadro a 12 horas
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $amPm';
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}