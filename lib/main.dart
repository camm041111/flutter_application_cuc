import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/providers/auth_providers.dart';
import 'core/services/push_messaging_service.dart';
// Importa tu tema oscuro/antracita
import 'core/theme/app_theme.dart';
// Importa el provider del router que creamos
import 'core/constants/app_routes.dart';

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

  if (_supportsFirebaseMessaging) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ProviderScope(child: CucApp()));
}

bool get _supportsFirebaseMessaging {
  return !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}

class CucApp extends ConsumerStatefulWidget {
  const CucApp({super.key});

  @override
  ConsumerState<CucApp> createState() => _CucAppState();
}

class _CucAppState extends ConsumerState<CucApp> {
  ProviderSubscription<AsyncValue<AuthState>>? _authSubscription;

  @override
  void initState() {
    super.initState();

    if (_supportsFirebaseMessaging) {
      _authSubscription = ref.listenManual(authStateProvider, (_, next) {
        next.whenData((authState) {
          if (authState.session?.user != null) {
            ref.read(pushMessagingServiceProvider).syncTokenForCurrentUser();
          }
        });
      });

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(pushMessagingServiceProvider).initialize();
        await ref.read(pushMessagingServiceProvider).syncTokenForCurrentUser();
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
