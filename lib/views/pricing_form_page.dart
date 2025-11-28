import 'package:flutter/material.dart';
import '../controllers/pricing_controller.dart';
import 'widgets/cost_item_tile.dart';

class PricingFormPage extends StatefulWidget {
  final PricingController controller;
  final int? editingIndex;

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

    // Se veio um índice de edição, carregamos esses dados
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

  /// Define cor visual da margem líquida
  Color getMarginColor(double marginPercent) {
    if (marginPercent >= 40) {
      return Colors.green; // Ideal
    } else if (marginPercent >= 30) {
      return Colors.orange; // Boa
    } else {
      return Colors.red; // Risco
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
          // ❌ NÃO colocamos backgroundColor aqui, usamos o do Theme (claro)
          appBar: AppBar(
            title: const Text('Precificação de Café'),
            centerTitle: true,
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------------------------
                  // DADOS GERAIS
                  // -------------------------
                  Text(
                    "Dados gerais",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    initialValue: model.productName,
                    decoration: const InputDecoration(
                      labelText: 'Nome do produto (ex: Mel de Bugia)',
                      // ❌ sem border aqui; usa a do Theme
                    ),
                    onChanged: widget.controller.setProductName,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    initialValue: model.markupPercent.toStringAsFixed(0),
                    decoration: const InputDecoration(
                      labelText: 'Margem / Markup desejado (%)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) {
                      widget.controller
                          .setMarkupPercent(_parseNumber(value));
                    },
                  ),

                  const SizedBox(height: 24),

                  // -------------------------
                  // CUSTOS POR KG
                  // -------------------------
                  Text(
                    'Custos por kg',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),

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

                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 12),

                  // -------------------------
                  // RESUMO
                  // -------------------------
                  Text(
                    'Resumo da precificação (por kg de café torrado)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),

                  _buildSummaryRow(
                    'Total de custo (R\$/kg)',
                    model.totalCostPerKg,
                  ),
                  _buildSummaryRow(
                    'Preço final (com margem) – R\$/kg',
                    model.finalPricePerKg,
                    highlight: true,
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Preço de venda (250g)',
                    model.price250g,
                  ),
                  _buildSummaryRow(
                    'Preço de venda (1kg)',
                    model.finalPricePerKg,
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Lucro líquido (R\$/kg)',
                    model.profitPerKg,
                  ),

                  // MARGEM LÍQUIDA COLORIDA
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Margem líquida (%)',
                            style: TextStyle(fontSize: 15),
                          ),
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

                  const SizedBox(height: 24),

                  // -------------------------
                  // BOTÃO SALVAR / ATUALIZAR
                  // -------------------------
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

                  const SizedBox(height: 32),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 12),

                  // -------------------------
                  // LISTA DE PRECIFICAÇÕES
                  // -------------------------
                  Text(
                    'Precificações salvas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),

                  if (saved.isEmpty)
                    Text(
                      'Nenhuma precificação salva ainda.',
                      style: TextStyle(color: Colors.grey.shade600),
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
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            title: Text(
                              p.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              'Preço 250g: R\$ ${_formatMoney(price250)}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.amber),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PricingFormPage(
                                          controller: widget.controller,
                                          editingIndex: index,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
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

                  const SizedBox(height: 40),
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
        bool highlight = false,
      }) {
    final formatted = value.toStringAsFixed(2).replaceAll('.', ',');

    final baseStyle = Theme.of(context).textTheme.bodyMedium ??
        const TextStyle(fontSize: 15);

    final textStyle = highlight
        ? baseStyle.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    )
        : baseStyle.copyWith(
      fontSize: 15,
      color: Colors.black87,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textStyle)),
          Text('R\$ $formatted', style: textStyle),
        ],
      ),
    );
  }
}
