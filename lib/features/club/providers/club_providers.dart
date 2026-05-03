import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';

// 1. Provider del Heatmap Colectivo (Llamada al nuevo RPC)
final clubHeatmapProvider = FutureProvider.family<Map<DateTime, int>, String>((ref, clubId) async {
  final supabase = ref.read(supabaseClientProvider);
  final response = await supabase.rpc('obtener_heatmap_colectivo', params: {'p_id_club': clubId});

  final Map<DateTime, int> heatmapData = {};
  for (var row in response) {
    final date = DateTime.parse(row['fecha'].toString());
    heatmapData[DateTime(date.year, date.month, date.day)] = int.parse(row['nivel'].toString());
  }
  return heatmapData;
});

// 2. Provider del Directorio (Trae solo la información esencial)
// Retorna un Record con dos listas: activos e inactivos/bajas
final clubDirectoryProvider = FutureProvider.family<({List<dynamic> activos, List<dynamic> historico}), String>((ref, clubId) async {
  final supabase = ref.read(supabaseClientProvider);

  // Optimizamos el payload solicitando SOLO las columnas que la UI necesita renderizar
  final response = await supabase
      .from('perfiles')
      .select('id, nombre_completo, url_avatar, rol, estado')
      .eq('id_club', clubId)
  // Excluimos a los 'registrados' porque aún no son miembros oficiales
      .neq('estado', 'registrado')
      .order('rol', ascending: true); // Coordinadores primero

  final activos = response.where((user) => user['estado'] == 'activo').toList();
  final historico = response.where((user) => user['estado'] != 'activo').toList();

  return (activos: activos, historico: historico);
});

// 3. Provider de la Identidad del Club
final clubIdentityProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, clubId) async {
  final supabase = ref.read(supabaseClientProvider);

  // 🚀 JOIN para traer los datos del club Y el acrónimo de su división
  final response = await supabase
      .from('clubes')
      .select('*, divisiones_academicas(acronimo)')
      .eq('id', clubId)
      .single();

  return response;
});

// 4. Provider de Métricas de Repositorio (Conteo exacto en servidor)
final clubDocsCountProvider = FutureProvider.family<int, String>((ref, clubId) async {
  final supabase = ref.read(supabaseClientProvider);

  // 🛡️ Seguridad y Rendimiento:
  // 1. Usamos count() para que PostgreSQL solo devuelva un número (int), no el JSON completo.
  // 2. Filtramos estrictamente por estado 'aprobado' para respetar el flujo de curaduría.
  final count = await supabase
      .from('publicaciones_repositorio')
      .count()
      .eq('id_club', clubId)
      .eq('estado', 'aprobado');

  return count;
});