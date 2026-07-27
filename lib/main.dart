import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargamos el archivo .env antes de inicializar Supabase
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    throw Exception(
      'Error: No se encontró el archivo .env. Asegúrate de crearlo en la raíz del proyecto.',
    );
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim() ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'Error: SUPABASE_URL y SUPABASE_ANON_KEY deben existir en el archivo .env.',
    );
  }

  final parsedSupabaseUrl = Uri.tryParse(supabaseUrl);
  if (parsedSupabaseUrl == null ||
      !parsedSupabaseUrl.hasScheme ||
      !parsedSupabaseUrl.hasAuthority) {
    throw Exception(
      'Error: SUPABASE_URL debe ser una URL completa, por ejemplo https://tu-proyecto.supabase.co.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ProviderScope(child: CucApp()));
}

class CucApp extends ConsumerWidget {
  const CucApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'CUC App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,

      //CONFIGURACIÓN DE LOCALIZACIÓN
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'MX'), // Español de México como idioma principal
        Locale('en', 'US'), // Inglés como respaldo
      ],
      routerConfig: router,
    );
  }
}