import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cache/app_cache_service.dart';
import 'supabase_provider.dart';

// 1. Provider que trae todas las Divisiones Académicas
final divisionesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final cache = ref.read(appCacheServiceProvider);
  final supabase = ref.read(supabaseClientProvider);

  return cache.staleWhileRevalidate<List<Map<String, dynamic>>>(
    ref: ref,
    key: 'catalogs:divisiones',
    ttl: CacheTtl.catalogs,
    fetch: () async {
      final data = await supabase
          .from('divisiones_academicas')
          .select('id, acronimo, nombre')
          .order('acronimo', ascending: true);
      return _jsonList(data);
    },
    fromJson: (json) => _jsonList(json),
    toJson: (value) => value,
  );
});

// 2. Provider que trae los Clubes, ¡pero filtrados por la división elegida!
// Usamos .family para poder pasarle el ID de la división como parámetro.
final clubesPorDivisionProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, divisionId) async {
  if (divisionId == null || divisionId.isEmpty) return []; // Si no hay división, no hay clubes

  final cache = ref.read(appCacheServiceProvider);
  final supabase = ref.read(supabaseClientProvider);

  return cache.staleWhileRevalidate<List<Map<String, dynamic>>>(
    ref: ref,
    key: 'catalogs:clubes_por_division:$divisionId',
    ttl: CacheTtl.catalogs,
    fetch: () async {
      final data = await supabase
          .from('clubes')
          .select('id, nombre')
          .eq('id_division', divisionId) // Filtro mágico de Supabase
          .order('nombre', ascending: true);
      return _jsonList(data);
    },
    fromJson: (json) => _jsonList(json),
    toJson: (value) => value,
  );
});

List<Map<String, dynamic>> _jsonList(Object? value) {
  return (value as List<dynamic>)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();
}
