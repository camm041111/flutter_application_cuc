import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/supabase_provider.dart';

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
      createdAt: DateTime.tryParse((json['fecha_creacion'] ?? '').toString()) ?? DateTime.now(),
      read: json['leida'] == true,
      referenceId: json['id_referencia']?.toString(),
    );
  }
}

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final response = await supabase
      .from('notificaciones')
      .select('id, titulo, cuerpo, tipo, id_referencia, leida, fecha_creacion')
      .eq('id_usuario', user.id)
      .order('fecha_creacion', ascending: false)
      .limit(30);

  return (response as List<dynamic>)
      .map((row) => AppNotification.fromJson(Map<String, dynamic>.from(row as Map)))
      .toList();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

class NotificationService {
  NotificationService(this.ref);

  final Ref ref;

  Future<void> markAsRead(String notificationId) async {
    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('notificaciones').update({'leida': true}).eq('id', notificationId);
    ref.invalidate(notificationsProvider);
  }

  Future<void> deleteNotification(String notificationId) async {
    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('notificaciones').delete().eq('id', notificationId);
    ref.invalidate(notificationsProvider);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('preferencias_notificacion')
        .upsert({'id_usuario': user.id, 'push_habilitado': enabled});
  }

  Future<void> registerPushToken(String token, {String platform = 'unknown'}) async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null || token.trim().isEmpty) return;

    await supabase.from('tokens_push').upsert({
      'id_usuario': user.id,
      'token': token.trim(),
      'plataforma': platform,
      'activo': true,
      'actualizado_el': DateTime.now().toIso8601String(),
    }, onConflict: 'token');
  }
}
