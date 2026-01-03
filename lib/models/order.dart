import 'client.dart';
/*
class OrderItem {
  final String sku;
  final String name;
  final int qty;
  final double unitPrice;

  // ✅ NOVOS (congelados no momento da venda)
  final double? unitCostAtSale; // custo unitário (ex: custo do pacote 250g)
  final int? gramsAtSale;       // 250 / 500 / 1000 (opcional)

  OrderItem({
    required this.sku,
    required this.name,
    required this.qty,
    required this.unitPrice,
    this.unitCostAtSale,
    this.gramsAtSale,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    double? parseDoubleNullable(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? parseIntNullable(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return OrderItem(
      sku: (json['sku'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      qty: parseInt(json['qty']),
      unitPrice: parseDouble(json['unitPrice']),

      // ✅ lê do backend (se já existir)
      unitCostAtSale: parseDoubleNullable(json['unitCostAtSale']),
      gramsAtSale: parseIntNullable(json['gramsAtSale']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sku': sku,
      'name': name,
      'qty': qty,
      'unitPrice': unitPrice,

      // ✅ só salva se tiver (evita sujar pedidos antigos)
      if (unitCostAtSale != null) 'unitCostAtSale': unitCostAtSale,
      if (gramsAtSale != null) 'gramsAtSale': gramsAtSale,
    };
  }

  double get total => qty * unitPrice;
}
*/

class OrderItem {
  final String sku;
  final String name;
  final int qty;
  final double unitPrice;

  // ✅ NOVO: moagem
  final String? grind; // "Grão" | "Moído"

  // ✅ NOVOS (congelados no momento da venda)
  final double? unitCostAtSale; // custo unitário (ex: custo do pacote 250g)
  final int? gramsAtSale;       // 250 / 500 / 1000 (opcional)

  OrderItem({
    required this.sku,
    required this.name,
    required this.qty,
    required this.unitPrice,
    this.grind,
    this.unitCostAtSale,
    this.gramsAtSale,
  });

  // ----------------------------
  // Helpers internos
  // ----------------------------
  static String? _extractGrindFromName(String name) {
    final m = RegExp(
      r'\((GRÃO|GRAO|MOÍDO|MOIDO)\)',
      caseSensitive: false,
    ).firstMatch(name);

    if (m == null) return null;

    final v = (m.group(1) ?? '').toUpperCase();
    if (v.contains('GRA')) return 'Grão';
    if (v.contains('MOI')) return 'Moído';
    return null;
  }

  static String _stripGrindFromName(String name) {
    return name
        .replaceAll(
      RegExp(r'\s*\((GRÃO|GRAO|MOÍDO|MOIDO)\)\s*', caseSensitive: false),
      '',
    )
        .trim();
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    double? parseDoubleNullable(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? parseIntNullable(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    final rawName = (json['name'] ?? '').toString();
    final grindFromField = json['grind']?.toString();
    final grindFromName = _extractGrindFromName(rawName);

    final finalGrind =
    (grindFromField != null && grindFromField.trim().isNotEmpty)
        ? grindFromField.trim()
        : grindFromName;

    // ✅ deixa o nome "limpo" e consistente
    final cleanName = _stripGrindFromName(rawName);

    return OrderItem(
      sku: (json['sku'] ?? '').toString(),
      name: cleanName,
      qty: parseInt(json['qty']),
      unitPrice: parseDouble(json['unitPrice']),

      // ✅ NOVO: moagem
      grind: finalGrind,

      // ✅ lê do backend (se já existir)
      unitCostAtSale: parseDoubleNullable(json['unitCostAtSale']),
      gramsAtSale: parseIntNullable(json['gramsAtSale']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sku': sku,
      'name': name,
      'qty': qty,
      'unitPrice': unitPrice,

      // ✅ NOVO
      if (grind != null && grind!.isNotEmpty) 'grind': grind,

      // ✅ só salva se tiver (evita sujar pedidos antigos)
      if (unitCostAtSale != null) 'unitCostAtSale': unitCostAtSale,
      if (gramsAtSale != null) 'gramsAtSale': gramsAtSale,
    };
  }

  double get total => qty * unitPrice;
}


class Order {
  final String id;
  final String clientId;
  final List<OrderItem> items;

  final double subtotal;
  final double shipping;
  final double total;

  // Pagamento
  final String paymentProvider;
  final String? paymentId;
  final String paymentStatus;

  // Envio
  final String shippingStatus;

  // Transportadora / prazo (podem vir com 2 nomes diferentes no JSON)
  final String? freightService;   // ex: "JeT - Standard"
  final String? freightDeadline;  // ex: "4 dias úteis"

  // Datas
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Cliente completo carregado depois
  Client? client;

  Order({
    required this.id,
    required this.clientId,
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.total,
    required this.paymentProvider,
    required this.paymentId,
    required this.paymentStatus,
    required this.shippingStatus,
    required this.createdAt,
    required this.updatedAt,
    this.freightService,
    this.freightDeadline,
    this.client,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final paymentStatus = (json['paymentStatus'] ?? '').toString();

    // ShippingStatus com fallback pros pedidos antigos
    String shippingStatus = (json['shippingStatus'] ?? '').toString();
    if (shippingStatus.isEmpty) {
      shippingStatus = paymentStatus.toUpperCase() == 'PAGO'
          ? 'EM_SEPARACAO'
          : 'AGUARDANDO_PAGAMENTO';
    }

    final itemsJson = (json['items'] as List?) ?? const [];

    return Order(
      id: json['id'] ?? '',
      clientId: json['clientId'] ?? '',
      items: itemsJson.map((e) => OrderItem.fromJson(e)).toList(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      shipping: (json['shipping'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      paymentProvider: json['paymentProvider'] ?? '',
      paymentId: json['paymentId'],
      paymentStatus: paymentStatus,
      shippingStatus: shippingStatus,

      // 🔥 Mapeia tanto freight* quanto shipping*
      freightService:
      json['freightService'] ?? json['shippingService'],
      freightDeadline:
      json['freightDeadline'] ?? json['shippingDeadline'],

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  int get totalItems =>
      items.fold<int>(0, (sum, item) => sum + item.qty);
}
