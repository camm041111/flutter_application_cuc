import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Importa tu tema oscuro/antracita
import 'core/theme/app_theme.dart';
// Importa el provider del router que creamos
import 'core/constants/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

// Cargamos el archivo .env antes de inicializar Supabase
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    throw Exception("Error: No se encontró el archivo .env. Asegúrate de crearlo en la raíz del proyecto.");
  }

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const ProviderScope(child: CucApp()));
}

// Convertimos a ConsumerWidget para poder leer el routerProvider
class CucApp extends ConsumerWidget {
  const CucApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtenemos la instancia de GoRouter configurada con nuestra lógica de seguridad
    final router = ref.watch(routerProvider);

    // Cambiamos MaterialApp tradicional por MaterialApp.router
    return MaterialApp.router(
      title: 'Clubes Universitarios de Ciencias',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark, // Tu tema minimalista
      routerConfig: router, // Inyectamos GoRouter
    );
  }
}