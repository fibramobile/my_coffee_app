import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_coffee_app/main.dart';

void main() {
  testWidgets('App abre mostrando a lista de precificações',
          (WidgetTester tester) async {
        // Monta o app
        await tester.pumpWidget(const CafePrecoApp());

        // Verifica se o título da AppBar da tela inicial aparece
        expect(find.text('Precificações de Café'), findsOneWidget);
      });
}
