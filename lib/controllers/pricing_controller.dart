import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/pricing_model.dart';
import '../models/cost_item.dart';

class PricingController extends ChangeNotifier {
  // 🔴 URL do seu endpoint PHP
  static const String _apiUrl =
      'https://smapps.16mb.com/fratheli/app/pricings.php';

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
            description: 'Valor de 4x 250g para referência de 1kg',
            costPerKg: 7.2,
          ),
          CostItem(
            name: 'Rótulo',
            description: 'Valor de 4x 250g para referência de 1kg',
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
            description: 'Perdas, custos fixos rateados, marketing etc.',
            costPerKg: 5,
          ),
        ],
      ) {
    _loadFromServer();
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

    await _syncToServer();
    notifyListeners();
  }

  Future<void> removeSavedPricing(int index) async {
    if (index < 0 || index >= _savedPricings.length) return;

    try {
      _savedPricings.removeAt(index);
      await _syncToServer();
      notifyListeners();
    } catch (e, s) {
      debugPrint('Erro ao remover precificação: $e');
      debugPrint('$s');
      rethrow;
    }
  }


  // 🔥 NOVO: margem líquida por SKU para usar no dashboard
  double? getNetMarginForSku(String sku) {
    // MAPA: qual SKU usa qual precificação (productName)
    // ajuste esses nomes pros MESMOS da tela de precificação:
    const Map<String, String> skuToProductName = {
      'BUGIA-250': 'Mel de Bugia',
      'TIUBA-250': 'Mel de Tiúba',
      // 'ROCA-250': 'Café Cheiro de Roça',
      // 'FLOR-250': 'Flor da Mata',
      // etc...
    };

    final productName = skuToProductName[sku];
    if (productName == null) return null;

    try {
      // procura o pricing salvo daquele produto
      final pricing = _savedPricings.firstWhere(
            (p) => p.productName == productName,
      );

      final m = pricing.markupPercent;
      if (m <= 0) return null;

      // margem líquida ≈ markup / (100 + markup)
      // ex.: 50% → 50/150 = 0.3333 (33,33%)
      return m / (100 + m);
    } catch (_) {
      return null;
    }
  }

  // ------- SYNC REMOTA COM PHP -------

  Future<void> _loadFromServer() async {
    try {
      final uri = Uri.parse(_apiUrl);
      final resp = await http.get(uri);

      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        final decoded = jsonDecode(resp.body);

        if (decoded is List) {
          _savedPricings
            ..clear()
            ..addAll(
              decoded
                  .map(
                    (e) => PricingModel.fromJson(e as Map<String, dynamic>),
              )
                  .toList(),
            );
          notifyListeners();
        }
      } else {
        debugPrint(
          'Falha ao carregar do servidor: ${resp.statusCode} ${resp.body}',
        );
      }
    } catch (e) {
      debugPrint('Erro ao carregar precificações do servidor: $e');
    }
  }

  Future<void> _syncToServer() async {
    try {
      final uri = Uri.parse(_apiUrl);

      final listMap = _savedPricings.map((p) => p.toJson()).toList();

      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode(listMap),
      );

      if (resp.statusCode != 200) {
        debugPrint(
          'Falha ao salvar no servidor: ${resp.statusCode} ${resp.body}',
        );
      }
    } catch (e) {
      debugPrint('Erro ao salvar precificações no servidor: $e');
    }
  }
}
