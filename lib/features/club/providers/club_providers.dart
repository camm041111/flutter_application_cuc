import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/cache/app_cache_service.dart';
import '../../../core/providers/supabase_provider.dart';

class ClubIdentity {
  const ClubIdentity({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.urlLogo,
    required this.acronimoDivision,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final String? urlLogo;
  final String acronimoDivision;

  factory ClubIdentity.fromJson(Map<String, dynamic> json) {
    final division = json['divisiones_academicas'];
    final divisionData =
        division is Map ? Map<String, dynamic>.from(division) : null;
    final rawLogo = json['url_logo']?.toString().trim();

    return ClubIdentity(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? 'Club sin nombre').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      urlLogo: rawLogo == null || rawLogo.isEmpty ? null : rawLogo,
      acronimoDivision: (divisionData?['acronimo'] ?? 'Desconocida').toString(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'url_logo': urlLogo,
      'divisiones_academicas': {'acronimo': acronimoDivision},
    };
  }
}

class ClubMember {
  const ClubMember({
    required this.id,
    required this.nombreCompleto,
    required this.urlAvatar,
    required this.rol,
    required this.estado,
  });

  final String id;
  final String nombreCompleto;
  final String? urlAvatar;
  final String rol;
  final String estado;

  factory ClubMember.fromJson(Map<String, dynamic> json) {
    final rawAvatar = json['url_avatar']?.toString().trim();
    return ClubMember(
      id: (json['id'] ?? '').toString(),
      nombreCompleto:
          (json['nombre_completo'] ?? 'Usuario sin nombre').toString(),
      urlAvatar: rawAvatar == null || rawAvatar.isEmpty ? null : rawAvatar,
      rol: (json['rol'] ?? '').toString(),
      estado: (json['estado'] ?? '').toString(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'nombre_completo': nombreCompleto,
      'url_avatar': urlAvatar,
      'rol': rol,
      'estado': estado,
    };
  }
}

// 1. Provider del Heatmap Colectivo (Llamada al nuevo RPC)
final clubHeatmapProvider =
    FutureProvider.family<Map<DateTime, int>, String>((ref, clubId) async {
  final supabase = ref.read(supabaseClientProvider);
  late final List<dynamic> response;
  try {
    response = await supabase.rpc(
      'obtener_heatmap_colectivo',
      params: {'p_id_club': clubId},
    );
  } on PostgrestException catch (e) {
    if (e.code != 'PGRST202' && e.code != '42883') rethrow;
    response = await supabase
        .from('logs_actividad')
        .select('fecha_creacion, perfiles!inner(id_club)')
        .eq('perfiles.id_club', clubId)
        .gte(
          'fecha_creacion',
          DateTime.now()
              .subtract(const Duration(days: 13 * 7))
              .toIso8601String(),
        );
    return _heatmapFromActivityLogs(response);
  }

  final Map<DateTime, int> heatmapData = {};
  for (var row in response) {
    final date = DateTime.parse(row['fecha'].toString());
    heatmapData[DateTime(date.year, date.month, date.day)] =
        int.parse(row['nivel'].toString());
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

// 2. Provider del Directorio (Trae solo la información esencial)
// Retorna un Record con dos listas: activos e inactivos/bajas
final clubDirectoryProvider = FutureProvider.family<
    ({List<ClubMember> activos, List<ClubMember> historico}),
    String>((ref, clubId) async {
  final cache = ref.read(appCacheServiceProvider);
  final supabase = ref.read(supabaseClientProvider);

  return cache.staleWhileRevalidate<
      ({List<ClubMember> activos, List<ClubMember> historico})>(
    ref: ref,
    key: 'club:$clubId:directory',
    ttl: CacheTtl.club,
    fetch: () async {
      // Optimizamos el payload solicitando SOLO las columnas que la UI necesita renderizar
      final response = await supabase
          .from('perfiles')
          .select('id, nombre_completo, url_avatar, rol, estado')
          .eq('id_club', clubId)
          // Excluimos a los 'registrados' porque aún no son miembros oficiales
          .neq('estado', 'registrado')
          .order('rol', ascending: true); // Coordinadores primero

      final members = response
          .map(
            (item) => ClubMember.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false);
      final activos =
          members.where((member) => member.estado == 'activo').toList();
      final historico =
          members.where((member) => member.estado != 'activo').toList();

      return (activos: activos, historico: historico);
    },
    fromJson: _directoryFromJson,
    toJson: _directoryToJson,
  );
});

// 3. Provider de la Identidad del Club
final clubIdentityProvider =
    FutureProvider.family<ClubIdentity, String>((ref, clubId) async {
  final cache = ref.read(appCacheServiceProvider);
  final supabase = ref.read(supabaseClientProvider);

  return cache.staleWhileRevalidate<ClubIdentity>(
    ref: ref,
    key: 'club:$clubId:identity',
    ttl: CacheTtl.club,
    fetch: () async {
      // 🚀 JOIN para traer los datos del club Y el acrónimo de su división
      final response = await supabase
          .from('clubes')
          .select('*, divisiones_academicas(acronimo)')
          .eq('id', clubId)
          .single();

      return ClubIdentity.fromJson(response);
    },
    fromJson: (json) =>
        ClubIdentity.fromJson(Map<String, dynamic>.from(json as Map)),
    toJson: (value) => value.toJson(),
  );
});

// 4. Provider de Métricas de Repositorio (Conteo exacto en servidor)
final clubDocsCountProvider =
    FutureProvider.family<int, String>((ref, clubId) async {
  final cache = ref.read(appCacheServiceProvider);
  final supabase = ref.read(supabaseClientProvider);

  return cache.staleWhileRevalidate<int>(
    ref: ref,
    key: 'club:$clubId:docs_count',
    ttl: CacheTtl.repository,
    fetch: () async {
      // 🛡️ Seguridad y Rendimiento:
      // 1. Usamos count() para que PostgreSQL solo devuelva un número (int), no el JSON completo.
      // 2. Filtramos estrictamente por estado 'aprobado' para respetar el flujo de curaduría.
      final count = await supabase
          .from('publicaciones_repositorio')
          .count()
          .eq('id_club', clubId)
          .eq('estado', 'aprobado');

      return count;
    },
    fromJson: (json) => json as int,
    toJson: (value) => value,
  );
});

({List<ClubMember> activos, List<ClubMember> historico}) _directoryFromJson(
  Object? json,
) {
  final map = Map<String, dynamic>.from(json as Map);
  return (
    activos: (map['activos'] as List<dynamic>)
        .map(
          (item) => ClubMember.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(),
    historico: (map['historico'] as List<dynamic>)
        .map(
          (item) => ClubMember.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(),
  );
}

Map<String, Object?> _directoryToJson(
  ({List<ClubMember> activos, List<ClubMember> historico}) value,
) {
  return {
    'activos': value.activos.map((member) => member.toJson()).toList(),
    'historico': value.historico.map((member) => member.toJson()).toList(),
  };
}
