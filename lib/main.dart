import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'features/auth/login/login_screen.dart';
import 'features/auth/register/register_screen.dart';
import 'features/main_shell.dart';
import 'features/new_post/new_post_screen.dart';


Future<void> main() async {
  // asegura que los bindings de Flutter estén listos antes de ejecutar código nativo
  WidgetsFlutterBinding.ensureInitialized();

  // .env
  await dotenv.load(fileName: ".env");

  // conexión con Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // ProviderScope (Requisito de Riverpod)
  runApp(const ProviderScope(child: CucResearchApp()));
}

class CucResearchApp extends StatelessWidget {
  const CucResearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CUC Research Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // Nota: Más adelante, en lugar de ir directo al Login,
      // Riverpod decidirá aquí si va al Login o al MainShell dependiendo si el usuario ya inició sesión.
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.main: (_) => const MainShell(),
        AppRoutes.newPost: (_) => const NewPostScreen(),
      },
    );
  }
}