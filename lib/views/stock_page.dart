import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/stock_item.dart';

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
  String _typeFilter = 'todos'; // 'todos', 'verde', 'torrado', 'outro'

  static const _loadEndpoint =
      'https://smapps.16mb.com/fratheli/app/stock/get_stock.php';
  static const _saveEndpoint =
      'https://smapps.16mb.com/fratheli/app/stock/save_stock.php';

  // ---------- HELPERS ----------

  List<StockItem> get _visibleItems {
    Iterable<StockItem> list = _items;

    if (_typeFilter != 'todos') {
      list = list.where((i) => i.type == _typeFilter);
    }
    if (_showOnlyLow) {
      list = list.where((i) => i.quantity <= i.minQuantity);
    }

    return list.toList();
  }

  String _format(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  // ---------- CARREGAR JSON (via PHP com CORS) ----------

  @override
  void initState() {
    super.initState();
    _loadFromRemote();
  }

  Future<void> _loadFromRemote() async {
    setState(() => _isLoading = true);

    try {
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
    } catch (_) {
      _items.clear();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------- SALVAR JSON NO SERVIDOR ----------

  Map<String, dynamic> _buildDataObject() {
    return {
      'updatedAt': DateTime.now().toIso8601String(),
      'items': _items.map((i) => i.toJson()).toList(),
    };
  }

  Future<void> _saveToServer({bool showSnack = true}) async {
    setState(() => _isSaving = true);

    try {
      final data = _buildDataObject();
      final uri = Uri.parse(_saveEndpoint);
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(data),
      );

      if (showSnack && mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Estoque salvo no servidor.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Falha ao salvar no servidor (HTTP ${response.statusCode}).'),
            ),
          );
        }
      }
    } catch (e) {
      if (showSnack && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar no servidor: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showExportJsonDialog() {
    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(_buildDataObject());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('JSON do estoque'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonString,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Fechar'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ---------- AÇÕES (CRUD) ----------

  Future<void> _addItem() async {
    final nameController = TextEditingController();
    final unitController = TextEditingController(text: 'kg');
    final quantityController = TextEditingController(text: '0');
    final minQuantityController = TextEditingController(text: '0');
    String selectedType = 'torrado'; // padrão: produtos finalizados

    await showDialog(
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
                    hintText: 'Ex: Microlote 01',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(
                      value: 'verde',
                      child: Text('Café verde'),
                    ),
                    DropdownMenuItem(
                      value: 'torrado',
                      child: Text('Café torrado'),
                    ),
                    DropdownMenuItem(
                      value: 'outro',
                      child: Text('Outros (mel, insumos...)'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    selectedType = v;
                  },
                ),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unidade',
                    hintText: 'kg, pacotes, sacas…',
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
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final quantity = double.tryParse(
                    quantityController.text.replaceAll(',', '.')) ??
                    0;
                final minQty = double.tryParse(
                    minQuantityController.text.replaceAll(',', '.')) ??
                    0;

                setState(() {
                  _items.add(
                    StockItem(
                      name: name,
                      unit: unitController.text.trim().isEmpty
                          ? 'unid.'
                          : unitController.text.trim(),
                      quantity: quantity,
                      minQuantity: minQty,
                      type: selectedType,
                    ),
                  );
                });

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );

    await _saveToServer();
  }

  Future<void> _editItem(StockItem item) async {
    final nameController = TextEditingController(text: item.name);
    final unitController = TextEditingController(text: item.unit);
    final quantityController = TextEditingController(text: _format(item.quantity));
    final minQuantityController =
    TextEditingController(text: _format(item.minQuantity));
    String selectedType = item.type;

    await showDialog(
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
                  decoration: const InputDecoration(labelText: 'Nome do item'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(
                      value: 'verde',
                      child: Text('Café verde'),
                    ),
                    DropdownMenuItem(
                      value: 'torrado',
                      child: Text('Café torrado'),
                    ),
                    DropdownMenuItem(
                      value: 'outro',
                      child: Text('Outros'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    selectedType = v;
                  },
                ),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(labelText: 'Unidade'),
                ),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration:
                  const InputDecoration(labelText: 'Quantidade atual'),
                ),
                TextField(
                  controller: minQuantityController,
                  keyboardType: TextInputType.number,
                  decoration:
                  const InputDecoration(labelText: 'Estoque mínimo'),
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
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final qty = double.tryParse(
                    quantityController.text.replaceAll(',', '.')) ??
                    item.quantity;
                final minQty = double.tryParse(
                    minQuantityController.text.replaceAll(',', '.')) ??
                    item.minQuantity;

                setState(() {
                  item.name = name;
                  item.unit = unitController.text.trim().isEmpty
                      ? item.unit
                      : unitController.text.trim();
                  item.quantity = qty;
                  item.minQuantity = minQty;
                  item.type = selectedType;
                });

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );

    await _saveToServer(showSnack: false);
  }

  Future<void> _deleteItem(StockItem item) async {
    setState(() => _items.remove(item));
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
                ? 'Mostrar todos'
                : 'Mostrar só com estoque baixo',
            icon: Icon(_showOnlyLow ? Icons.filter_alt_off : Icons.filter_alt),
            onPressed: () => setState(() {
              _showOnlyLow = !_showOnlyLow;
            }),
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
                          Text('Resumo do estoque',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            '${_items.length} itens · $lowCount com estoque baixo',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Filtros por tipo
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _typeFilter == 'todos',
                    onSelected: (_) =>
                        setState(() => _typeFilter = 'todos'),
                  ),
                  ChoiceChip(
                    label: const Text('Café verde'),
                    selected: _typeFilter == 'verde',
                    onSelected: (_) =>
                        setState(() => _typeFilter = 'verde'),
                  ),
                  ChoiceChip(
                    label: const Text('Café torrado'),
                    selected: _typeFilter == 'torrado',
                    onSelected: (_) =>
                        setState(() => _typeFilter = 'torrado'),
                  ),
                  ChoiceChip(
                    label: const Text('Outros'),
                    selected: _typeFilter == 'outro',
                    onSelected: (_) =>
                        setState(() => _typeFilter = 'outro'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: _visibleItems.isEmpty
                  ? Center(
                child: Text(
                  'Nenhum registro de estoque.\n'
                      'Toque em "Novo item" para começar.',
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
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: item.type == 'verde'
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (item.type == 'verde')
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.eco,
                                size: 16,
                              ),
                            ),
                          if (item.type == 'torrado')
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.local_fire_department,
                                size: 16,
                              ),
                            ),
                          if (isLow)
                            Container(
                              margin:
                              const EdgeInsets.only(left: 6),
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
                              'Qtd: ${_format(item.quantity)} ${item.unit}'),
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
