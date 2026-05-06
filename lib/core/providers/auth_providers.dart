import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Proveedor del cliente de Supabase (Inyección de dependencias limpia)
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// 2. Capa de Sesión (StreamProvider)
// Escucha en tiempo real si el usuario inicia sesión, cierra sesión o el token expira.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return supabase.auth.onAuthStateChange;
});

// 3. Helper para obtener al usuario actual rápidamente
final currentUserProvider = Provider<User?>((ref) {
  // Observamos el Stream de arriba. Si hay sesión, devolvemos el usuario.
  return ref.watch(authStateProvider).value?.session?.user;
});

// 4. Capa de Autorización (FutureProvider)
// Este proveedor reacciona automáticamente cada vez que el usuario cambia.
final perfilUsuarioProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return null; // No hay usuario logeado, no hay perfil.
  }

  final supabase = ref.watch(supabaseClientProvider);

  // Consultamos la tabla perfiles usando el ID del usuario autenticado
  final response = await supabase
      .from('perfiles')
      .select()
      .eq('id', user.id)
      .maybeSingle(); // maybeSingle() evita errores si por alguna razón no existe aún

  return response;
});