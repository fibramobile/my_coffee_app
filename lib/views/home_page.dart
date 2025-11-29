import 'package:flutter/material.dart';
import '../controllers/pricing_controller.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Café'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Text(
              'Painel principal',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Organize seu café do plantio ao cliente final.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),

            // Resumo / visão geral simples (placeholder por enquanto)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.insights, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Em breve: visão geral com gráficos de custos, margens e lotes.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Módulos de gestão',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            // Grid de módulos
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // PLANTIO & TALHÕES
                _ModuleCard(
                  icon: Icons.agriculture,
                  title: 'Plantio & Talhões',
                  subtitle: 'Espaçamento, talhões, variedades',
                  onTap: () => _showComingSoon(context),
                ),

                // PÓS-COLHEITA
                _ModuleCard(
                  icon: Icons.grass,
                  title: 'Pós-colheita',
                  subtitle: 'Lavagem, terreiro, secagem',
                  onTap: () => _showComingSoon(context),
                ),

                // TORRA & LOTES
                _ModuleCard(
                  icon: Icons.local_fire_department,
                  title: 'Torra & Lotes',
                  subtitle: 'Perfis de torra e microlotes',
                  onTap: () => _showComingSoon(context),
                ),

                // ESTOQUE & ARMAZÉM
                _ModuleCard(
                  icon: Icons.inventory_2,
                  title: 'Estoque & Armazém',
                  subtitle: 'Sacas, big bags, controle',
                  onTap: () => _showComingSoon(context),
                ),

                // VENDAS & CLIENTES
                _ModuleCard(
                  icon: Icons.point_of_sale,
                  title: 'Vendas & Clientes',
                  subtitle: 'Pedidos, canais, fidelização',
                  onTap: () => _showComingSoon(context),
                ),

                // 🔥 PRECIFICAÇÃO (FUNCIONAL)
                _ModuleCard(
                  icon: Icons.calculate,
                  title: 'Precificação de Café',
                  subtitle: 'Custos, margens e preços de venda',
                  highlight: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PricingListPage(controller: controller),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
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

  const _ModuleCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final borderColor = highlight
        ? const Color(0xFFD4AF37)
        : Colors.grey.shade200;

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
              Row(
                children: [
                  Icon(
                    icon,
                    size: 28,
                    color: highlight
                        ? const Color(0xFFD4AF37)
                        : Colors.grey[800],
                  ),
                  const Spacer(),
                  if (highlight)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Ativo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.brown[800],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Em breve',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
