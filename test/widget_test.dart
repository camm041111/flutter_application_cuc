import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Obligatorio para Riverpod
import 'package:cuc_research_portal/main.dart';

void main() {
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

    // Verificamos que el texto del botón de login esté presente
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
  });
}