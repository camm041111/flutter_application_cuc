import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Provider que trae todas las Divisiones Académicas
final divisionesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  // Traemos el ID, acrónimo y nombre, ordenados alfabéticamente
  final data = await supabase
      .from('divisiones_academicas')
      .select('id, acronimo, nombre')
      .order('acronimo', ascending: true);
  return data;
});

// 2. Provider que trae los Clubes, ¡pero filtrados por la división elegida!
// Usamos .family para poder pasarle el ID de la división como parámetro.
final clubesPorDivisionProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, divisionId) async {
  if (divisionId == null || divisionId.isEmpty) return []; // Si no hay división, no hay clubes

  final supabase = Supabase.instance.client;
  final data = await supabase
      .from('clubes')
      .select('id, nombre')
      .eq('id_division', divisionId) // Filtro mágico de Supabase
      .order('nombre', ascending: true);
  return data;
});