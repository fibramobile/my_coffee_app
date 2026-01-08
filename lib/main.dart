import 'package:flutter/material.dart';

import 'controllers/pricing_controller.dart';
import 'views/home_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const CafePrecoApp());
}

class CafePrecoApp extends StatefulWidget {
  const CafePrecoApp({Key? key}) : super(key: key);

  @override
  State<CafePrecoApp> createState() => _CafePrecoAppState();
}

class _CafePrecoAppState extends State<CafePrecoApp> {
  // Uma única instância do controller para o app inteiro
  final PricingController _pricingController = PricingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // ✅ força pt_BR (dd/MM/yyyy)
      locale: const Locale('pt', 'BR'),

      // (opcional) limita os locais suportados
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],

      // ✅ delegates obrigatórios
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'Gestão de Café – App',
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

        // Cards (custos, lista, dashboard)
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),

        // Botões principais
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

      // 👉 Tela principal agora é o dashboard, recebendo o mesmo controller
      home: HomePage(controller: _pricingController),
    );
  }
}
