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

  /// Define cor visual da margem líquida
  Color getMarginColor(double marginPercent) {
    if (marginPercent >= 40) {
      return Colors.green;
    } else if (marginPercent >= 30) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final model = widget.controller.model;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.editingIndex != null
                  ? 'Editar precificação'
                  : 'Nova precificação',
            ),
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
                    'Resumo da precificação',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),

                  _buildSummaryRow(
                    context,
                    'Total de custo (R\$/kg)',
                    model.totalCostPerKg,
                  ),
                  _buildSummaryRow(
                    context,
                    'Preço final (com margem) – R\$/kg',
                    model.finalPricePerKg,
                    highlight: true,
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    context,
                    'Preço de venda (250g)',
                    model.price250g,
                  ),
                  _buildSummaryRow(
                    context,
                    'Preço de venda (1kg)',
                    model.finalPricePerKg,
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    context,
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
                      onPressed: () async {
                        final isEditing = widget.editingIndex != null;

                        await widget.controller.saveCurrentPricing(
                          indexToUpdate: widget.editingIndex,
                        );

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEditing
                                  ? 'Precificação atualizada!'
                                  : 'Precificação salva!',
                            ),
                          ),
                        );

                        Navigator.pop(context);
                      },
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(
      BuildContext context,
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
