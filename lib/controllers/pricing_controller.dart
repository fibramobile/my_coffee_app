import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pricing_model.dart';
import '../models/cost_item.dart';

class PricingController extends ChangeNotifier {
  static const String _prefsKey = 'saved_pricings';

  PricingModel model;

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
      ) {
    _loadFromPrefs();
  }

  // ------- setters normais -------

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

  // ------- carregar para edição -------

  void loadFromSaved(int index) {
    if (index < 0 || index >= _savedPricings.length) return;

    final selected = _savedPricings[index];

    final clonedItems = selected.items
        .map(
          (e) => CostItem(
        name: e.name,
        description: e.description,
        costPerKg: e.costPerKg,
      ),
    )
        .toList();

    model = PricingModel(
      productName: selected.productName,
      markupPercent: selected.markupPercent,
      items: clonedItems,
    );

    notifyListeners();
  }

  // ------- salvar (novo ou editar) -------

  Future<void> saveCurrentPricing({int? indexToUpdate}) async {
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

    if (indexToUpdate != null &&
        indexToUpdate >= 0 &&
        indexToUpdate < _savedPricings.length) {
      _savedPricings[indexToUpdate] = saved;
    } else {
      _savedPricings.add(saved);
    }

    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> removeSavedPricing(int index) async {
    if (index < 0 || index >= _savedPricings.length) return;
    _savedPricings.removeAt(index);
    await _saveToPrefs();
    notifyListeners();
  }

  // ------- SharedPreferences -------

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final listMap =
    _savedPricings.map((p) => p.toJson()).toList();

    final jsonString = jsonEncode(listMap);

    await prefs.setString(_prefsKey, jsonString);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);

    if (jsonString == null || jsonString.isEmpty) return;

    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      _savedPricings
        ..clear()
        ..addAll(decoded
            .map((e) => PricingModel.fromJson(e as Map<String, dynamic>)));

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar precificações salvas: $e');
    }
  }
}
