// lib/features/management/providers/coordinator_providers.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

// PASO 2: Clase de Acciones con Blindaje Estricto
class CoordinatorActions {
  // 🛡️ Mantiene el flujo de aprobación inicial (registrado -> activo)
  static Future<bool> approveMember(WidgetRef ref, String targetUserId) async {
    final supabase = ref.read(supabaseClientProvider);
    try {
      // Reutilizamos el RPC para mantener la mutación segura
      await supabase.rpc('modificar_miembro_club', params: {
        'p_id_objetivo': targetUserId,
        'p_nuevo_rol': 'miembro',
        'p_nuevo_estado': 'activo',
      });

      final cache = ref.read(appCacheServiceProvider);
      await cache.invalidate('profile:$targetUserId');
      await cache.invalidatePrefix('club:');
      ref.invalidate(pendingMembersProvider);
      ref.invalidate(clubDirectoryProvider);
      ref.invalidate(activeMembersProvider);
      ref.invalidate(historicalMembersProvider);
      return true;
    } catch (e) {
      debugPrint('Error al aprobar miembro: $e');
      return false;
    }
  }

  // 🛡️ Nueva función para gestionar miembros existentes
  static Future<bool> updateMember(
    WidgetRef ref,
    String targetUserId,
    String newRole,
    String newStatus,
  ) async {
    final supabase = ref.read(supabaseClientProvider);
    try {
      await supabase.rpc('modificar_miembro_club', params: {
        'p_id_objetivo': targetUserId,
        'p_nuevo_rol': newRole,
        'p_nuevo_estado': newStatus,
      });

      final cache = ref.read(appCacheServiceProvider);
      await cache.invalidate('profile:$targetUserId');
      await cache.invalidatePrefix('club:');
      ref.invalidate(pendingMembersProvider);
      ref.invalidate(clubDirectoryProvider);
      ref.invalidate(activeMembersProvider);
      ref.invalidate(historicalMembersProvider);
      return true;
    } catch (e) {
      debugPrint('Error de seguridad al modificar miembro: $e');
      return false;
    }
  }

  // 🛡️ Actualización para incluir feedback obligatorio en rechazos
  static Future<bool> reviewDocument(
    WidgetRef ref,
    String documentId, {
    required bool approved,
    String? comment,
  }) async {
    final supabase = ref.read(supabaseClientProvider);
    try {
      await supabase.rpc(
        'revisar_publicacion_repositorio',
        params: {
          'p_id_publicacion': documentId,
          'p_aprobada': approved,
          'p_comentario': comment, // Ahora soporta feedback
        },
      );

      final cache = ref.read(appCacheServiceProvider);
      await cache.invalidatePrefix('repository:');
      await cache.invalidatePrefix('club:');
      ref.invalidate(pendingDocumentsProvider);
      ref.invalidate(repositoryDocumentsProvider);
      ref.invalidate(clubDocsCountProvider);
      return true;
    } catch (e) {
      debugPrint('Error al revisar documento: $e');
      return false;
    }
  }
}

// 🛡️ Proveedor para la plantilla activa del club (excluye al propio usuario para evitar auto-mutaciones)
final activeMembersProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final user = supabase.auth.currentUser;

  if (user == null) return [];

  final profile = await supabase
      .from('perfiles')
      .select('id_club')
      .eq('id', user.id)
      .single();

  return await supabase
      .from('perfiles')
      .select('id, nombre_completo, matricula, rol, estado')
      .eq('id_club', profile['id_club'])
      .eq('estado', 'activo')
      .neq('id', user.id) // Previene auto-modificarse accidentalmente
      .order('rol', ascending: true);
});

// 🛡️ Proveedor para gestionar miembros inactivos o dados de baja
final historicalMembersProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final profile = await supabase
      .from('perfiles')
      .select('id_club')
      .eq('id', user.id)
      .single();

  return await supabase
      .from('perfiles')
      .select('id, nombre_completo, matricula, rol, estado')
      .eq('id_club', profile['id_club'])
      .inFilter('estado', const ['inactivo', 'baja'])
      .order('nombre_completo', ascending: true);
});
