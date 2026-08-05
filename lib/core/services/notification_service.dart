import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_providers.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.read,
    this.referenceId,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final bool read;
  final String? referenceId;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      title: (json['titulo'] ?? 'Notificacion').toString(),
      body: (json['cuerpo'] ?? '').toString(),
      type: (json['tipo'] ?? 'sistema').toString(),
      createdAt: DateTime.tryParse((json['fecha_creacion'] ?? '').toString()) ??
          DateTime.now(),
      read: json['leida'] == true,
      referenceId: json['id_referencia']?.toString(),
    );
  }
}

/// Bandeja de notificaciones en tiempo real.
/// Se mantiene actualizada con Realtime (INSERT/UPDATE/DELETE de la tabla
/// `notificaciones` filtrada por el usuario) y con un refresco periódico de
/// respaldo por si la conexión Realtime se cae.
final notificationsProvider = AsyncNotifierProvider.autoDispose<
    NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  RealtimeChannel? _channel;
  Timer? _backupTimer;

  @override
  Future<List<AppNotification>> build() async {
    _cleanup();

    ref.onDispose(() {
      _backupTimer?.cancel();
      if (_channel != null) {
        ref.read(supabaseClientProvider).removeChannel(_channel!);
      }
      _channel = null;
      _backupTimer = null;
    });

    // Se re-suscribe automáticamente cuando cambia el usuario (login/logout).
    final user = ref.watch(currentUserProvider);
    if (user == null) return const [];

    final supabase = ref.read(supabaseClientProvider);

    _channel = supabase
        .channel('notificaciones_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notificaciones',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id_usuario',
            value: user.id,
          ),
          callback: (_) => _reload(),
        )
        .subscribe();

    // Respaldo por si Realtime no está disponible (red inestable).
    _backupTimer =
        Timer.periodic(const Duration(minutes: 1), (_) => _reload());

    return _fetch();
  }

  Future<List<AppNotification>> _fetch() async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) return const [];

    final response = await supabase
        .from('notificaciones')
        .select('id, titulo, cuerpo, tipo, id_referencia, leida, fecha_creacion')
        .eq('id_usuario', user.id)
        .order('fecha_creacion', ascending: false)
        .limit(30);

    return (response as List<dynamic>)
        .map((row) =>
            AppNotification.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  /// Refresca la bandeja sin ponerla en estado de carga.
  Future<void> _reload() async {
    try {
      state = AsyncData(await _fetch());
    } catch (_) {
      // Conservamos los datos actuales si el refresco falla.
    }
  }

  /// Refresco público para usar tras mutaciones (marcar leída, eliminar...).
  Future<void> refresh() => _reload();

  void _cleanup() {
    _backupTimer?.cancel();
    _backupTimer = null;
    if (_channel != null) {
      ref.read(supabaseClientProvider).removeChannel(_channel!);
      _channel = null;
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

class NotificationService {
  NotificationService(this.ref);

  final Ref ref;

  Future<void> markAsRead(String notificationId) async {
    final supabase = ref.read(supabaseClientProvider);
    await supabase
        .from('notificaciones')
        .update({'leida': true}).eq('id', notificationId);
    await ref.read(notificationsProvider.notifier).refresh();
  }

  Future<void> markAllAsRead() async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('notificaciones')
        .update({'leida': true})
        .eq('id_usuario', user.id)
        .eq('leida', false);
    await ref.read(notificationsProvider.notifier).refresh();
  }

  Future<void> deleteNotification(String notificationId) async {
    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('notificaciones').delete().eq('id', notificationId);
    await ref.read(notificationsProvider.notifier).refresh();
  }
}
