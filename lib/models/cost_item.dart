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
}
