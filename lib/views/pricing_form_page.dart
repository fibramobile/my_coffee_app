import 'package:flutter/material.dart';
import '../controllers/pricing_controller.dart';
import 'widgets/cost_item_tile.dart';

class PricingFormPage extends StatefulWidget {
  final PricingController controller;
  final int? editingIndex; // <--- NOVO

  const PricingFormPage({
    Key? key,
    required this.controller,
    this.editingIndex,
  }) : super(key: key);

  @override
  State<PricingFormPage> createState() => _PricingFormPageState();
}

class _PricingFormPageState extends State<PricingFormPage> {
  final _formKey = GlobalKey<FormState>();


  @override
  void initState() {
    super.initState();

    // Se veio um índice de edição, carrega os dados desse item
    if (widget.editingIndex != null) {
      widget.controller.loadFromSaved(widget.editingIndex!);
    }
  }

  double _parseNumber(String value) {
    final cleaned = value.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }

  String _formatMoney(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  Color getMarginColor(double marginPercent) {
    if (marginPercent >= 40) {
      return Colors.blueAccent;        // Ideal
    } else if (marginPercent >= 30) {
      return Colors.green; // Boa
    } else {
      return Colors.yellow;    // Risco
    }
  }


  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final model = widget.controller.model;
        final saved = widget.controller.savedPricings;

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
                  // DADOS GERAIS
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

                  // ITENS DE CUSTO
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

                  // RESUMO
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
                  /*
                  _buildSummaryRow(
                    'Margem líquida (%)',
                    model.profitMargin * 100,
                    suffix: '%',
                  ),*/
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('Margem líquida (%)'),
                        ),
                        Text(
                          '${(model.profitMargin * 100).toStringAsFixed(2).replaceAll('.', ',')}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: getMarginColor(model.profitMargin * 100),
                          ),
                        ),
                      ],
                    ),
                  ),


                  const SizedBox(height: 16),

                  // BOTÃO SALVAR
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(
                        widget.editingIndex != null ? Icons.check : Icons.save,
                      ),
                      label: Text(
                        widget.editingIndex != null
                            ? 'Atualizar precificação'
                            : 'Salvar precificação',
                      ),
                      onPressed: () {
                        final isEditing = widget.editingIndex != null;

                        widget.controller.saveCurrentPricing(
                          indexToUpdate: widget.editingIndex,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEditing
                                  ? 'Precificação atualizada!'
                                  : 'Precificação salva!',
                            ),
                          ),
                        );

                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),



                  const SizedBox(height: 24),
                  Divider(color: Colors.grey[500]),
                  const SizedBox(height: 8),

                  // LISTA DE PRECIFICAÇÕES SALVAS
                  Text(
                    'Precificações salvas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  if (saved.isEmpty)
                    Text(
                      'Nenhuma precificação salva ainda.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    )
                  else
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: saved.length,
                      itemBuilder: (context, index) {
                        final p = saved[index];
                        final price250 = p.price250g;
                        return Card(
                          child: ListTile(
                            title: Text(p.productName),
                            subtitle: Text(
                              'Preço 250g: R\$ ${_formatMoney(price250)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    debugPrint(
                                        'Clicou em editar índice $index (${p.productName})');

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PricingFormPage(
                                          controller: widget.controller,
                                          editingIndex: index, // <--- ESSENCIAL
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () {
                                    widget.controller.removeSavedPricing(index);
                                  },
                                ),
                              ],
                            ),


                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),
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
