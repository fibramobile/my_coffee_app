import 'package:flutter/material.dart';
import 'controllers/pricing_controller.dart';
import 'views/pricing_form_page.dart';
import 'views/pricing_list_page.dart';

void main() {
  runApp(const CafePrecoApp());
}

class CafePrecoApp extends StatelessWidget {
  const CafePrecoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = PricingController();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestão de Café – Precificação',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        // Fundo geral branco premium
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),

        // Paleta Frathéli
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37), // dourado premium
          brightness: Brightness.light,
        ),

        // Textos claros, elegantes
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
          titleLarge: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
          titleMedium: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),

        // Campos de texto
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(color: Colors.grey.shade700),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(
              color: Color(0xFFD4AF37),
              width: 1.5,
            ),
          ),
        ),

        // Cards (custos e lista de produtos)
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),

        // Botão salvar
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37), // dourado
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            elevation: 2,
          ),
        ),

        // AppBar clara e elegante
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          foregroundColor: Colors.black87,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // 👉 AGORA A TELA INICIAL É A LISTA
      home: PricingListPage(controller: controller),
    );
  }
}
