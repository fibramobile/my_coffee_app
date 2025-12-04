import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/catalog_product.dart';

class CatalogProductsPage extends StatefulWidget {
  const CatalogProductsPage({Key? key}) : super(key: key);

  @override
  State<CatalogProductsPage> createState() => _CatalogProductsPageState();
}

class _CatalogProductsPageState extends State<CatalogProductsPage> {
  final List<CatalogProduct> _products = [];

  bool _isLoading = true;
  bool _isSaving = false;

  static const _loadEndpoint =
      'https://smapps.16mb.com/fratheli/app/products/get_products.php';
  static const _saveEndpoint =
      'https://smapps.16mb.com/fratheli/app/products/save_products.php';


  @override
  void initState() {
    super.initState();
    _loadFromRemote();
  }

  // ---------------- CARREGAR ----------------

  Future<void> _loadFromRemote() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now().millisecondsSinceEpoch.toString();
      final uri =
      Uri.parse(_loadEndpoint).replace(queryParameters: {'v': now});

      final res = await http.get(uri);

      if (res.statusCode == 200 && res.body.trim().isNotEmpty) {
        final decoded = jsonDecode(res.body);
        final list = decoded['products'];

        _products
          ..clear()
          ..addAll(
            (list as List)
                .where((e) => e is Map<String, dynamic>)
                .map((e) => CatalogProduct.fromJson(e)),
          );
      } else {
        _products.clear();
      }
    } catch (e) {
      _products.clear();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------- SALVAR ----------------

  Map<String, dynamic> _buildDataObject() {
    return {
      'updatedAt': DateTime.now().toIso8601String(),
      'products': _products.map((p) => p.toJson()).toList(),
    };
  }

  Future<void> _saveToServer({bool showSnack = true}) async {
    setState(() => _isSaving = true);

    try {
      final data = _buildDataObject();
      final uri = Uri.parse(_saveEndpoint);

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(data),
      );

      if (!mounted) return;

      if (showSnack) {
        if (res.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Catálogo salvo no servidor.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Falha ao salvar catálogo (HTTP ${res.statusCode}).',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (showSnack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar catálogo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---------------- CRUD ----------------

  Future<void> _addOrEditProduct({CatalogProduct? editing}) async {
    final isEditing = editing != null;

    final skuController = TextEditingController(text: editing?.sku ?? '');
    final nameController = TextEditingController(text: editing?.name ?? '');
    final descController =
    TextEditingController(text: editing?.description ?? '');
    final imgController =
    TextEditingController(text: editing?.imagePath ?? '');
    final pricingNameController =
    TextEditingController(text: editing?.pricingName ?? '');
    final fallbackPriceController = TextEditingController(
      text: editing != null ? editing.fallbackPrice.toStringAsFixed(2) : '0.00',
    );
    final tagController = TextEditingController(text: editing?.tag ?? '');
    final metaController = TextEditingController(text: editing?.meta ?? '');
    bool tagAlt = editing?.tagAlt ?? false;
    bool inStock = editing?.inStock ?? true;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar produto' : 'Novo produto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: skuController,
                  decoration: const InputDecoration(labelText: 'SKU'),
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                TextField(
                  controller: pricingNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome na precificação',
                    hintText: 'Ex: Mel de Bugia',
                  ),
                ),
                TextField(
                  controller: fallbackPriceController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Preço base (fallback)',
                    prefixText: 'R\$ ',
                  ),
                ),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration:
                  const InputDecoration(labelText: 'Descrição (site)'),
                ),
                TextField(
                  controller: imgController,
                  decoration: const InputDecoration(
                    labelText: 'Caminho da imagem',
                    hintText: 'assets/img/...',
                  ),
                ),
                TextField(
                  controller: tagController,
                  decoration: const InputDecoration(
                    labelText: 'Tag (ex: PREMIUM, LIMITADO)',
                  ),
                ),
                TextField(
                  controller: metaController,
                  decoration: const InputDecoration(
                    labelText: 'Meta / subtítulo',
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Tag alternativa (tagAlt)'),
                  value: tagAlt,
                  onChanged: (v) {
                    tagAlt = v;
                    (context as Element).markNeedsBuild();
                  },
                ),
                SwitchListTile(
                  title: const Text('Em estoque (inStock)'),
                  value: inStock,
                  onChanged: (v) {
                    inStock = v;
                    (context as Element).markNeedsBuild();
                  },
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
              child: Text(isEditing ? 'Salvar alterações' : 'Adicionar'),
              onPressed: () {
                final sku = skuController.text.trim();
                final name = nameController.text.trim();
                final pricingName = pricingNameController.text.trim();

                if (sku.isEmpty || name.isEmpty || pricingName.isEmpty) {
                  return;
                }

                final fallbackPrice = double.tryParse(
                  fallbackPriceController.text
                      .replaceAll(',', '.')
                      .trim(),
                ) ??
                    0.0;

                setState(() {
                  if (isEditing) {
                    editing!.sku = sku;
                    editing.name = name;
                    editing.description = descController.text.trim();
                    editing.imagePath = imgController.text.trim();
                    editing.pricingName = pricingName;
                    editing.fallbackPrice = fallbackPrice;
                    editing.tag = tagController.text.trim();
                    editing.meta = metaController.text.trim();
                    editing.tagAlt = tagAlt;
                    editing.inStock = inStock;
                  } else {
                    _products.add(
                      CatalogProduct(
                        sku: sku,
                        name: name,
                        description: descController.text.trim(),
                        imagePath: imgController.text.trim(),
                        pricingName: pricingName,
                        fallbackPrice: fallbackPrice,
                        tag: tagController.text.trim(),
                        tagAlt: tagAlt,
                        meta: metaController.text.trim(),
                        inStock: inStock,
                      ),
                    );
                  }
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

  Future<void> _deleteProduct(CatalogProduct p) async {
    setState(() => _products.remove(p));
    await _saveToServer(showSnack: false);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Produtos (site)'),
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
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar do servidor',
            onPressed: _loadFromRemote,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditProduct(),
        icon: const Icon(Icons.add),
        label: const Text('Novo produto'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 120, left: 16, right: 16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _products.isEmpty
            ? Center(
          child: Text(
            'Nenhum produto cadastrado ainda.\n\nToque em "Novo produto" para começar.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.grey[700]),
          ),
        )
            : ListView.builder(
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final p = _products[index];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(
                  p.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SKU: ${p.sku}'),
                    Text('Pricing: ${p.pricingName}'),
                    Text(
                      'Preço base: R\$ ${p.fallbackPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                    ),
                    Text(
                      p.inStock ? 'Em estoque' : 'Sem estoque',
                      style: TextStyle(
                        color:
                        p.inStock ? Colors.green : Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.amber),
                      onPressed: () => _addOrEditProduct(editing: p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      onPressed: () => _deleteProduct(p),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
