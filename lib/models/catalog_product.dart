class CatalogProduct {
  String sku;
  String name;
  String description;
  String imagePath;
  String pricingName;
  double fallbackPrice;
  double? originalPrice;
  String tag;
  bool tagAlt;
  String meta;
  bool inStock;

  // 🔥 NOVOS CAMPOS
  List<String> grindOptions;   // ["Grão", "Moído"], ["Moído"], etc
  String? defaultGrind;        // "Grão" ou "Moído"

  CatalogProduct({
    required this.sku,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.pricingName,
    required this.fallbackPrice,
    this.originalPrice,
    required this.tag,
    required this.tagAlt,
    required this.meta,
    required this.inStock,
    this.grindOptions = const [],   // 🔥 default vazio
    this.defaultGrind,             // 🔥 pode ser null
  });

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    return CatalogProduct(
      sku: json['sku'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imagePath: json['imagePath'] ?? '',
      pricingName: json['pricingName'] ?? '',
      fallbackPrice: (json['fallbackPrice'] ?? 0).toDouble(),
      originalPrice: json['originalPrice'] != null
          ? (json['originalPrice'] as num).toDouble()
          : null,
      tag: json['tag'] ?? '',
      tagAlt: json['tagAlt'] ?? false,
      meta: json['meta'] ?? '',
      inStock: json['inStock'] ?? true,

      // 🔥 NOVOS
      grindOptions: (json['grindOptions'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          const [],
      defaultGrind: json['defaultGrind'] as String?,
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
      if (originalPrice != null) 'originalPrice': originalPrice,
      'tag': tag,
      'tagAlt': tagAlt,
      'meta': meta,
      'inStock': inStock,

      // 🔥 NOVOS
      'grindOptions': grindOptions,
      'defaultGrind': defaultGrind,
    };
  }
}
