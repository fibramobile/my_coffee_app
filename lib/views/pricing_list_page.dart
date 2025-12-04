import 'package:flutter/material.dart';
import '../controllers/pricing_controller.dart';
import 'pricing_form_page.dart';

class PricingListPage extends StatelessWidget {
  final PricingController controller;

  const PricingListPage({
    Key? key,
    required this.controller,
  }) : super(key: key);

  String _formatMoney(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final saved = [...controller.savedPricings];
        saved.sort((a, b) => a.price250g.compareTo(b.price250g));


        return Scaffold(
          appBar: AppBar(
            title: const Text('Precificações de Café'),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 120, left: 16, right: 16),
            child: saved.isEmpty
                ? Center(
              child: Text(
                'Nenhuma precificação salva ainda.\n\nToque no botão + para criar a primeira.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            )
                : ListView.builder(
              itemCount: saved.length,
              itemBuilder: (context, index) {
                final p = saved[index];
                final price250 = p.price250g;
                final marginPercent = p.profitMargin * 100;

                Color marginColor;
                if (marginPercent >= 40) {
                  marginColor = Colors.green;
                } else if (marginPercent >= 30) {
                  marginColor = Colors.orange;
                } else {
                  marginColor = Colors.red;
                }

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
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preço 250g: R\$ ${_formatMoney(price250)}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Margem líquida: ${marginPercent.toStringAsFixed(1).replaceAll('.', ',')}%',
                          style: TextStyle(
                            fontSize: 13,
                            color: marginColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.amber),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PricingFormPage(
                                  controller: controller,
                                  editingIndex: index,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            controller.removeSavedPricing(index);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Botão flutuante para criar nova precificação
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PricingFormPage(
                    controller: controller,
                    editingIndex: null,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Nova precificação'),
          ),
        );
      },
    );
  }
}
