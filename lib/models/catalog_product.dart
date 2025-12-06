class CatalogProduct {
  String sku;
  String name;
  String description;
  String imagePath;
  String pricingName;
  double fallbackPrice;
  double? originalPrice;        // 🔥 novo
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
    this.originalPrice,         // 🔥 novo
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
      originalPrice: json['originalPrice'] != null     // 🔥 novo
          ? (json['originalPrice'] as num).toDouble()
          : null,
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
      if (originalPrice != null) 'originalPrice': originalPrice, // 🔥 novo
      'tag': tag,
      'tagAlt': tagAlt,
      'meta': meta,
      'inStock': inStock,
    };
  }
}
