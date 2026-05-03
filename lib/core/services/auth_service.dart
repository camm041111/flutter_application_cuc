import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Creamos un Provider de Riverpod para acceder a este servicio desde cualquier pantalla
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Metodo para registrar un nuevo usuario
  /// Retorna un [String] con el mensaje de error, o [null] si fue exitoso.
  Future<String?> registrarUsuario({
    required String correo,
    required String contrasena,
    required String nombreCompleto,
    required String matricula,
    required String idDivision,
    required String idClub
  }) async {
    try {
      // 1. Validación de Regla de Negocio: Correo Institucional
      final correoMin = correo.trim().toLowerCase();
      if (!correoMin.endsWith('@alumno.ujat.mx') && !correoMin.endsWith('@ujat.mx')) {
        return 'Registro denegado: Usa tu correo institucional (@alumno.ujat.mx o @ujat.mx)';
      }

      // 2. Ejecutar el registro en Supabase Auth
      // Al pasar datos en 'data', el Trigger de PostgreSQL que creamos
      // automáticamente insertará una fila en la tabla 'perfiles'.
      final response = await _supabase.auth.signUp(
        email: correoMin,
        password: contrasena,
        data: {
          'full_name': nombreCompleto.trim(),
          'matricula': matricula.trim(),
          'id_division': idDivision, // UUID de la tabla divisiones_academicas
          'id_club': idClub,
        },
      );

      // Verificamos si se creó el usuario correctamente
      if (response.user != null) {
        return null; // Éxito
      } else {
        return 'No se pudo completar el registro. Intenta de nuevo.';
      }
    } on AuthException catch (e) {
      // Errores propios de Supabase (ej. la contraseña es muy corta, o el correo ya existe)
      if (e.message.contains('already registered')) {
        return 'Este correo ya está registrado.';
      }
      return 'Error de autenticación: ${e.message}';
    } catch (e) {
      // Cualquier otro error inesperado
      return 'Ocurrió un error inesperado: $e';
    }
  }
  /// Método para iniciar sesión
  Future<String?> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: correo.trim().toLowerCase(),
        password: contrasena,
      );
      return null; // Éxito
    } on AuthException catch (e) {
      // Manejo de errores específicos (RF01.5: Intentos fallidos)
      if (e.message.contains('Invalid login credentials')) {
        return 'Correo o contraseña incorrectos.';
      }
      if (e.message.contains('Email not confirmed')) {
        return 'Por favor, confirma tu correo institucional.';
      }
      return e.message;
    } catch (e) {
      return 'Error de conexión: $e';
    }
  }

  /// Cerrar sesión
  Future<void> cerrarSesion() async {
    await _supabase.auth.signOut();
  }
}