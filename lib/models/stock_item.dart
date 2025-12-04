class StockItem {
  String name;        // Ex: "Microlote 01"
  String unit;        // Ex: "kg", "pacotes"
  double quantity;    // Quantidade atual
  double minQuantity; // Estoque mínimo desejado
  String type;        // 'verde', 'torrado', 'outro'

  StockItem({
    required this.name,
    required this.unit,
    required this.quantity,
    required this.minQuantity,
    required this.type,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      name: json['name'] as String? ?? '',
      unit: json['unit'] as String? ?? 'unid.',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      minQuantity: (json['minQuantity'] as num?)?.toDouble() ?? 0,
      // JSON antigo não tem "type" → assumo "torrado" (produtos finais)
      type: json['type'] as String? ?? 'torrado',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'unit': unit,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'type': type,
    };
  }
}
