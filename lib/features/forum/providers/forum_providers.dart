import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/cache/app_cache_service.dart';

// Definimos el provider que inyectará nuestras acciones del foro
final forumActionsProvider = Provider<ForumActions>((ref) {
  return ForumActions(ref);
});

class ForumActions {
  ForumActions(this.ref);
  final Ref ref;

  /// Vota por una pregunta del foro (1 para positivo, -1 para negativo)
  /// Retorna un mapa con los nuevos contadores exactos desde la BD, o null si falla.
  Future<Map<String, dynamic>?> voteQuestion(String questionId, int value) async {
    final supabase = ref.read(supabaseClientProvider);

    // Validación estricta en el cliente (Fail-Fast antes de gastar red)
    if (value != 1 && value != -1) {
      debugPrint('Error arquitectónico: El valor del voto debe ser 1 o -1');
      return null;
    }

    try {
      // Delegamos toda la lógica transaccional y de concurrencia al RPC de PostgreSQL
      final response = await supabase.rpc(
        'votar_pregunta_foro',
        params: {
          'p_id_pregunta': questionId,
          'p_valor': value,
        },
      );

      // Si todo sale bien, limpiamos la caché relacionada con las preguntas
      // (si estás usando app_cache_service para las listas del foro)
      await ref.read(appCacheServiceProvider).invalidatePrefix('forum:');

      // La base de datos nos responde con: {votos_positivos: X, votos_negativos: Y, mi_voto: Z}
      // Retornamos esto para que tu UI (Widget) actualice sus estados locales inmediatamente
      // sin necesidad de volver a consultar toda la lista de preguntas.
      return Map<String, dynamic>.from(response as Map);

    } on PostgrestException catch (e) {
      // Capturamos violaciones de constraints o errores personalizados que lanzamos en el SQL
      debugPrint('Error de integridad/BD al votar: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error inesperado al intentar votar: $e');
      return null;
    }
  }
}
