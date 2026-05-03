import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Proveedor global e inmutable del cliente de Supabase.
/// Cualquier repositorio o provider que necesite datos debe consumir este provider,
/// NUNCA llamar a Supabase.instance.client directamente.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});