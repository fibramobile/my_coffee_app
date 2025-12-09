import 'package:flutter/material.dart';
import '../models/order.dart';

class OrderDetailsPage extends StatelessWidget {
  final Order order;

  const OrderDetailsPage({Key? key, required this.order}) : super(key: key);

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAGO':
        return Colors.green.shade700;
      case 'CANCELADO':
        return Colors.red.shade600;
      default:
        return Colors.orange.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = order.client;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido ${order.id}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // STATUS + INFO GERAL
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo do pedido',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(order.paymentStatus)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          order.paymentStatus,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(order.paymentStatus),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatCurrency(order.total),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Criado em: ${_formatDate(order.createdAt)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[700]),
                  ),
                  if (order.paymentProvider.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Pagamento: ${order.paymentProvider}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[700]),
                    ),
                    if (order.freightService != null && order.freightService!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Entrega: ${order.freightService}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (order.freightDeadline != null &&
                          order.freightDeadline!.isNotEmpty)
                        Text(
                          'Prazo: ${order.freightDeadline}',
                          style: const TextStyle(fontSize: 13),
                        ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // CLIENTE
          if (client != null)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cliente',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      client.name.isEmpty ? '(sem nome)' : client.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    if (client.cpf.isNotEmpty)
                      Text('CPF: ${client.cpf}',
                          style: const TextStyle(fontSize: 13)),
                    if (client.phone.isNotEmpty)
                      Text('Telefone: ${client.phone}',
                          style: const TextStyle(fontSize: 13)),
                    if (client.email.isNotEmpty)
                      Text('E-mail: ${client.email}',
                          style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(
                      'Endereço de entrega',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        client.address.street,
                        client.address.neighborhood,
                        client.address.city,
                        client.address.state,
                        client.address.cep,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          if (client == null) ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Cliente não encontrado na lista local.\n'
                      'Verifique se o arquivo clients.json está atualizado.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ITENS
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Itens do pedido',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map((it) {
                    final totalItem = it.qty * it.unitPrice;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  it.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'SKU: ${it.sku} · ${it.qty}x ${_formatCurrency(it.unitPrice)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatCurrency(totalItem),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const Divider(height: 24),
                  _totalsRow('Subtotal', _formatCurrency(order.subtotal)),
                  _totalsRow(
                    'Frete',
                    order.shipping > 0
                        ? _formatCurrency(order.shipping)
                        : 'R\$ 0,00',
                  ),
                  const SizedBox(height: 4),
                  _totalsRow(
                    'Total',
                    _formatCurrency(order.total),
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalsRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
