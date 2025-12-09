import 'client.dart';

class OrderItem {
  final String sku;
  final String name;
  final int qty;
  final double unitPrice;

  OrderItem({
    required this.sku,
    required this.name,
    required this.qty,
    required this.unitPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      sku: json['sku'] ?? '',
      name: json['name'] ?? '',
      qty: (json['qty'] ?? 0) is int
          ? json['qty']
          : int.tryParse(json['qty'].toString()) ?? 0,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
    );
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
