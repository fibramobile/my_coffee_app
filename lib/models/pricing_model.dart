import 'cost_item.dart';

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
