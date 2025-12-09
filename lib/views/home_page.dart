import 'package:flutter/material.dart';
import 'package:my_coffee_app/views/roast_page.dart';
import 'package:my_coffee_app/views/sales_clients_page.dart';
import 'package:my_coffee_app/views/stock_page.dart';
import '../controllers/pricing_controller.dart';
import 'catalog_products_page.dart';
import 'pricing_list_page.dart';

class HomePage extends StatelessWidget {
  final PricingController controller;

  const HomePage({
    Key? key,
    required this.controller,
  }) : super(key: key);

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Módulo em desenvolvimento 👷‍♂️☕'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900; // web / tablet landscape

    // define quantas colunas no grid
    int crossAxisCount;
    if (size.width >= 1100) {
      crossAxisCount = 4;
    } else if (size.width >= 900) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F5F0),
        foregroundColor: const Color(0xFF2D2213),
        titleTextStyle: theme.textTheme.titleMedium?.copyWith(
          color: const Color(0xFF2D2213),
          fontWeight: FontWeight.w600,
        ),
        title: const Text('Gestão de Café'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 32 : 16,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------------------------------------------------
            // CABEÇALHO / HERO
            // -----------------------------------------------------------------
            Text(
              'Painel principal',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D2213),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Acompanhe seu café do plantio ao cliente final em um só lugar.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),

            // chips de contexto
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _ContextChip(label: 'Produção'),
                _ContextChip(label: 'Estoque'),
                _ContextChip(label: 'Vendas & Clientes'),
                _ContextChip(label: 'Precificação'),
              ],
            ),

            const SizedBox(height: 24),

            // -----------------------------------------------------------------
            // RESUMO SIMPLES (PLACEHOLDER)
            // -----------------------------------------------------------------
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.insights,
                        size: 30,
                        color: Color(0xFF8B6B2C),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Em breve você verá aqui gráficos de custos, margens, lotes em andamento e resultados do mês.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // -----------------------------------------------------------------
            // TÍTULO MÓDULOS
            // -----------------------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Módulos de gestão',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D2213),
                  ),
                ),
                Text(
                  'Toque para acessar',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // -----------------------------------------------------------------
            // GRID DE MÓDULOS
            // -----------------------------------------------------------------
            GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isWide ? 1.1 : 0.9,
              children: [
                // PLANTIO & TALHÕES
                _ModuleCard(
                  icon: Icons.agriculture,
                  title: 'Plantio & Talhões',
                  subtitle: 'Espaçamento, talhões, variedades',
                  statusLabel: 'Em breve',
                  onTap: () => _showComingSoon(context),
                ),

                // PÓS-COLHEITA
                _ModuleCard(
                  icon: Icons.grass,
                  title: 'Pós-colheita',
                  subtitle: 'Lavagem, terreiro, secagem',
                  statusLabel: 'Em breve',
                  onTap: () => _showComingSoon(context),
                ),

                // TORRA & LOTES
                _ModuleCard(
                  icon: Icons.local_fire_department,
                  title: 'Torra & Lotes',
                  subtitle: 'Transforme café verde em torrado',
                  highlight: true,
                  statusLabel: 'Ativo',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RoastPage(),
                      ),
                    );
                  },
                ),

                // ESTOQUE & ARMAZÉM
                _ModuleCard(
                  icon: Icons.inventory_2,
                  title: 'Estoque & Armazém',
                  subtitle: 'Sacas, big bags, controle',
                  highlight: true,
                  statusLabel: 'Ativo',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StockPage(),
                      ),
                    );
                  },
                ),

                // VENDAS & CLIENTES
                _ModuleCard(
                  icon: Icons.point_of_sale,
                  title: 'Vendas & Clientes',
                  subtitle: 'Pedidos, canais, fidelização',
                  highlight: true,
                  statusLabel: 'Ativo',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SalesClientsPage(pricingController: controller),
                      ),
                    );
                  },
                ),

                // PRECIFICAÇÃO
                _ModuleCard(
                  icon: Icons.calculate,
                  title: 'Precificação de Café',
                  subtitle: 'Custos, margens e preços de venda',
                  highlight: true,
                  statusLabel: 'Ativo',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PricingListPage(controller: controller),
                      ),
                    );
                  },
                ),

                // CATÁLOGO DE PRODUTOS
                _ModuleCard(
                  icon: Icons.storefront,
                  title: 'Catálogo de Produtos',
                  subtitle: 'Controlar produtos visíveis no site',
                  highlight: true,
                  statusLabel: 'Ativo',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CatalogProductsPage(),
                      ),
                    );
                  },
                ),

                // INSUMOS
                _ModuleCard(
                  icon: Icons.shopping_bag,
                  title: 'Insumos',
                  subtitle: 'Registro de insumos',
                  statusLabel: 'Em breve',
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WIDGETS AUXILIARES
// ---------------------------------------------------------------------------

class _ContextChip extends StatelessWidget {
  final String label;

  const _ContextChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: const Color(0xFFEEE3C7),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF3A2A16),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;
  final String statusLabel;

  const _ModuleCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
    this.statusLabel = 'Em breve',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final borderColor = highlight
        ? const Color(0xFFD4AF37)
        : Colors.grey.shade300;

    final statusBg = highlight
        ? const Color(0xFFD4AF37).withOpacity(0.15)
        : Colors.grey.shade200;

    final statusTextColor = highlight
        ? const Color(0xFF5A4318)
        : Colors.grey.shade700;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: borderColor,
            width: highlight ? 1.4 : 1,
          ),
        ),
        elevation: highlight ? 4 : 2,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // topo: ícone + status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: highlight
                          ? const Color(0xFFD4AF37).withOpacity(0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: highlight
                          ? const Color(0xFF8B6B2C)
                          : Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusTextColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // título
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D2213),
                ),
              ),

              const SizedBox(height: 4),

              // subtítulo
              Expanded(
                child: Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
