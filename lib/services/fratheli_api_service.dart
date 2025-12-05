import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/client.dart';
import '../models/order.dart';

class FratheliApiService {
  static const String _base =
      //'https://smapps.16mb.com/fratheli/site';
  'https://frathelicafe.com.br/api';

  final http.Client _client;

  FratheliApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Lista de pedidos
  Future<List<Order>> fetchOrders() async {
    final uri = Uri.parse('$_base/orders_api.php'); // 👈 mudou
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Erro HTTP ${response.statusCode} ao buscar pedidos');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception('Formato inesperado de orders_api.php (esperado array)');
    }

    return decoded.map<Order>((e) => Order.fromJson(e)).toList();
  }

  Future<Order> updatePaymentStatus({
    required String orderId,
    required String paymentStatus,
    String paymentProvider = 'PIX_MANUAL',
    String? paymentId,
  }) async {
    final uri = Uri.parse('$_base/api.php?action=update-payment');

    final body = jsonEncode({
      'orderId': orderId,
      'paymentStatus': paymentStatus,
      'paymentProvider': paymentProvider,
      'paymentId': paymentId,
    });

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode != 200) {
      throw Exception(
        'Erro HTTP ${res.statusCode} ao atualizar pagamento',
      );
    }

    final data = jsonDecode(res.body);

    if (data['success'] != true) {
      throw Exception('Falha na API: ${data['error'] ?? 'erro desconhecido'}');
    }

    // API devolve `order` atualizado
    return Order.fromJson(data['order']);
  }


  Future<Order> updateShippingStatus({
    required String orderId,
    required String shippingStatus,
  }) async {
    // pode usar o mesmo api.php com outra action
    final uri = Uri.parse('$_base/api.php?action=update-shipping');

    final body = jsonEncode({
      'orderId': orderId,
      'shippingStatus': shippingStatus,
    });

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode != 200) {
      throw Exception(
        'Erro HTTP ${res.statusCode} ao atualizar status de envio',
      );
    }

    final data = jsonDecode(res.body);

    if (data['success'] != true) {
      throw Exception('Falha na API: ${data['error'] ?? 'erro desconhecido'}');
    }

    // API deve devolver `order` atualizado
    return Order.fromJson(data['order']);
  }

  Future<void> deleteOrder(String orderId) async {
    final uri = Uri.parse('https://frathelicafe.com.br/api/delete_order.php');

    final resp = await http.post(uri, body: {
      'orderId': orderId,
    });

    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Falha ao excluir pedido (HTTP ${resp.statusCode}).');
    }
  }




  /// Lista de clientes
  Future<List<Client>> fetchClients() async {
    final uri = Uri.parse('$_base/clients_api.php'); // 👈 mudou
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Erro HTTP ${response.statusCode} ao buscar clientes');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception('Formato inesperado de clients_api.php (esperado array)');
    }

    return decoded.map<Client>((e) => Client.fromJson(e)).toList();
  }

  /// (Opcional) detalhe do pedido, usando o api.php que você já tem
  Future<Map<String, dynamic>> fetchOrderDetail(String orderId) async {
    final uri = Uri.parse(
      '$_base/api.php?action=get-order&id=${Uri.encodeComponent(orderId)}',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
          'Erro HTTP ${response.statusCode} ao buscar detalhes do pedido');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map || decoded['order'] == null) {
      throw Exception('Formato inesperado em get-order');
    }

    final order = Order.fromJson(decoded['order']);
    Client? client;
    if (decoded['client'] != null) {
      client = Client.fromJson(decoded['client']);
    }

    return {
      'order': order,
      'client': client,
    };
  }
}
