// lib/features/management/providers/coordinator_providers.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/cache/app_cache_service.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../club/providers/club_providers.dart';
import '../../repository/providers/repository_providers.dart';

// Provider que lista aspirantes en estado 'registrado'
final pendingMembersProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final user = supabase.auth.currentUser;

  final profile = await supabase
      .from('perfiles')
      .select('id_club')
      .eq('id', user!.id)
      .single();

  return await supabase
      .from('perfiles')
      .select('id, nombre_completo, matricula')
      .eq('id_club', profile['id_club'])
      .eq('estado', 'registrado');
});

final pendingDocumentsProvider =
    FutureProvider.autoDispose<List<RepositoryDocument>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final profile = await supabase
      .from('perfiles')
      .select('id_club')
      .eq('id', user.id)
      .single();

  final response = await supabase
      .from('publicaciones_repositorio')
      .select(
          'id, id_autor, id_club, titulo, descripcion, categoria, area_conocimiento, etiquetas, urls_archivos, estado, fecha_creacion, perfiles(nombre_completo), clubes(nombre)')
      .eq('id_club', profile['id_club'])
      .eq('estado', 'pendiente')
      .order('fecha_creacion', ascending: true);

  return (response as List<dynamic>)
      .map((item) =>
          RepositoryDocument.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
});

// 🛡️ PASO 2: Clase de Acciones con Blindaje de Excepciones
class CoordinatorActions {
  static Future<bool> approveMember(WidgetRef ref, String targetUserId) async {
    final supabase = ref.read(supabaseClientProvider);

    try {
      // Ejecutamos la actualización de estado a 'activo'
      await supabase
          .from('perfiles')
          .update({'estado': 'activo'}).eq('id', targetUserId);

      // Limpiamos la caché de los providers afectados para reflejar cambios en tiempo real
      final cache = ref.read(appCacheServiceProvider);
      await cache.invalidate('profile:$targetUserId');
      await cache.invalidatePrefix('club:');
      ref.invalidate(pendingMembersProvider);
      ref.invalidate(clubDirectoryProvider);

      return true;
    } on PostgrestException catch (e) {
      debugPrint('Error de base de datos: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error inesperado: $e');
      return false;
    }
  }

  static Future<bool> reviewDocument(
    WidgetRef ref,
    String documentId, {
    required bool approved,
  }) async {
    final supabase = ref.read(supabaseClientProvider);

    try {
      try {
        await supabase.rpc(
          'revisar_publicacion_repositorio',
          params: {
            'p_id_publicacion': documentId,
            'p_aprobada': approved,
          },
        );
      } on PostgrestException catch (e) {
        // Algunos entornos del proyecto aún no tienen el RPC instalado.
        // La actualización directa mantiene funcional el flujo de curaduría.
        if (e.code != 'PGRST202' && e.code != '42883') rethrow;
        await supabase.from('publicaciones_repositorio').update({
          'estado': approved ? 'aprobado' : 'rechazado',
        }).eq('id', documentId);
      }

      final cache = ref.read(appCacheServiceProvider);
      await cache.invalidatePrefix('repository:');
      await cache.invalidatePrefix('club:');
      ref.invalidate(pendingDocumentsProvider);
      ref.invalidate(repositoryDocumentsProvider);
      ref.invalidate(clubDocsCountProvider);

      return true;
    } on PostgrestException catch (e) {
      debugPrint('Error de base de datos: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error inesperado: $e');
      return false;
    }
  }
}
