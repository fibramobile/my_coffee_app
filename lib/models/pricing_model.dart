/*import 'cost_item.dart';

class PricingModel {
  String productName;          // Ex: "Mel de Bugia"
  double markupPercent;        // Ex: 50 (%)
  List<CostItem> items;

  PricingModel({
    required this.productName,
    required this.markupPercent,
    required this.items,
  });

  double get totalCostPerKg =>
      items.fold(0.0, (prev, e) => prev + e.costPerKg);

  double get finalPricePerKg =>
      totalCostPerKg * (1 + markupPercent / 100);

  double get price250g => finalPricePerKg * 0.25;

  double get profitPerKg => finalPricePerKg - totalCostPerKg;

  double get profitMargin =>
      finalPricePerKg == 0 ? 0 : profitPerKg / finalPricePerKg;

  // ---- JSON ----

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'markupPercent': markupPercent,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory PricingModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>? ?? []);
    return PricingModel(
      productName: json['productName'] as String? ?? '',
      markupPercent: (json['markupPercent'] as num?)?.toDouble() ?? 0.0,
      items: itemsJson
          .map((e) => CostItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

*/
import 'cost_item.dart';

class PricingModel {
  String pricingId;        // ✅ NOVO: ex "FLOR", "TIUBA", "BUGIA"
  String productName;      // Ex: "Flor da Mata (2SL)"
  double markupPercent;    // Ex: 50 (%)
  List<CostItem> items;

  PricingModel({
    required this.pricingId,
    required this.productName,
    required this.markupPercent,
    required this.items,
  });

  double get totalCostPerKg =>
      items.fold(0.0, (prev, e) => prev + e.costPerKg);

  double get finalPricePerKg =>
      totalCostPerKg * (1 + markupPercent / 100);

  double get price250g => finalPricePerKg * 0.25;

  double get profitPerKg => finalPricePerKg - totalCostPerKg;

  double get profitMargin =>
      finalPricePerKg == 0 ? 0 : profitPerKg / finalPricePerKg;

  Map<String, dynamic> toJson() {
    return {
      'pricingId': pricingId, // ✅ NOVO
      'productName': productName,
      'markupPercent': markupPercent,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory PricingModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>? ?? []);

    // ✅ fallback para JSON antigo (sem pricingId)
    final String pidRaw = (json['pricingId'] as String?) ?? '';
    final String nameRaw = (json['productName'] as String?) ?? '';
    final String fallbackPid = _fallbackIdFromProductName(nameRaw);

    return PricingModel(
      pricingId: pidRaw.isNotEmpty ? pidRaw : fallbackPid,
      productName: nameRaw,
      markupPercent: (json['markupPercent'] as num?)?.toDouble() ?? 0.0,
      items: itemsJson
          .map((e) => CostItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static String _fallbackIdFromProductName(String productName) {
    final s = productName.toUpperCase();

    // heurística inicial só pra não quebrar quem tem json antigo:
    if (s.contains('TIUBA')) return 'TIUBA';
    if (s.contains('BUGIA')) return 'BUGIA';
    if (s.contains('JATA')) return 'JATAI';
    if (s.contains('FLOR')) return 'FLOR';
    if (s.contains('ROCA')) return 'ROCA';
    if (s.contains('BICA')) return 'BICA';

    // se não detectar, vira "SEM_ID"
    return 'SEM_ID';
  }
}
