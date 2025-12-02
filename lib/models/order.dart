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
  final DateTime? createdAt;

  /// Opcional: client “acoplado” pra facilitar exibição
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
    required this.createdAt,
    this.client,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
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
      paymentStatus: json['paymentStatus'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  int get totalItems =>
      items.fold<int>(0, (sum, item) => sum + item.qty);
}
