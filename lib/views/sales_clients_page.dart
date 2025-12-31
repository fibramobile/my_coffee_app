import 'package:flutter/material.dart';

import '../controllers/pricing_controller.dart';
import '../models/order.dart';
import '../models/client.dart';
import '../services/fratheli_api_service.dart';
import 'order_details_page.dart';
import 'client_details_page.dart';

class SalesClientsPage extends StatefulWidget {
  final PricingController pricingController;

  const SalesClientsPage({
    Key? key,
    required this.pricingController,
  }) : super(key: key);

  @override
  State<SalesClientsPage> createState() => _SalesClientsPageState();
}

class _SalesClientsPageState extends State<SalesClientsPage>
    with SingleTickerProviderStateMixin {
  // 👉 agora o widget existe aqui dentro
  PricingController get _pricingController => widget.pricingController;

  late final FratheliApiService _api;


  bool _loadingOrders = false;
  bool _loadingClients = false;
  String? _errorOrders;
  String? _errorClients;

  List<Order> _orders = [];
  List<Client> _clients = [];

  // 🔎 Busca de clientes
  final TextEditingController _clientSearchController = TextEditingController();
  List<Client> _filteredClients = [];

  // 'ALL' = sem filtro, mostra todos
  String _shippingFilter = 'ALL';

  List<Order> get _filteredOrders {
    if (_shippingFilter == 'ALL') return _orders;
    return _orders.where((o) {
      return o.shippingStatus.toUpperCase() == _shippingFilter;
    }).toList();
  }

  Color _shippingStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'AGUARDANDO_PAGAMENTO':
        return Colors.orange.shade700;
      case 'EM_SEPARACAO':
        return Colors.blue.shade700;
      case 'ENVIADO':
        return Colors.purple.shade700;
      case 'ENTREGUE':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _shippingStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'AGUARDANDO_PAGAMENTO':
        return 'Aguardando pagto';
      case 'EM_SEPARACAO':
        return 'Em separação';
      case 'ENVIADO':
        return 'Enviado';
      case 'ENTREGUE':
        return 'Entregue';
      default:
        return status;
    }
  }

  Color _moneyColor(double value) {
    if (value < 0) return Colors.red.shade700;
    if (value == 0) return Colors.grey.shade700;
    // positivo
    return Colors.green.shade700;
  }

  /// Para "atenção" quando está positivo, porém baixo
  Color _profitColor(double lucro, {double baixoAte = 20}) {
    if (lucro < 0) return Colors.red.shade700;
    if (lucro <= baixoAte) return Colors.orange.shade800;
    return Colors.green.shade700;
  }

  /// Se quiser usar em "pendente" etc.
  Color _warningColor(double value, {double altoAPartir = 200}) {
    if (value >= altoAPartir) return Colors.red.shade700;
    if (value > 0) return Colors.orange.shade800;
    return Colors.grey.shade700;
  }



  @override
  void initState() {
    super.initState();
    _api = FratheliApiService();

    // listener de busca
    _clientSearchController.addListener(() {
      _applyClientFilter(_clientSearchController.text);
    });

    _loadAll();
  }

  @override
  void dispose() {
    _clientSearchController.dispose();
    super.dispose();
  }

  double _calcularLucroLiquidoMes(List<Order> paidThisMonth) {
    double lucro = 0.0;

    for (final o in paidThisMonth) {
      final r = calcOrderProfit(
        order: o,
        pricingController: widget.pricingController, // ✅ aqui SIM existe widget
      );
      lucro += r.lucroLiquido;
    }

    return lucro;
  }



  Widget _buildShippingFilterChips() {
    final options = <String, String>{
      'ALL': 'Todos',
      'AGUARDANDO_PAGAMENTO': 'Aguardando pagto',
      'EM_SEPARACAO': 'Em separação',
      'ENVIADO': 'Enviado',
      'ENTREGUE': 'Entregue',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: options.entries.map((e) {
          final isSelected = _shippingFilter == e.key;
          final color = e.key == 'ALL'
              ? Colors.grey.shade700
              : _shippingStatusColor(e.key);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                e.value,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              selectedColor: color,
              backgroundColor: color.withOpacity(0.08),
              side: BorderSide(color: color.withOpacity(0.5)),
              onSelected: (_) {
                setState(() {
                  _shippingFilter = e.key;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _updateOrderShippingStatus(
      Order order, String newStatus) async {
    try {
      final updated = await _api.updateShippingStatus(
        orderId: order.id,
        shippingStatus: newStatus,
      );

      setState(() {
        final idx = _orders.indexWhere((o) => o.id == order.id);
        if (idx != -1) {
          _orders[idx] = updated;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status de envio atualizado para ${_shippingStatusLabel(newStatus)}.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar status de envio: $e')),
      );
    }
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

      setState(() {
        _orders = orders
        ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!)); // 👈 mais recente no topo
        _attachClientsToOrders(); // 👈 AGORA SIM, DEPOIS DE ATUALIZAR _orders
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
        // inicialmente, mostra todos
        _filteredClients = List.from(clients);
        _attachClientsToOrders(); // 👈 continua igual
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

  void _applyClientFilter(String query) {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      setState(() {
        _filteredClients = List.from(_clients);
      });
      return;
    }

    setState(() {
      _filteredClients = _clients.where((c) {
        final name = c.name.toLowerCase();
        final phone = c.phone.toLowerCase();

        // tirar caracteres não numéricos do telefone
        final phoneDigits = c.phone.replaceAll(RegExp(r'\D'), '');
        final qDigits = q.replaceAll(RegExp(r'\D'), '');

        final matchName = name.contains(q);
        final matchPhone =
            phone.contains(q) || (qDigits.isNotEmpty && phoneDigits.contains(qDigits));

        return matchName || matchPhone;
      }).toList();
    });
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

  void _attachClientsToOrders() {
    if (_clients.isEmpty || _orders.isEmpty) return;

    final mapClients = {for (final c in _clients) c.id: c};

    for (final o in _orders) {
      o.client = mapClients[o.clientId];
    }
  }

  String? extractUfFromAddress(String address) {
    const ufs = [
      'AC','AL','AM','AP','BA','CE','DF','ES','GO','MA','MG','MS','MT',
      'PA','PB','PE','PI','PR','RJ','RN','RO','RR','RS','SC','SE','SP','TO',
    ];

    final upper = address.toUpperCase();

    for (final uf in ufs) {
      final regex = RegExp(r'\b$uf\b'); // casa a sigla "solta"
      if (regex.hasMatch(upper)) {
        return uf;
      }
    }
    return null;
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
  /*
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
  */
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

    // -------------------------------
    // PEDIDOS PAGOS NO MÊS
    // -------------------------------
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

    final lucroLiquidoMes = _calcularLucroLiquidoMes(paidThisMonth);

    // ✅ AQUI ESTÁ A VARIÁVEL QUE ESTAVA FALTANDO
    final margemLiquidaMesPct = totalSoldThisMonth == 0
        ? 0.0
        : (lucroLiquidoMes / totalSoldThisMonth) * 100.0;

    // -------------------------------
    // PRODUTOS x FRETE (PAGOS)
    // -------------------------------
    double totalProdutosMes = 0.0;
    double totalFreteMes = 0.0;

    for (final o in paidThisMonth) {
      final totalItens = o.items.fold<double>(
        0.0,
            (sum, item) => sum + (item.unitPrice * item.qty),
      );
      totalProdutosMes += totalItens;
      totalFreteMes += o.shipping;
    }

    // -------------------------------
    // PENDENTES
    // -------------------------------
    final pendingOrders = _orders.where((o) {
      final s = o.paymentStatus.toUpperCase();
      return s != 'PAGO' && s != 'CANCELADO';
    }).toList();

    final totalPending = pendingOrders.fold<double>(
      0.0,
          (sum, o) => sum + o.total,
    );

    // -------------------------------
    // TICKET MÉDIO
    // -------------------------------
    final ticketMedio = paidThisMonth.isEmpty
        ? 0.0
        : totalSoldThisMonth / paidThisMonth.length;

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // ===================================================
          // CARD RESUMO DO MÊS
          // ===================================================
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

                  // ✅ CÁLCULOS (margem real sem frete)
                  Builder(
                    builder: (_) {
                      final double receitaProdutosMes = totalProdutosMes; // (PAGO) só produtos
                      final double margemLiquidaMesPct = receitaProdutosMes <= 0
                          ? 0
                          : (lucroLiquidoMes / receitaProdutosMes) * 100;

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 600;

                          if (isNarrow) {
                            // MOBILE
                            return Column(
                              children: [
                                _DashboardNumber(
                                  label: 'Total vendido (PAGO)',
                                  value: _formatCurrency(totalSoldThisMonth),
                                  icon: Icons.attach_money,
                                  valueColor: Colors.green.shade800,
                                  badgeText: paidThisMonth.isEmpty
                                      ? 'Sem vendas'
                                      : '${paidThisMonth.length} pedidos',
                                  badgeColor: Colors.green.shade700,
                                ),
                                const SizedBox(height: 12),

                                _DashboardNumber(
                                  label: 'Total pendente',
                                  value: _formatCurrency(totalPending),
                                  icon: Icons.hourglass_top,
                                  valueColor: _warningColor(totalPending, altoAPartir: 300),
                                  badgeColor: _warningColor(totalPending, altoAPartir: 300),
                                  badgeText: pendingOrders.isEmpty
                                      ? 'OK'
                                      : '${pendingOrders.length} pendentes',
                                ),
                                const SizedBox(height: 12),

                                _DashboardNumber(
                                  label: 'Ticket médio (mês)',
                                  value: _formatCurrency(ticketMedio),
                                  icon: Icons.analytics_outlined,
                                  valueColor: const Color(0xFF2D2213),
                                ),
                                const SizedBox(height: 12),

                                _DashboardNumber(
                                  label: 'Lucro líquido (mês)',
                                  value: _formatCurrency(lucroLiquidoMes),
                                  icon: Icons.trending_up,
                                  valueColor: _profitColor(lucroLiquidoMes, baixoAte: 30),
                                  badgeText: lucroLiquidoMes < 0
                                      ? 'Prejuízo'
                                      : (lucroLiquidoMes <= 30 ? 'Atenção' : 'Saudável'),
                                  badgeColor: _profitColor(lucroLiquidoMes, baixoAte: 30),
                                ),
                                const SizedBox(height: 12),

                                // ✅ MARGEM REAL (sem frete)
                                _DashboardNumber(
                                  label: 'Margem líquida (mês)',
                                  value:
                                  '${margemLiquidaMesPct.toStringAsFixed(1).replaceAll('.', ',')}%',
                                  icon: Icons.percent,
                                  valueColor: margemLiquidaMesPct < 8
                                      ? Colors.red.shade700
                                      : (margemLiquidaMesPct < 15
                                      ? Colors.orange.shade800
                                      : Colors.green.shade700),
                                  badgeText: margemLiquidaMesPct < 8
                                      ? 'Baixa'
                                      : (margemLiquidaMesPct < 15 ? 'Boa' : 'Excelente'),
                                  badgeColor: margemLiquidaMesPct < 8
                                      ? Colors.red.shade700
                                      : (margemLiquidaMesPct < 15
                                      ? Colors.orange.shade800
                                      : Colors.green.shade700),
                                ),
                              ],
                            );
                          }

                          // DESKTOP
                          return Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              _DashboardNumber(
                                label: 'Total vendido (PAGO)',
                                value: _formatCurrency(totalSoldThisMonth),
                                icon: Icons.attach_money,
                                valueColor: Colors.green.shade800,
                              ),
                              _DashboardNumber(
                                label: 'Total pendente',
                                value: _formatCurrency(totalPending),
                                icon: Icons.hourglass_top,
                                valueColor: _warningColor(totalPending, altoAPartir: 300),
                              ),
                              _DashboardNumber(
                                label: 'Ticket médio (mês)',
                                value: _formatCurrency(ticketMedio),
                                icon: Icons.analytics_outlined,
                              ),
                              _DashboardNumber(
                                label: 'Lucro líquido (mês)',
                                value: _formatCurrency(lucroLiquidoMes),
                                icon: Icons.trending_up,
                                valueColor: _profitColor(lucroLiquidoMes, baixoAte: 30),
                              ),

                              // ✅ MARGEM REAL (sem frete)
                              _DashboardNumber(
                                label: 'Margem líquida (mês)',
                                value:
                                '${margemLiquidaMesPct.toStringAsFixed(1).replaceAll('.', ',')}%',
                                icon: Icons.percent,
                                valueColor: margemLiquidaMesPct < 8
                                    ? Colors.red.shade700
                                    : (margemLiquidaMesPct < 15
                                    ? Colors.orange.shade800
                                    : Colors.green.shade700),
                                badgeText: margemLiquidaMesPct < 8
                                    ? 'Baixa'
                                    : (margemLiquidaMesPct < 15 ? 'Boa' : 'Excelente'),
                                badgeColor: margemLiquidaMesPct < 8
                                    ? Colors.red.shade700
                                    : (margemLiquidaMesPct < 15
                                    ? Colors.orange.shade800
                                    : Colors.green.shade700),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Quebra Produtos x Frete (ambos informativos)
                  Row(
                    children: [
                      Expanded(
                        child: _DashboardNumber(
                          label: 'Produtos (PAGO)',
                          value: _formatCurrency(totalProdutosMes),
                          icon: Icons.inventory_2_outlined,
                          valueColor: const Color(0xFF2D2213),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DashboardNumber(
                          label: 'Frete (PAGO pelo cliente)',
                          value: _formatCurrency(totalFreteMes),
                          icon: Icons.local_shipping_outlined,
                          valueColor: Colors.blueGrey.shade700,
                        ),
                      ),
                    ],
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
  /*
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
  */

  Future<void> _confirmAndDeleteOrder(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Excluir pedido?'),
          content: Text(
            'Tem certeza que deseja excluir o pedido ${order.id}?\n'
                'Essa ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Excluir',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      // exclui no backend
      await _api.deleteOrder(order.id);

      // remove da lista local
      setState(() {
        _orders.removeWhere((o) => o.id == order.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido excluído com sucesso.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir pedido: $e')),
      );
    }
  }

/*
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

          final pagamentoPago =
              order.paymentStatus.toUpperCase() == 'PAGO';

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

                    // LADO DIREITO: total + status + ações
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 220,
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

                          // Status de pagamento
                          // Status de pagamento (clicável para alternar)
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () async {
                              final atual = order.paymentStatus.toUpperCase();

                              // Se já está PAGO, volta para AGUARDANDO_PAGAMENTO
                              // Se não está PAGO, marca como PAGO
                              final novoStatus =
                              (atual == 'PAGO') ? 'AGUARDANDO_PAGAMENTO' : 'PAGO';

                              try {
                                final updated = await _api.updatePaymentStatus(
                                  orderId: order.id,
                                  paymentStatus: novoStatus,
                                );

                                setState(() {
                                  final idx =
                                  _orders.indexWhere((o) => o.id == order.id);
                                  if (idx != -1) {
                                    _orders[idx] = updated;
                                  }
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      novoStatus == 'PAGO'
                                          ? 'Pagamento marcado como PAGO.'
                                          : 'Pagamento voltou para Aguardando pagamento.',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro ao atualizar pagamento: $e'),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(order.paymentStatus)
                                    .withOpacity(0.12),
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
                          ),


                          const SizedBox(height: 6),

                          // NOVO: Status de envio + menu de alteração
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _shippingStatusColor(
                                      order.shippingStatus)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _shippingStatusColor(
                                            order.shippingStatus),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _shippingStatusLabel(
                                          order.shippingStatus),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _shippingStatusColor(
                                            order.shippingStatus),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 4),

                              // Menu para alterar status de envio
                              PopupMenuButton<String>(
                                tooltip: 'Opções do pedido',
                                onSelected: (value) async {
                                  if (value == '_DELETE') {
                                    await _confirmAndDeleteOrder(order);
                                  } else {
                                    await _updateOrderShippingStatus(order, value);
                                  }
                                },
                                itemBuilder: (context) {
                                  final List<PopupMenuEntry<String>> items = [];

                                  // Opções de status de envio
                               //  if (!pagamentoPago) {
                                    items.add(
                                      const PopupMenuItem(
                                        value: 'AGUARDANDO_PAGAMENTO',
                                        child: Text('Aguardando pagamento'),
                                      ),
                                    );
                                 // } else {
                                    items.addAll(const [
                                      PopupMenuItem(
                                        value: 'EM_SEPARACAO',
                                        child: Text('Em separação'),
                                      ),
                                      PopupMenuItem(
                                        value: 'ENVIADO',
                                        child: Text('Enviado'),
                                      ),
                                      PopupMenuItem(
                                        value: 'ENTREGUE',
                                        child: Text('Entregue'),
                                      ),
                                    ]);
                                //  }

                                  // 👉 Excluir só se estiver aguardando pagamento (pedido de teste / pendente)
                                 // if (isPendente) {
                                    items.add(const PopupMenuDivider());
                                    items.add(
                                      const PopupMenuItem(
                                        value: '_DELETE',
                                        child: Text(
                                          'Excluir pedido',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    );
                               //   }

                                  return items;
                                },
                                icon: const Icon(
                                  Icons.more_vert,
                                  size: 18,
                                ),
                              ),



                            ],
                          ),


                          // Botão "Marcar como pago"
                          if (!pagamentoPago)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 120),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                  const Color(0xFF2D2213),
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

                                    // 👉 Aqui assumimos que o backend já
                                    // atualiza shippingStatus para EM_SEPARACAO
                                    // ou o fromJson faz esse fallback.
                                    setState(() {
                                      final idx = _orders.indexWhere(
                                              (element) =>
                                          element.id == order.id);
                                      if (idx != -1) {
                                        _orders[idx] = updated;
                                      }
                                    });

                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Pagamento marcado como PAGO.'),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
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
  */
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

    // 👉 usa a lista filtrada
    final orders = _filteredOrders;

    return SafeArea(
      bottom: true,
      child: Column(
        children: [
          // barra de filtros por status de envio
          _buildShippingFilterChips(),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOrders,
              child: orders.isEmpty
                  ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('Nenhum pedido com esse status.')),
                ],
              )
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  0,
                  8,
                  0,
                  24, // 👈 espaço extra no rodapé da lista
                ),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final clientName = order.client?.name ?? order.clientId;
                  final itemsDesc =
                      '${order.totalItems} ${order.totalItems == 1 ? 'item' : 'itens'}';

                  final pagamentoPago =
                      order.paymentStatus.toUpperCase() == 'PAGO';
                  final isPendente = order.paymentStatus.toUpperCase() ==
                      'AGUARDANDO_PAGAMENTO';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 1,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      /*
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                OrderDetailsPage(order: order),
                          ),
                        );
                      },
                      */
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailsPage(order: order),
                          ),
                        );
                      },

                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LADO ESQUERDO
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
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

                            // LADO DIREITO
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 220,
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
                                  // FRETE — transportadora + prazo
                                  if (order.freightService != null && order.freightService!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            order.freightService!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          if (order.freightDeadline != null && order.freightDeadline!.isNotEmpty)
                                            Text(
                                              'Prazo: ${order.freightDeadline}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.black45,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

/*
                                  // STATUS PAGAMENTO (clicável)
                                  InkWell(
                                    borderRadius:
                                    BorderRadius.circular(999),
                                    onTap: () async {
                                      final atual = order.paymentStatus
                                          .toUpperCase();

                                      final novoStatus = (atual == 'PAGO')
                                          ? 'AGUARDANDO_PAGAMENTO'
                                          : 'PAGO';

                                      try {
                                        final updated =
                                        await _api.updatePaymentStatus(
                                          orderId: order.id,
                                          paymentStatus: novoStatus,
                                        );

                                        setState(() {
                                          final idx = _orders.indexWhere(
                                                  (o) => o.id == order.id);
                                          if (idx != -1) {
                                            _orders[idx] = updated;
                                          }
                                        });

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              novoStatus == 'PAGO'
                                                  ? 'Pagamento marcado como PAGO.'
                                                  : 'Pagamento voltou para Aguardando pagamento.',
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Erro ao atualizar pagamento: $e'),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                        _statusColor(order.paymentStatus)
                                            .withOpacity(0.12),
                                        borderRadius:
                                        BorderRadius.circular(999),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: _statusColor(
                                                  order.paymentStatus),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _statusLabel(
                                                order.paymentStatus),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: _statusColor(
                                                  order.paymentStatus),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
*/
                                  // STATUS PAGAMENTO (clicável)
                                  InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: () async {
                                      await _confirmTogglePaymentStatus(order);
                                    },

                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _statusColor(order.paymentStatus).withOpacity(0.12),
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
                                  ),


                                  const SizedBox(height: 6),

                                  // STATUS ENVIO + MENU
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _shippingStatusColor(
                                              order.shippingStatus)
                                              .withOpacity(0.12),
                                          borderRadius:
                                          BorderRadius.circular(999),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: _shippingStatusColor(
                                                    order.shippingStatus),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _shippingStatusLabel(
                                                  order.shippingStatus),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                _shippingStatusColor(
                                                    order
                                                        .shippingStatus),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      PopupMenuButton<String>(
                                        tooltip: 'Opções do pedido',
                                        onSelected: (value) async {
                                          if (value == '_DELETE') {
                                            await _confirmAndDeleteOrder(
                                                order);
                                          } else {
                                            await _updateOrderShippingStatus(
                                                order, value);
                                          }
                                        },
                                        itemBuilder: (context) {
                                          final List<
                                              PopupMenuEntry<String>> items =
                                          [];

                                          items.add(
                                            const PopupMenuItem(
                                              value:
                                              'AGUARDANDO_PAGAMENTO',
                                              child: Text(
                                                  'Aguardando pagamento'),
                                            ),
                                          );
                                          items.addAll(const [
                                            PopupMenuItem(
                                              value: 'EM_SEPARACAO',
                                              child: Text('Em separação'),
                                            ),
                                            PopupMenuItem(
                                              value: 'ENVIADO',
                                              child: Text('Enviado'),
                                            ),
                                            PopupMenuItem(
                                              value: 'ENTREGUE',
                                              child: Text('Entregue'),
                                            ),
                                          ]);

                                          if (isPendente) {
                                            items.add(
                                                const PopupMenuDivider());
                                            items.add(
                                              const PopupMenuItem(
                                                value: '_DELETE',
                                                child: Text(
                                                  'Excluir pedido',
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            );
                                          }

                                          return items;
                                        },
                                        icon: const Icon(
                                          Icons.more_vert,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),



                                  // Botão "Marcar como pago"
                        /*
                                  if (!pagamentoPago)
                                    Padding(
                                      padding:
                                      const EdgeInsets.only(top: 4),
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                          const Color(0xFF2D2213),
                                          padding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          minimumSize: const Size(0, 0),
                                          tapTargetSize:
                                          MaterialTapTargetSize
                                              .shrinkWrap,
                                        ),
                                        onPressed: () async {
                                          try {
                                            final updated = await _api
                                                .updatePaymentStatus(
                                              orderId: order.id,
                                              paymentStatus: 'PAGO',
                                            );

                                            setState(() {
                                              final idx = _orders
                                                  .indexWhere((element) =>
                                              element.id ==
                                                  order.id);
                                              if (idx != -1) {
                                                _orders[idx] = updated;
                                              }
                                            });

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Pagamento marcado como PAGO.'),
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
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
                  */
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
            ),
          ),
        ],
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

    // se não tem nenhum cliente mesmo
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

    return Column(
      children: [
        // 🔎 Campo de busca
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _clientSearchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou telefone...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
            ),
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadClients,
            child: _filteredClients.isEmpty
                ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 80),
                Center(child: Text('Nenhum cliente corresponde à busca.')),
              ],
            )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _filteredClients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final c = _filteredClients[index];

                final cityState = [
                  c.address.city,
                  c.address.state,
                ].where((s) => s.isNotEmpty).join(' - ');

                final initials = c.name.trim().isNotEmpty
                    ? c.name
                    .trim()
                    .split(' ')
                    .take(2)
                    .map((e) => e[0])
                    .join()
                    : '?';

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
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
                      backgroundColor:
                      const Color(0xFFD4AF37).withOpacity(0.85),
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
          ),
        ),
      ],
    );
  }
/*
  Future<void> _confirmTogglePaymentStatus(Order order) async {
    final atual = order.paymentStatus.toUpperCase();
    final vaiPraPago = atual != 'PAGO';
    final novoStatus = vaiPraPago ? 'PAGO' : 'AGUARDANDO_PAGAMENTO';

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(vaiPraPago ? 'Confirmar pagamento' : 'Reabrir pagamento'),
        content: Text(
          vaiPraPago
              ? 'Deseja marcar o pedido ${order.id} como PAGO?'
              : 'Deseja voltar o pedido ${order.id} para AGUARDANDO PAGAMENTO?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    int extractGrams({required String sku, required String name}) {
      final s = '${sku.toUpperCase()} ${name.toUpperCase()}';

      // 250g, 500g etc
      final m = RegExp(r'(\d+)\s*G').firstMatch(s);
      if (m != null) return int.tryParse(m.group(1)!) ?? 250;

      if (s.contains('1KG') || s.contains('1000G')) return 1000;
      if (s.contains('500')) return 500;
      if (s.contains('250')) return 250;

      return 250; // fallback
    }

    double costUnitFromKg({required double costPerKg, required int grams}) {
      return costPerKg * (grams / 1000.0);
    }

    String money(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

    try {
      // ✅ se estiver indo para PAGO, calcula e manda custos congelados
      List<Map<String, dynamic>>? itemsCostPatch;

      if (novoStatus == 'PAGO') {
        itemsCostPatch = [];

        debugPrint('================= CONGELAR CUSTO (PAGO) =================');
        debugPrint('Pedido: ${order.id}');

        for (final item in order.items) {
          final pricing = _pricingController.getPricingForItem(
            sku: item.sku,
            name: item.name,
          );

          if (pricing == null) {
            debugPrint('⚠️ Sem precificação para sku="${item.sku}" | name="${item.name}"');
            continue;
          }

          final grams = extractGrams(sku: item.sku, name: item.name);
          final unitCost = costUnitFromKg(costPerKg: pricing.totalCostPerKg, grams: grams);

          itemsCostPatch.add({
            'sku': item.sku,
            'name': item.name,
            'gramsAtSale': grams,
            'unitCostAtSale': unitCost,
          });

          debugPrint('Item "${item.name}" | sku=${item.sku} | ${grams}g');
          debugPrint('  custo/kg = R\$ ${money(pricing.totalCostPerKg)}');
          debugPrint('  unitCostAtSale = R\$ ${money(unitCost)}');
        }

        debugPrint('==========================================================');
      }

      // ✅ chama backend salvando status + custos congelados (se PAGO)
      final updated = await _api.updatePaymentStatus(
        orderId: order.id,
        paymentStatus: novoStatus,
        itemsCostAtSale: itemsCostPatch, // <- NOVO
      );

      setState(() {
        final idx = _orders.indexWhere((o) => o.id == order.id);
        if (idx != -1) _orders[idx] = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            novoStatus == 'PAGO'
                ? 'Pagamento marcado como PAGO (custo congelado).'
                : 'Pagamento voltou para Aguardando pagamento.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar pagamento: $e')),
      );
    }
  }
*/
  Future<void> _confirmTogglePaymentStatus(Order order) async {
    final atual = order.paymentStatus.toUpperCase();
    final vaiPraPago = atual != 'PAGO';
    final novoStatus = vaiPraPago ? 'PAGO' : 'AGUARDANDO_PAGAMENTO';

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(vaiPraPago ? 'Confirmar pagamento' : 'Reabrir pagamento'),
        content: Text(
          vaiPraPago
              ? 'Deseja marcar o pedido ${order.id} como PAGO?'
              : 'Deseja voltar o pedido ${order.id} para AGUARDANDO PAGAMENTO?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // ==========================================================
      // ✅ CONGELAR CUSTOS APENAS AO IR PARA PAGO
      // ==========================================================
      List<Map<String, dynamic>>? itemsCostAtSale;

      if (novoStatus == 'PAGO') {
        itemsCostAtSale = [];

        debugPrint('================= CONGELAR CUSTO =================');
        debugPrint('Pedido: ${order.id}');

        for (final item in order.items) {
          final pricing = _pricingController.getPricingForItem(
            sku: item.sku,
            name: item.name,
          );

          if (pricing == null) {
            debugPrint(
              '⚠️ Sem precificação para sku="${item.sku}" | name="${item.name}"',
            );
            continue;
          }

          final grams = _extractGramsFromItemSafe(
            sku: item.sku,
            name: item.name,
          );

          final unitCostAtSale =
              pricing.totalCostPerKg * (grams / 1000.0);

          itemsCostAtSale.add({
            'sku': item.sku,
            'name': item.name,
            'gramsAtSale': grams,
            'unitCostAtSale': unitCostAtSale,
          });

          debugPrint(
            'Item ${item.name} | ${grams}g | custo/kg R\$ ${pricing.totalCostPerKg.toStringAsFixed(2)} | unitCostAtSale R\$ ${unitCostAtSale.toStringAsFixed(2)}',
          );
        }

        debugPrint('===============================================');
      }

      // ==========================================================
      // ✅ CHAMADA FINAL AO BACKEND
      // ==========================================================
      final updated = await _api.updatePaymentStatus(
        orderId: order.id,
        paymentStatus: novoStatus,
        itemsCostAtSale: itemsCostAtSale, // ✅ NOME CORRETO
      );

      setState(() {
        final idx = _orders.indexWhere((o) => o.id == order.id);
        if (idx != -1) _orders[idx] = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            novoStatus == 'PAGO'
                ? 'Pagamento marcado como PAGO (custos congelados).'
                : 'Pagamento voltou para Aguardando pagamento.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar pagamento: $e')),
      );
    }
  }


  ///=======================================================
/// CONGELA CUSTO DOS ITENS NO MOMENTO DO PAGAMENTO
/// =======================================================
  List<Map<String, dynamic>> _buildFrozenItemsPayload(Order order) {
    int extractGrams({required String sku, required String name}) {
      final s = '${sku.toUpperCase()} ${name.toUpperCase()}';

      final m = RegExp(r'(\d+)\s*G').firstMatch(s);
      if (m != null) return int.tryParse(m.group(1)!) ?? 250;

      if (s.contains('1KG') || s.contains('1000G')) return 1000;
      if (s.contains('500')) return 500;
      if (s.contains('250')) return 250;

      return 250;
    }

    double unitCostFromKg(double costPerKg, int grams) {
      return costPerKg * (grams / 1000.0);
    }

    final List<Map<String, dynamic>> out = [];

    debugPrint('================= CONGELAR CUSTOS =================');
    debugPrint('Pedido: ${order.id}');

    for (final item in order.items) {
      // 🔒 já congelado → mantém
      if (item.unitCostAtSale != null && item.gramsAtSale != null) {
        out.add(item.toJson());
        continue;
      }

      final pricing = widget.pricingController.getPricingForItem(
        sku: item.sku,
        name: item.name,
      );

      if (pricing == null) {
        debugPrint('⚠️ Sem precificação para ${item.name}');
        out.add(item.toJson());
        continue;
      }

      final grams = extractGrams(sku: item.sku, name: item.name);
      final unitCost = unitCostFromKg(pricing.totalCostPerKg, grams);

      debugPrint(
        'Item ${item.name} | ${grams}g | custo unit R\$ ${unitCost.toStringAsFixed(2)}',
      );

      out.add({
        ...item.toJson(),
        'gramsAtSale': grams,
        'unitCostAtSale': unitCost,
      });
    }

    debugPrint('===================================================');
    return out;
  }



}


class _OrderProfit {
  final double receitaProdutos;
  final double custoProdutos;
  final double lucroLiquido;
  final double margemPct;

  const _OrderProfit({
    required this.receitaProdutos,
    required this.custoProdutos,
    required this.lucroLiquido,
    required this.margemPct,
  });
}

int _extractGramsFromItemSafe({required String sku, required String name}) {
  final upSku = sku.toUpperCase();
  final upName = name.toUpperCase();

  // tenta "250g" / "500g" no texto
  final m = RegExp(r'(\d+)\s*G').firstMatch('$upSku $upName');
  if (m != null) {
    final g = int.tryParse(m.group(1) ?? '');
    if (g != null) return g;
  }

  if (upSku.contains('1KG') || upName.contains('1KG') || upSku.contains('1000') || upName.contains('1000')) return 1000;
  if (upSku.contains('500') || upName.contains('500')) return 500;
  if (upSku.contains('250') || upName.contains('250')) return 250;

  return 250; // fallback
}

double _unitCostFromCostPerKg({required double costPerKg, required int grams}) {
  return costPerKg * (grams / 1000.0);
}

_OrderProfit calcOrderProfit({
  required Order order,
  required PricingController pricingController,
}) {
  double receita = 0.0;
  double custo = 0.0;

  for (final item in order.items) {
    final pricing = pricingController.getPricingForItem(
      sku: item.sku,
      name: item.name,
    );

    if (pricing == null) continue;

    final grams = _extractGramsFromItemSafe(sku: item.sku, name: item.name);
    final unitCost = _unitCostFromCostPerKg(
      costPerKg: pricing.totalCostPerKg,
      grams: grams,
    );

    receita += item.unitPrice * item.qty;
    custo += unitCost * item.qty;
  }

  final lucro = receita - custo;
  final margem = receita <= 0 ? 0.0 : (lucro / receita) * 100.0;

  return _OrderProfit(
    receitaProdutos: receita,
    custoProdutos: custo,
    lucroLiquido: lucro,
    margemPct: margem,
  );
}





// ---------------------------------------------------------------------------
// Helpers internos
// ---------------------------------------------------------------------------

class _DashboardNumber extends StatelessWidget {
  final String label;
  final String value;

  /// NOVO
  final Color? valueColor;
  final IconData? icon;
  final String? badgeText;
  final Color? badgeColor;

  const _DashboardNumber({
    Key? key,
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
    this.badgeText,
    this.badgeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = valueColor ?? const Color(0xFF2D2213);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: Colors.black54),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (badgeText != null && badgeText!.isNotEmpty) ...[
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? c).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: (badgeColor ?? c).withOpacity(0.3)),
                  ),
                  child: Text(
                    badgeText!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: badgeColor ?? c,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ]
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: c,
              letterSpacing: -0.2,
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
