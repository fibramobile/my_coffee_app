import 'package:flutter/material.dart';
import 'controllers/pricing_controller.dart';
import 'views/pricing_form_page.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD4AF37)),
        useMaterial3: true,
      ),
      home: PricingFormPage(controller: controller),
    );
  }
}
