import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/cache/app_cache_service.dart';
import '../../../core/providers/supabase_provider.dart';

// 1. Actualizamos el Modelo
class UserProfile {
  final String id;
  final String nombreCompleto;
  final String matricula;
  final String? urlAvatar;
  final String rol;
  final String estado;
  final String divisionAcronimo;

  // 🛡️ NUEVOS CAMPOS: Pueden ser nulos si el usuario apenas se registró y no tiene club asignado
  final String? clubId;
  final String? clubNombre;

  UserProfile({
    required this.id,
    required this.nombreCompleto,
    required this.matricula,
    this.urlAvatar,
    required this.rol,
    required this.estado,
    required this.divisionAcronimo,
    this.clubId,
    this.clubNombre,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // 🛡️ Manejo seguro de nulos (Null-Safety) por si el JOIN de clubes viene vacío
    final clubData = json['clubes'];

    return UserProfile(
      id: json['id'],
      nombreCompleto: json['nombre_completo'],
      matricula: json['matricula'],
      urlAvatar: json['url_avatar'],
      rol: json['rol'],
      estado: json['estado'],
      divisionAcronimo: json['divisiones_academicas']['acronimo'],
      clubId: clubData?['id'],
      clubNombre: clubData?['nombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre_completo': nombreCompleto,
      'matricula': matricula,
      'url_avatar': urlAvatar,
      'rol': rol,
      'estado': estado,
      'divisiones_academicas': {'acronimo': divisionAcronimo},
      'clubes': clubId == null && clubNombre == null
          ? null
          : {
              'id': clubId,
              'nombre': clubNombre,
            },
    };
  }
}

// 2. Actualizamos el Provider
final profileProvider = FutureProvider.family<UserProfile, String>((ref, userId) async {
  final cache = ref.read(appCacheServiceProvider);
  final supabase = ref.read(supabaseClientProvider);

  return cache.staleWhileRevalidate<UserProfile>(
    ref: ref,
    key: 'profile:$userId',
    ttl: CacheTtl.profile,
    fetch: () async {
      // 🚀 El JOIN Maestro: Traemos la división origen Y los datos del club asignado
      final response = await supabase
          .from('perfiles')
          .select('*, divisiones_academicas(acronimo), clubes(id, nombre)')
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    },
    fromJson: (json) => UserProfile.fromJson(Map<String, dynamic>.from(json as Map)),
    toJson: (profile) => profile.toJson(),
    persistent: false,
  );
});

// 3. Provider del Heatmap (Consume el RPC)
final heatmapProvider = FutureProvider.family<Map<DateTime, int>, String>((ref, userId) async {
  final supabase = ref.read(supabaseClientProvider);

  late final List<dynamic> response;
  try {
    response = await supabase.rpc(
      'obtener_datos_heatmap',
      params: {'p_id_usuario': userId},
    );
  } on PostgrestException catch (e) {
    if (e.code != 'PGRST202' && e.code != '42883') rethrow;
    response = await supabase
        .from('logs_actividad')
        .select('fecha_creacion')
        .eq('id_usuario', userId)
        .gte(
          'fecha_creacion',
          DateTime.now()
              .subtract(const Duration(days: 26 * 7))
              .toIso8601String(),
        );
    return _heatmapFromActivityLogs(response);
  }

  final Map<DateTime, int> heatmapData = {};

  for (var row in response) {
    final date = DateTime.parse(row['fecha'].toString());
    final level = int.parse(row['nivel'].toString());

    // Normalizamos la fecha a medianoche para evitar desajustes en el widget visual
    heatmapData[DateTime(date.year, date.month, date.day)] = level;
  }

  return heatmapData;
});

Map<DateTime, int> _heatmapFromActivityLogs(List<dynamic> rows) {
  final heatmapData = <DateTime, int>{};
  for (final row in rows) {
    final value = (row as Map)['fecha_creacion'];
    final date = DateTime.tryParse((value ?? '').toString());
    if (date == null) continue;
    final key = DateTime(date.year, date.month, date.day);
    final next = (heatmapData[key] ?? 0) + 1;
    heatmapData[key] = next > 4 ? 4 : next;
  }
  return heatmapData;
}

// 4. Provider de Métricas (Lazy Load: Solo carga si el recuadro es visible/requerido)
// Usamos un Record ({int publicaciones, int foro}) para tipar el retorno.
final statsProvider = FutureProvider.family<({int publicaciones, int foro}), String>((ref, userId) async {
  final supabase = ref.read(supabaseClientProvider);

  // Rendimiento: Ejecutamos las consultas en paralelo con Future.wait
  // Solo seleccionamos la columna 'id' para que el payload HTTP sea minúsculo
  final results = await Future.wait([
    supabase
        .from('publicaciones_repositorio')
        .select('id')
        .eq('id_autor', userId)
        .eq('estado', 'aprobado'), // Solo contamos documentos oficiales

    supabase
        .from('preguntas_foro')
        .select('id')
        .eq('id_autor', userId),
  ]);

  return (
  publicaciones: results[0].length,
  foro: results[1].length,
  );
});

// 5. Provider de Publicaciones Recientes (Top 3)
final recentPostsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final supabase = ref.read(supabaseClientProvider);

  // Rendimiento: Traemos estrictamente los campos que la UI necesita renderizar
  return await supabase
      .from('publicaciones_repositorio')
      .select('id, titulo, categoria')
      .eq('id_autor', userId)
      .eq('estado', 'aprobado')
      .order('fecha_creacion', ascending: false)
      .limit(3); // Candado de seguridad para no desbordar la UI
});
