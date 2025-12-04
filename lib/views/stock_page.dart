import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Modelo de item de estoque
class StockItem {
  String name;        // Ex: "Bugia 250g"
  String unit;        // Ex: "pacotes", "kg", "sacas"
  double quantity;    // Quantidade atual
  double minQuantity; // Estoque mínimo desejado

  StockItem({
    required this.name,
    required this.unit,
    required this.quantity,
    required this.minQuantity,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      name: json['name'] as String? ?? '',
      unit: json['unit'] as String? ?? 'unid.',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      minQuantity: (json['minQuantity'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'unit': unit,
      'quantity': quantity,
      'minQuantity': minQuantity,
    };
  }
}

class StockPage extends StatefulWidget {
  const StockPage({Key? key}) : super(key: key);

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final List<StockItem> _items = [];

  bool _showOnlyLow = false;
  bool _isLoading = true;
  bool _isSaving = false;

// Endpoints
  static const _loadEndpoint =
      'https://smapps.16mb.com/fratheli/app/stock/get_stock.php';
  static const _saveEndpoint =
      'https://smapps.16mb.com/fratheli/app/stock/save_stock.php';


  // ---------- HELPERS ----------

  List<StockItem> get _visibleItems {
    if (!_showOnlyLow) return _items;
    return _items.where((i) => i.quantity <= i.minQuantity).toList();
  }

  String _format(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  // ---------- CARREGAR JSON REMOTO (COM ANTI-CACHE) ----------

  @override
  void initState() {
    super.initState();
    _loadFromRemote();
  }

  Future<void> _loadFromRemote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ainda uso anti-cache pra garantir que não pegue versão antiga
      final now = DateTime.now().millisecondsSinceEpoch.toString();
      final uri = Uri.parse(_loadEndpoint).replace(queryParameters: {'v': now});

      final response = await http.get(uri);

      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        final decoded = jsonDecode(response.body);

        final itemsJson = decoded['items'];
        if (itemsJson is List) {
          _items
            ..clear()
            ..addAll(
              itemsJson
                  .where((e) => e is Map<String, dynamic>)
                  .map((e) => StockItem.fromJson(e as Map<String, dynamic>)),
            );
        } else {
          _items.clear();
        }
      } else {
        _items.clear();
      }
    } catch (e) {
      _items.clear();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  // ---------- MONTAR JSON E SALVAR NO SERVIDOR ----------

  Map<String, dynamic> _buildDataObject() {
    return {
      'updatedAt': DateTime.now().toIso8601String(),
      'items': _items.map((i) => i.toJson()).toList(),
    };
  }

  Future<void> _saveToServer({bool showSnack = true}) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final data = _buildDataObject();
      final jsonString = jsonEncode(data);

      final uri = Uri.parse(_saveEndpoint);
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonString,
      );

      if (response.statusCode == 200) {
        if (showSnack && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estoque salvo no servidor.'),
            ),
          );
        }
      } else {
        if (showSnack && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Falha ao salvar no servidor (HTTP ${response.statusCode}).',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (showSnack && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar no servidor: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showExportJsonDialog() {
    final data = _buildDataObject();
    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(data);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('JSON do estoque'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                jsonString,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Fechar'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  // ---------- AÇÕES ----------

  void _addItem() {
    final nameController = TextEditingController();
    final unitController = TextEditingController(text: 'pacotes');
    final quantityController = TextEditingController(text: '0');
    final minQuantityController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Novo item de estoque'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do item',
                    hintText: 'Ex: Bugia 250g',
                  ),
                ),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unidade',
                    hintText: 'Ex: pacotes, kg, sacas',
                  ),
                ),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade atual',
                  ),
                ),
                TextField(
                  controller: minQuantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Estoque mínimo',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Salvar'),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final quantity =
                    double.tryParse(quantityController.text.replaceAll(',', '.')) ?? 0;
                final minQty =
                    double.tryParse(minQuantityController.text.replaceAll(',', '.')) ?? 0;

                setState(() {
                  _items.add(
                    StockItem(
                      name: name,
                      unit: unitController.text.trim().isEmpty
                          ? 'unid.'
                          : unitController.text.trim(),
                      quantity: quantity,
                      minQuantity: minQty,
                    ),
                  );
                });

                Navigator.pop(context);

                await _saveToServer();
              },
            ),
          ],
        );
      },
    );
  }

  void _editQuantity(StockItem item) {
    final quantityController =
    TextEditingController(text: _format(item.quantity));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ajustar estoque - ${item.name}'),
          content: TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantidade atual',
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Salvar'),
              onPressed: () async {
                final value =
                double.tryParse(quantityController.text.replaceAll(',', '.'));
                if (value == null) return;

                setState(() {
                  item.quantity = value;
                });

                Navigator.pop(context);

                await _saveToServer(showSnack: false);
              },
            ),
          ],
        );
      },
    );
  }

  void _editMinQuantity(StockItem item) {
    final minQuantityController =
    TextEditingController(text: _format(item.minQuantity));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Estoque mínimo - ${item.name}'),
          content: TextField(
            controller: minQuantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Estoque mínimo desejado',
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Salvar'),
              onPressed: () async {
                final value =
                double.tryParse(minQuantityController.text.replaceAll(',', '.'));
                if (value == null) return;

                setState(() {
                  item.minQuantity = value;
                });

                Navigator.pop(context);

                await _saveToServer(showSnack: false);
              },
            ),
          ],
        );
      },
    );
  }

  void _editItem(StockItem item) {
    final nameController = TextEditingController(text: item.name);
    final unitController = TextEditingController(text: item.unit);
    final quantityController =
    TextEditingController(text: _format(item.quantity));
    final minQuantityController =
    TextEditingController(text: _format(item.minQuantity));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar item de estoque'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do item',
                  ),
                ),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unidade',
                  ),
                ),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade atual',
                  ),
                ),
                TextField(
                  controller: minQuantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Estoque mínimo',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Salvar'),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final qty = double.tryParse(
                  quantityController.text.replaceAll(',', '.'),
                ) ??
                    item.quantity;
                final minQty = double.tryParse(
                  minQuantityController.text.replaceAll(',', '.'),
                ) ??
                    item.minQuantity;

                setState(() {
                  item.name = name;
                  item.unit = unitController.text.trim().isEmpty
                      ? item.unit
                      : unitController.text.trim();
                  item.quantity = qty;
                  item.minQuantity = minQty;
                });

                Navigator.pop(context);

                await _saveToServer(showSnack: false);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem(StockItem item) async {
    setState(() {
      _items.remove(item);
    });
    await _saveToServer(showSnack: false);
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lowCount =
        _items.where((i) => i.quantity <= i.minQuantity).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque & Armazém'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Exportar JSON do estoque',
            icon: const Icon(Icons.code),
            onPressed: _items.isEmpty ? null : _showExportJsonDialog,
          ),
          IconButton(
            tooltip: _showOnlyLow
                ? 'Mostrar todos os itens'
                : 'Mostrar só itens com estoque baixo',
            icon: Icon(
              _showOnlyLow ? Icons.filter_alt_off : Icons.filter_alt,
            ),
            onPressed: () {
              setState(() {
                _showOnlyLow = !_showOnlyLow;
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        icon: const Icon(Icons.add),
        label: const Text('Novo item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // Resumo
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warehouse),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumo do estoque',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_items.length} itens cadastrados · $lowCount com estoque baixo',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                    if (lowCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.redAccent,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Repor',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _visibleItems.isEmpty
                  ? Center(
                child: Text(
                  'Nenhum registro de estoque encontrado.\n'
                      'Toque em "Novo item" para cadastrar o primeiro.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              )
                  : ListView.separated(
                itemCount: _visibleItems.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _visibleItems[index];
                  final isLow =
                      item.quantity <= item.minQuantity;

                  return Card(
                    elevation: 2,
                    child: ListTile(
                      title: Row(
                        children: [
                          Expanded(child: Text(item.name)),
                          if (isLow)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                borderRadius:
                                BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Baixo estoque',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Qtd: ${_format(item.quantity)} ${item.unit}',
                          ),
                          Text(
                            'Mínimo: ${_format(item.minQuantity)} ${item.unit}',
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      leading: Icon(
                        Icons.inventory_2,
                        color: isLow
                            ? Colors.redAccent
                            : Colors.green,
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editItem(item);
                          } else if (value == 'qtd') {
                            _editQuantity(item);
                          } else if (value == 'min') {
                            _editMinQuantity(item);
                          } else if (value == 'del') {
                            _deleteItem(item);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Editar item'),
                          ),
                          PopupMenuItem(
                            value: 'qtd',
                            child: Text('Ajustar quantidade'),
                          ),
                          PopupMenuItem(
                            value: 'min',
                            child: Text('Definir estoque mínimo'),
                          ),
                          PopupMenuItem(
                            value: 'del',
                            child: Text('Remover item'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
