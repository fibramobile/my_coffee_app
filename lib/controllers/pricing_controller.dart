import 'package:flutter/foundation.dart';
import '../models/pricing_model.dart';
import '../models/cost_item.dart';

class PricingController extends ChangeNotifier {
  PricingModel model;

  /// Lista de precificações salvas
  final List<PricingModel> _savedPricings = [];

  List<PricingModel> get savedPricings => List.unmodifiable(_savedPricings);

  PricingController({PricingModel? initial})
      : model = initial ??
      PricingModel(
        productName: 'Mel de Bugia',
        markupPercent: 50,
        items: [
          CostItem(
            name: 'Café verde (matéria-prima) KG',
            costPerKg: 63.75,
          ),
          CostItem(
            name: 'Torrefação / processamento',
            description: 'Custo por kg torrado + combustível',
            costPerKg: 8,
          ),
          CostItem(
            name: 'Embalagem',
            description:
            'Valor de 4x 250g para referência de 1kg',
            costPerKg: 7.2,
          ),
          CostItem(
            name: 'Rótulo',
            description:
            'Valor de 4x 250g para referência de 1kg',
            costPerKg: 4,
          ),
          CostItem(
            name: 'Mão de obra',
            description: 'Colher, secar, beneficiar etc.',
            costPerKg: 3,
          ),
          CostItem(
            name: 'Combustível / transporte / distribuição',
            costPerKg: 2.7,
          ),
          CostItem(
            name: 'Mel',
            costPerKg: 2,
          ),
          CostItem(
            name: 'Custos fixos / perdas / margem segurança',
            description:
            'Perdas, custos fixos rateados, marketing etc.',
            costPerKg: 5,
          ),
        ],
      );

  void setProductName(String value) {
    model.productName = value;
    notifyListeners();
  }

  void setMarkupPercent(double value) {
    model.markupPercent = value;
    notifyListeners();
  }

  void updateItemCost(int index, double value) {
    if (index < 0 || index >= model.items.length) return;
    model.items[index].costPerKg = value;
    notifyListeners();
  }

  void addItem(CostItem item) {
    model.items.add(item);
    notifyListeners();
  }

  void removeItem(int index) {
    if (index < 0 || index >= model.items.length) return;
    model.items.removeAt(index);
    notifyListeners();
  }

  /// Clona o modelo atual e salva na lista
  void saveCurrentPricing() {
    final clonedItems = model.items
        .map(
          (e) => CostItem(
        name: e.name,
        description: e.description,
        costPerKg: e.costPerKg,
      ),
    )
        .toList();

    final saved = PricingModel(
      productName: model.productName,
      markupPercent: model.markupPercent,
      items: clonedItems,
    );

    _savedPricings.add(saved);
    notifyListeners();
  }

  /// Remove um item salvo
  void removeSavedPricing(int index) {
    if (index < 0 || index >= _savedPricings.length) return;
    _savedPricings.removeAt(index);
    notifyListeners();
  }
}
