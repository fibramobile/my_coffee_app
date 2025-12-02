import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/order.dart';
import '../services/fratheli_api_service.dart';

class ClientDetailsPage extends StatefulWidget {
  final Client client;

  const ClientDetailsPage({Key? key, required this.client}) : super(key: key);

  @override
  State<ClientDetailsPage> createState() => _ClientDetailsPageState();
}

class _ClientDetailsPageState extends State<ClientDetailsPage> {
  final _api = FratheliApiService();

  List<Order> _orders = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final allOrders = await _api.fetchOrders();

      // Filtra apenas os pedidos desse cliente
      final list = allOrders.where((o) => o.clientId == widget.client.id).toList();

      setState(() {
        _orders = list;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String _formatCurrency(double v) {
    return 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.client;

    final address = [
      c.address.street,
      c.address.number,
      c.address.neighborhood,
      c.address.city,
      c.address.state,
      c.address.cep,
    ].where((s) => s.isNotEmpty).join(', ');

    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ----------------------------------------------------------
            // CABEÇALHO — DADOS DO CLIENTE
            // ----------------------------------------------------------
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: Text(c.name.isNotEmpty ? c.name[0] : '?'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          if (c.phone.isNotEmpty) Text(c.phone),
                          if (address.isNotEmpty)
                            Text(address, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ----------------------------------------------------------
            // TÍTULO — Histórico de Pedidos
            // ----------------------------------------------------------
            const Text(
              'Histórico de pedidos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              )),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Erro ao carregar pedidos:\n$_error'),
              ),

            if (!_loading && _orders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhum pedido encontrado para este cliente.'),
              ),

            // ----------------------------------------------------------
            // LISTA DE PEDIDOS DO CLIENTE
            // ----------------------------------------------------------
            ..._orders.map((order) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Pedido ${order.id}'),
                subtitle: Text('Total: ${_formatCurrency(order.total)} • ${order.paymentStatus}'),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
