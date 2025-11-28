import 'package:flutter/material.dart';
import '../controllers/pricing_controller.dart';
import 'widgets/cost_item_tile.dart';

class PricingFormPage extends StatefulWidget {
  final PricingController controller;

  const PricingFormPage({Key? key, required this.controller}) : super(key: key);

  @override
  State<PricingFormPage> createState() => _PricingFormPageState();
}

class _PricingFormPageState extends State<PricingFormPage> {
  final _formKey = GlobalKey<FormState>();

  double _parseNumber(String value) {
    final cleaned = value.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final model = widget.controller.model;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Precificação de Café'),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dados gerais
                  TextFormField(
                    initialValue: model.productName,
                    decoration: const InputDecoration(
                      labelText: 'Nome do produto (ex: Mel de Bugia)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: widget.controller.setProductName,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: model.markupPercent.toStringAsFixed(0),
                    decoration: const InputDecoration(
                      labelText: 'Margem / Markup desejado (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) {
                      widget.controller
                          .setMarkupPercent(_parseNumber(value));
                    },
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Custos por kg',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  // Lista de itens de custo
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: model.items.length,
                    itemBuilder: (context, index) {
                      final item = model.items[index];
                      return CostItemTile(
                        item: item,
                        index: index,
                        onChanged: (value) {
                          widget.controller.updateItemCost(index, value);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  Divider(color: Colors.grey[400]),
                  const SizedBox(height: 8),

                  // Resumo financeiro
                  Text(
                    'Resumo da precificação (por kg de café torrado)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  _buildSummaryRow(
                    'Total de custo (R\$/kg)',
                    model.totalCostPerKg,
                  ),
                  _buildSummaryRow(
                    'Preço final (com margem) – R\$/kg',
                    model.finalPricePerKg,
                    highlight: true,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Preço de venda (250g)',
                    model.price250g,
                    prefix: 'R\$ ',
                  ),
                  _buildSummaryRow(
                    'Preço de venda (1kg)',
                    model.finalPricePerKg,
                    prefix: 'R\$ ',
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Lucro líquido (R\$/kg)',
                    model.profitPerKg,
                  ),
                  _buildSummaryRow(
                    'Margem líquida (%)',
                    model.profitMargin * 100,
                    suffix: '%',
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Esses valores são baseados na sua planilha Bugia/Tiúba/Arara.\n'
                          'Depois podemos evoluir para salvar lotes, históricos e relatórios.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(
      String label,
      double value, {
        String prefix = 'R\$ ',
        String suffix = '',
        bool highlight = false,
      }) {
    final textStyle = highlight
        ? const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    )
        : const TextStyle(fontSize: 15);

    final formatted = value.toStringAsFixed(2).replaceAll('.', ',');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            prefix == 'R\$ ' && suffix.isEmpty
                ? '$prefix$formatted'
                : '$prefix$formatted$suffix',
            style: textStyle,
          ),
        ],
      ),
    );
  }
}
