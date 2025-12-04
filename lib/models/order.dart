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
  final String paymentProvider;
  final String? paymentId;
  final String paymentStatus;
  final String shippingStatus;   // 👈 NOVO
  final DateTime? createdAt;
  final DateTime? updatedAt;     // 👈 opcional, já existe no JSON

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
    required this.shippingStatus,   // 👈 NOVO
    required this.createdAt,
    required this.updatedAt,        // 👈 NOVO
    this.client,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final paymentStatus = (json['paymentStatus'] ?? '').toString();

    // Se o backend ainda não mandou shippingStatus,
    // calcula um padrão em cima do paymentStatus:
    // - se PAGO -> EM_SEPARACAO
    // - senão   -> AGUARDANDO_PAGAMENTO
    String shippingStatus = (json['shippingStatus'] ?? '').toString();
    if (shippingStatus.isEmpty) {
      if (paymentStatus.toUpperCase() == 'PAGO') {
        shippingStatus = 'EM_SEPARACAO';
      } else {
        shippingStatus = 'AGUARDANDO_PAGAMENTO';
      }
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
      shippingStatus: shippingStatus,  // 👈
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

