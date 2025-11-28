import 'package:flutter/material.dart';
import '../../models/cost_item.dart';

class CostItemTile extends StatelessWidget {
  final CostItem item;
  final int index;
  final ValueChanged<double> onChanged;

  const CostItemTile({
    Key? key,
    required this.item,
    required this.index,
    required this.onChanged,
  }) : super(key: key);

  double _parseNumber(String value) {
    final cleaned = value.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. ${item.name}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (item.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  item.description,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: item.costPerKg.toStringAsFixed(2),
              decoration: const InputDecoration(
                labelText: 'Custo unitário (R\$/kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) {
                onChanged(_parseNumber(value));
              },
            ),
          ],
        ),
      ),
    );
  }
}
