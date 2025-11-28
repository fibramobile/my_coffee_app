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

  /// Soma de todos os custos por kg
  double get totalCostPerKg =>
      items.fold(0.0, (prev, e) => prev + e.costPerKg);

  /// Preço final por kg com markup (igual à sua planilha)
  double get finalPricePerKg =>
      totalCostPerKg * (1 + markupPercent / 100);

  /// Preço para 250 g
  double get price250g => finalPricePerKg * 0.25;

  /// Lucro líquido por kg (preço - custo)
  double get profitPerKg => finalPricePerKg - totalCostPerKg;

  /// Margem líquida (lucro/preço)
  double get profitMargin =>
      finalPricePerKg == 0 ? 0 : profitPerKg / finalPricePerKg;
}
