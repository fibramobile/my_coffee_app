class CatalogProduct {
  String sku;
  String name;
  String description;
  String imagePath;
  String pricingName;      // nome usado na precificação (ex: "Mel de Bugia")
  double fallbackPrice;    // preço padrão, caso não ache na precificação
  String tag;
  bool tagAlt;
  String meta;
  bool inStock;

  CatalogProduct({
    required this.sku,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.pricingName,
    required this.fallbackPrice,
    required this.tag,
    required this.tagAlt,
    required this.meta,
    required this.inStock,
  });

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    return CatalogProduct(
      sku: json['sku'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imagePath: json['imagePath'] ?? '',
      pricingName: json['pricingName'] ?? '',
      fallbackPrice: (json['fallbackPrice'] ?? 0).toDouble(),
      tag: json['tag'] ?? '',
      tagAlt: json['tagAlt'] ?? false,
      meta: json['meta'] ?? '',
      inStock: json['inStock'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sku': sku,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'pricingName': pricingName,
      'fallbackPrice': fallbackPrice,
      'tag': tag,
      'tagAlt': tagAlt,
      'meta': meta,
      'inStock': inStock,
    };
  }
}
