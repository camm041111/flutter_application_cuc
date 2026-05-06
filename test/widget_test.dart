import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Obligatorio para Riverpod
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cuc_research_portal/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
    );
  });

  testWidgets('App inicial se muestra correctamente', (WidgetTester tester) async {
    // 1. Cambiamos CucResearchApp por CucApp
    // 2. Envolvemos en ProviderScope para que los providers de Auth y Router funcionen
    await tester.pumpWidget(
      const ProviderScope(
        child: CucApp(),
      ),
    );

    // pumpAndSettle espera a que las animaciones y rutas iniciales terminen
    await tester.pumpAndSettle();

    // Verificamos que la pantalla de login esté presente.
    expect(find.text('INICIAR SESIÓN'), findsWidgets);
    expect(find.text('CORREO INSTITUCIONAL'), findsOneWidget);
  });
}
