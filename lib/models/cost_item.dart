class CostItem {
  final String name;
  final String description;
  double costPerKg;

  CostItem({
    required this.name,
    this.description = '',
    this.costPerKg = 0.0,
  });

  CostItem copyWith({
    String? name,
    String? description,
    double? costPerKg,
  }) {
    return CostItem(
      name: name ?? this.name,
      description: description ?? this.description,
      costPerKg: costPerKg ?? this.costPerKg,
    );
  }

  // ---- JSON ----

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'costPerKg': costPerKg,
    };
  }

  factory CostItem.fromJson(Map<String, dynamic> json) {
    return CostItem(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      costPerKg: (json['costPerKg'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
