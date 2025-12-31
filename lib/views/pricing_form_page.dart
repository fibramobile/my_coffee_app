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

    if (widget.editingIndex != null) {
      final m = widget.controller.model;
    } else {
      debugPrint('FORM: nova precificação');
      // Se você tiver um método para limpar o modelo, pode chamar aqui:
      // widget.controller.resetCurrentPricing();
    }
  }

  double _parseNumber(String value) {
    final cleaned = value.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Converte margem líquida (%) desejada em markup equivalente (%)
  ///
  /// margemPercent: ex: 40 → 40%
  /// Fórmula: markup = (margem / (1 - margem)) * 100
  double _marginToMarkup(double marginPercent) {
    final m = marginPercent / 100.0;

    if (m <= 0) return 0;
    if (m >= 0.99) {
      // evita divisão por zero / markup absurdo
      return 9999;
    }

    return (m / (1 - m)) * 100;
  }

  /// Define cor visual da margem líquida exibida no resumo
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
        final currentMarginPercent = model.profitMargin * 100;

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
                    initialValue: model.pricingId,
                    decoration: const InputDecoration(
                      labelText: 'ID da precificação (família)',
                      helperText: 'Ex.: FLOR, TIUBA, BUGIA, JATAI (sem espaços)',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: widget.controller.setPricingId,
                  ),
                  const SizedBox(height: 16),


                  TextFormField(
                    initialValue: model.productName,
                    decoration: const InputDecoration(
                      labelText: 'Nome do produto (ex: Mel de Bugia)',
                    ),
                    onChanged: widget.controller.setProductName,
                  ),
                  const SizedBox(height: 16),

                  // ------ CAMPO DE MARKUP ------
                  TextFormField(
                    initialValue: model.markupPercent.toStringAsFixed(0),
                    decoration: const InputDecoration(
                      labelText: 'Markup desejado sobre o custo (%)',
                      helperText:
                      'Ex.: 50% → preço = custo × 1,5 (margem ~33%)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) {
                      final markup = _parseNumber(value);
                      widget.controller.setMarkupPercent(markup);
                    },
                  ),

                  const SizedBox(height: 12),

                  // ------ CAMPO DE MARGEM LÍQUIDA DESEJADA ------
                  TextFormField(
                    initialValue:
                    currentMarginPercent.toStringAsFixed(1), // margem atual
                    decoration: const InputDecoration(
                      labelText: 'Margem líquida desejada (%)',
                      helperText:
                      'Ex.: 40% de margem → markup ~67% (aprox.)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) {
                      final desiredMargin = _parseNumber(value);

                      final newMarkup = _marginToMarkup(desiredMargin);

                      widget.controller.setMarkupPercent(newMarkup);
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

                  // MARGEM LÍQUIDA ATUAL (CALCULADA)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Margem líquida atual (%)',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                        Text(
                          '${currentMarginPercent.toStringAsFixed(2).replaceAll('.', ',')}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: getMarginColor(currentMarginPercent),
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
