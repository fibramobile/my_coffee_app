import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/client.dart';
import '../services/fratheli_api_service.dart';
import 'order_details_page.dart';
import 'client_details_page.dart';

class SalesClientsPage extends StatefulWidget {
  const SalesClientsPage({Key? key}) : super(key: key);

  @override
  State<SalesClientsPage> createState() => _SalesClientsPageState();
}

class _SalesClientsPageState extends State<SalesClientsPage>
    with SingleTickerProviderStateMixin {
  late final FratheliApiService _api;

  bool _loadingOrders = false;
  bool _loadingClients = false;
  String? _errorOrders;
  String? _errorClients;

  List<Order> _orders = [];
  List<Client> _clients = [];

  @override
  void initState() {
    super.initState();
    _api = FratheliApiService();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadClients(),
      _loadOrders(),
    ]);
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loadingOrders = true;
      _errorOrders = null;
    });

    try {
      final orders = await _api.fetchOrders();

      // "join" em memória com clientes, se já tiver carregado
      final mapClients = {for (final c in _clients) c.id: c};

      for (final o in orders) {
        o.client = mapClients[o.clientId];
      }

      setState(() {
        _orders = orders;
      });
    } catch (e) {
      setState(() {
        _errorOrders = e.toString();
      });
    } finally {
      setState(() {
        _loadingOrders = false;
      });
    }
  }

  Future<void> _loadClients() async {
    setState(() {
      _loadingClients = true;
      _errorClients = null;
    });

    try {
      final clients = await _api.fetchClients();
      setState(() {
        _clients = clients;
      });
    } catch (e) {
      setState(() {
        _errorClients = e.toString();
      });
    } finally {
      setState(() {
        _loadingClients = false;
      });
    }
  }

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
        return Colors.orange.shade700; // AGUARDANDO_PAGAMENTO etc
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PAGO':
        return 'Pago';
      case 'CANCELADO':
        return 'Cancelado';
      case 'AGUARDANDO_PAGAMENTO':
        return 'Aguardando pagamento';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Dashboard + Pedidos + Clientes
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5F0),
         appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F5F0), // mesmo tom do fundo
        foregroundColor: const Color(0xFF2D2213), // texto/ícones em marrom escuro
        iconTheme: const IconThemeData(color: Color(0xFF2D2213)),
        titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFF2D2213),
          fontWeight: FontWeight.w600,
        ),
        title: const Text('Vendas & Clientes'),
        bottom: TabBar(
          indicatorColor: const Color(0xFFD4AF37),
          labelColor: const Color(0xFF2D2213),
          unselectedLabelColor: Colors.grey[600],
          tabs: const [
            Tab(icon: Icon(Icons.insights), text: 'Dashboard'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Pedidos'),
            Tab(icon: Icon(Icons.people), text: 'Clientes'),
          ],
        ),
      ),

      body: TabBarView(
          children: [
            _buildDashboardTab(),
            _buildOrdersTab(),
            _buildClientsTab(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DASHBOARD
  // ---------------------------------------------------------------------------
  Widget _buildDashboardTab() {
    if ((_loadingOrders || _loadingClients) &&
        _orders.isEmpty &&
        _clients.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorOrders != null && _orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Erro ao carregar dados de pedidos:\n$_errorOrders',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final now = DateTime.now();

    // Pedidos pagos no mês atual
    final paidThisMonth = _orders.where((o) {
      if (o.createdAt == null) return false;
      final s = o.paymentStatus.toUpperCase();
      return s == 'PAGO' &&
          o.createdAt!.year == now.year &&
          o.createdAt!.month == now.month;
    }).toList();

    final totalSoldThisMonth = paidThisMonth.fold<double>(
      0.0,
          (sum, o) => sum + o.total,
    );

    // Total pendente (tudo que não é PAGO / CANCELADO)
    final pendingOrders = _orders.where((o) {
      final s = o.paymentStatus.toUpperCase();
      return s != 'PAGO' && s != 'CANCELADO';
    }).toList();

    final totalPending = pendingOrders.fold<double>(
      0.0,
          (sum, o) => sum + o.total,
    );

    // Ticket médio (considerando só pedidos pagos NO MÊS)
    final ticketMedio = paidThisMonth.isEmpty
        ? 0.0
        : paidThisMonth.fold<double>(
      0.0,
          (sum, o) => sum + o.total,
    ) /
        paidThisMonth.length;

    // Pedidos por produto
    final Map<String, _ProductAgg> produtosAgg = {};
    for (final o in _orders) {
      for (final item in o.items) {
        final key = item.sku;
        final existing = produtosAgg[key];
        if (existing == null) {
          produtosAgg[key] = _ProductAgg(
            sku: item.sku,
            name: item.name,
            qty: item.qty,
            total: item.qty * item.unitPrice,
          );
        } else {
          existing.qty += item.qty;
          existing.total += item.qty * item.unitPrice;
        }
      }
    }

    final produtosList = produtosAgg.values.toList()
      ..sort((a, b) => b.qty.compareTo(a.qty));

    // Mapa de envios por UF
    final Map<String, int> enviosPorUf = {};
    for (final o in _orders) {
      final uf = o.client?.address.state.trim() ?? '';
      if (uf.isEmpty) continue;
      enviosPorUf[uf] = (enviosPorUf[uf] ?? 0) + 1;
    }

    final enviosList = enviosPorUf.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // RESUMO DO MÊS
          Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo do mês',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Referência: ${now.month.toString().padLeft(2, '0')}/${now.year}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // em telas estreitas, empilha
                      final isNarrow = constraints.maxWidth < 600;
                      if (isNarrow) {
                        return Column(
                          children: [
                            _DashboardNumber(
                              label: 'Total vendido (PAGO)',
                              value: _formatCurrency(totalSoldThisMonth),
                            ),
                            const SizedBox(height: 12),
                            _DashboardNumber(
                              label: 'Total pendente',
                              value: _formatCurrency(totalPending),
                            ),
                            const SizedBox(height: 12),
                            _DashboardNumber(
                              label: 'Ticket médio (mês)',
                              value: _formatCurrency(ticketMedio),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          _DashboardNumber(
                            label: 'Total vendido (PAGO)',
                            value: _formatCurrency(totalSoldThisMonth),
                          ),
                          const SizedBox(width: 16),
                          _DashboardNumber(
                            label: 'Total pendente',
                            value: _formatCurrency(totalPending),
                          ),
                          const SizedBox(width: 16),
                          _DashboardNumber(
                            label: 'Ticket médio (mês)',
                            value: _formatCurrency(ticketMedio),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // PEDIDOS POR PRODUTO
          Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedidos por produto',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (produtosList.isEmpty)
                    const Text(
                      'Nenhum pedido ainda para calcular produtos.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: produtosList.length,
                      separatorBuilder: (_, __) =>
                      const Divider(height: 12, thickness: 0.3),
                      itemBuilder: (context, index) {
                        final p = produtosList[index];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            p.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'SKU: ${p.sku}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${p.qty} ${p.qty == 1 ? 'unidade' : 'unidades'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatCurrency(p.total),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // MAPA DE ENVIOS (por UF)
          Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mapa de envios por UF',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (enviosList.isEmpty)
                    const Text(
                      'Ainda não há pedidos com UF informado.',
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: enviosList.map((e) {
                        return Chip(
                          backgroundColor:
                          const Color(0xFFEEE3C7).withOpacity(0.7),
                          label: Text(
                            '${e.key} · ${e.value} ${e.value == 1 ? 'pedido' : 'pedidos'}',
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PEDIDOS
  // ---------------------------------------------------------------------------
  Widget _buildOrdersTab() {
    if (_loadingOrders && _orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorOrders != null && _orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Erro ao carregar pedidos:\n$_errorOrders',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            Center(child: Text('Nenhum pedido encontrado ainda.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final order = _orders[index];
          final clientName = order.client?.name ?? order.clientId;
          final itemsDesc =
              '${order.totalItems} ${order.totalItems == 1 ? 'item' : 'itens'}';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailsPage(order: order),
                  ),
                );
              },
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LADO ESQUERDO: info do pedido / cliente
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Pedido ${order.id}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            clientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$itemsDesc · ${_formatDate(order.createdAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // LADO DIREITO: total + status + botão
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 180,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Total
                          Text(
                            _formatCurrency(order.total),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Chip de status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                              _statusColor(order.paymentStatus).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _statusColor(order.paymentStatus),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _statusLabel(order.paymentStatus),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _statusColor(order.paymentStatus),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Botão "Marcar como pago"
                          if (order.paymentStatus.toUpperCase() != 'PAGO')
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF2D2213),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () async {
                                  try {
                                    final updated =
                                    await _api.updatePaymentStatus(
                                      orderId: order.id,
                                      paymentStatus: 'PAGO',
                                    );

                                    setState(() {
                                      final idx = _orders.indexWhere(
                                              (element) => element.id == order.id);
                                      if (idx != -1) {
                                        _orders[idx] = updated;
                                      }
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                        Text('Pagamento marcado como PAGO.'),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Erro ao atualizar pagamento: $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text(
                                  'Marcar como pago',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CLIENTES
  // ---------------------------------------------------------------------------
  Widget _buildClientsTab() {
    if (_loadingClients && _clients.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorClients != null && _clients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Erro ao carregar clientes:\n$_errorClients',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_clients.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadClients,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            Center(child: Text('Nenhum cliente encontrado ainda.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClients,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _clients.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final c = _clients[index];

          final cityState = [
            c.address.city,
            c.address.state,
          ].where((s) => s.isNotEmpty).join(' - ');

          final initials = c.name.trim().isNotEmpty
              ? c.name.trim().split(' ').take(2).map((e) => e[0]).join()
              : '?';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 1,
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClientDetailsPage(client: c),
                  ),
                );
              },

              leading: CircleAvatar(
                backgroundColor: const Color(0xFFD4AF37).withOpacity(0.85),
                child: Text(
                  initials.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(c.name.isEmpty ? '(sem nome)' : c.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (c.phone.isNotEmpty) Text(c.phone),
                  if (cityState.isNotEmpty)
                    Text(
                      cityState,
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers internos
// ---------------------------------------------------------------------------

class _DashboardNumber extends StatelessWidget {
  final String label;
  final String value;

  const _DashboardNumber({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductAgg {
  final String sku;
  final String name;
  int qty;
  double total;

  _ProductAgg({
    required this.sku,
    required this.name,
    required this.qty,
    required this.total,
  });
}
