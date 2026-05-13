import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';

class ClubEvent {
  const ClubEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startsAt,
    required this.endsAt,
    required this.clubId,
    required this.clubName,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startsAt;
  final DateTime endsAt;
  final String clubId;
  final String clubName;
  final String? imageUrl;

  factory ClubEvent.fromJson(Map<String, dynamic> json) {
    final club = json['clubes'] as Map<String, dynamic>?;

    return ClubEvent(
      id: json['id'].toString(),
      title: (json['titulo'] ?? 'Evento sin título').toString(),
      description: (json['descripcion'] ?? '').toString(),
      location: (json['ubicacion'] ?? 'Ubicación por confirmar').toString(),
      startsAt: _parseDateTime(json, 'hora_inicio'),
      endsAt: _parseDateTime(json, 'hora_fin'),
      clubId: (json['id_club'] ?? '').toString(),
      clubName: (club?['nombre'] ?? 'CUC').toString(),
      imageUrl: json['imagen_url']?.toString(),
    );
  }

  static DateTime _parseDateTime(Map<String, dynamic> json, String timeKey) {
    final fecha = (json['fecha'] ?? '').toString();
    final time = (json[timeKey] ?? '00:00:00').toString();
    return DateTime.tryParse('${fecha}T$time') ?? DateTime.now();
  }
}

class EventInput {
  const EventInput({
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  final String title;
  final String description;
  final String location;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
}

final showFutureEventsProvider =
    NotifierProvider<ShowFutureEventsNotifier, bool>(
        ShowFutureEventsNotifier.new);

class ShowFutureEventsNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setShowFuture(bool value) {
    state = value;
  }
}

final eventsProvider = FutureProvider.autoDispose<List<ClubEvent>>((ref) async {
  final showFuture = ref.watch(showFutureEventsProvider);
  final supabase = ref.read(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final profile = await supabase
      .from('perfiles')
      .select('id_club')
      .eq('id', user.id)
      .single();
  final clubId = (profile['id_club'] ?? '').toString();
  if (clubId.isEmpty) return [];

  final today = DateTime.now().toIso8601String().split('T').first;

  dynamic query = supabase.from('eventos_agenda').select(
      'id, id_club, titulo, descripcion, ubicacion, fecha, hora_inicio, hora_fin, clubes(nombre)')
      .eq('id_club', clubId);

  query = showFuture
      ? query.gte('fecha', today).order('fecha', ascending: true)
      : query.lt('fecha', today).order('fecha', ascending: false);

  final response = await query;
  return (response as List<dynamic>)
      .map((item) => ClubEvent.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
});

final canManageEventsProvider = FutureProvider.autoDispose<bool>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return false;

  final profile = await supabase
      .from('perfiles')
      .select('rol, estado, id_club')
      .eq('id', user.id)
      .single();

  final role = (profile['rol'] ?? '').toString();
  final status = (profile['estado'] ?? '').toString();
  final clubId = (profile['id_club'] ?? '').toString();
  return status == 'activo' &&
      clubId.isNotEmpty &&
      (role == 'coordinador' || role == 'lider');
});

final canManageEventProvider =
    FutureProvider.autoDispose.family<bool, ClubEvent>((ref, event) async {
  final supabase = ref.read(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return false;

  final profile = await supabase
      .from('perfiles')
      .select('rol, estado, id_club')
      .eq('id', user.id)
      .single();

  final role = (profile['rol'] ?? '').toString();
  final status = (profile['estado'] ?? '').toString();
  return status == 'activo' &&
      event.clubId == (profile['id_club'] ?? '').toString() &&
      (role == 'coordinador' || role == 'lider');
});

final eventActionsProvider = Provider<EventActions>((ref) {
  return EventActions(ref);
});

class EventActions {
  EventActions(this.ref);

  final Ref ref;

  Future<void> createEvent(EventInput input) async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Debes iniciar sesión para crear eventos.');
    }

    final profile = await supabase
        .from('perfiles')
        .select('id_club, rol, estado')
        .eq('id', user.id)
        .single();

    final role = (profile['rol'] ?? '').toString();
    final status = (profile['estado'] ?? '').toString();
    final clubId = profile['id_club'];
    if (status != 'activo' ||
        clubId == null ||
        (role != 'coordinador' && role != 'lider')) {
      throw Exception('No tienes permisos para crear eventos.');
    }

    await supabase.from('eventos_agenda').insert({
      'id_club': clubId,
      'titulo': input.title.trim(),
      'descripcion': input.description.trim(),
      'fecha': _dateString(input.date),
      'hora_inicio': _timeString(input.startTime),
      'hora_fin': _timeString(input.endTime),
      'ubicacion': input.location.trim(),
    });

    ref.invalidate(eventsProvider);
  }

  Future<void> updateEvent(ClubEvent event, EventInput input) async {
    await _assertCanManage(event.clubId);

    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('eventos_agenda').update({
      'titulo': input.title.trim(),
      'descripcion': input.description.trim(),
      'fecha': _dateString(input.date),
      'hora_inicio': _timeString(input.startTime),
      'hora_fin': _timeString(input.endTime),
      'ubicacion': input.location.trim(),
    }).eq('id', event.id);

    ref.invalidate(eventsProvider);
  }

  Future<void> deleteEvent(ClubEvent event) async {
    await _assertCanManage(event.clubId);

    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('eventos_agenda').delete().eq('id', event.id);
    ref.invalidate(eventsProvider);
  }

  Future<void> _assertCanManage(String eventClubId) async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Debes iniciar sesión para gestionar eventos.');
    }

    final profile = await supabase
        .from('perfiles')
        .select('id_club, rol, estado')
        .eq('id', user.id)
        .single();

    final role = (profile['rol'] ?? '').toString();
    final status = (profile['estado'] ?? '').toString();
    if (status != 'activo' ||
        eventClubId != (profile['id_club'] ?? '').toString() ||
        (role != 'coordinador' && role != 'lider')) {
      throw Exception('No tienes permisos para gestionar este evento.');
    }
  }

  static String _dateString(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static String _timeString(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }
}
