import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/catalog_product.dart';

import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

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

  String? _uploadedImagePath; // ex: "images/bugia_250.jpg"

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

  // ---------------- UPLOAD IMAGEM (WEB + MOBILE) ----------------
  Future<void> _pickAndUploadImage(TextEditingController imgController) async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (picked == null) return;

    // ✅ pega bytes (funciona no WEB e no MOBILE)
    final Uint8List bytes = await picked.readAsBytes();
    final String filename = picked.name.isNotEmpty ? picked.name : 'image.jpg';

    final uri = Uri.parse(
      'https://smapps.16mb.com/fratheli/app/products/upload_product_image.php',
    );

    final request = http.MultipartRequest('POST', uri);

    // tenta descobrir mime (image/jpeg, image/png etc)
    final mimeType =
        lookupMimeType(filename, headerBytes: bytes) ?? 'image/jpeg';
    final parts = mimeType.split('/');
    final contentType =
    MediaType(parts[0], parts.length > 1 ? parts[1] : 'jpeg');

    request.files.add(
      http.MultipartFile.fromBytes(
        'file', // ⚠️ tem que bater com seu PHP: $_FILES['file']
        bytes,
        filename: filename,
        contentType: contentType,
      ),
    );

    final streamed = await request.send();
    final status = streamed.statusCode;
    final body = await streamed.stream.bytesToString();

    if (!mounted) return;

    if (status == 200) {
      try {
        final data = jsonDecode(body);

        if (data['success'] == true) {
          setState(() {
            _uploadedImagePath = data['path']; // ex: images/xxx.jpg
            imgController.text = _uploadedImagePath!; // ✅ atualiza campo
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imagem enviada com sucesso.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: ${data['error'] ?? 'desconhecido'}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resposta inválida do servidor: $body')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('HTTP $status no upload. Body: $body')),
      );
    }
  }

  // ---------------- CRUD ----------------
  Future<void> _addOrEditProduct({CatalogProduct? editing}) async {
    final isEditing = editing != null;

    final skuController = TextEditingController(text: editing?.sku ?? '');
    final nameController = TextEditingController(text: editing?.name ?? '');
    final pricingNameController =
    TextEditingController(text: editing?.pricingName ?? '');
    final descController =
    TextEditingController(text: editing?.description ?? '');
    final imgController =
    TextEditingController(text: editing?.imagePath ?? '');
    final fallbackPriceController = TextEditingController(
      text: editing != null ? editing.fallbackPrice.toStringAsFixed(2) : '',
    );
    final originalPriceController = TextEditingController(
      text: (editing?.originalPrice != null)
          ? editing!.originalPrice!.toStringAsFixed(2)
          : '',
    );
    final tagController = TextEditingController(text: editing?.tag ?? '');
    final metaController = TextEditingController(text: editing?.meta ?? '');

    bool tagAlt = editing?.tagAlt ?? false;
    bool inStock = editing?.inStock ?? true;

    // 🔥 OPÇÕES DE MOAGEM (Grão / Moído)
    final existingGrinds = editing?.grindOptions ?? const <String>[];
    bool grindGrao =
    existingGrinds.isEmpty ? true : existingGrinds.contains('Grão');
    bool grindMoido =
    existingGrinds.isEmpty ? true : existingGrinds.contains('Moído');

    String defaultGrindLocal = editing?.defaultGrind ??
        (grindGrao ? 'Grão' : (grindMoido ? 'Moído' : 'Grão'));

    String getPreviewPath() => _uploadedImagePath ?? imgController.text.trim();

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFFF6EEE0),
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          titlePadding:
          const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 8),
          contentPadding:
          const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 16),
          title: Text(
            isEditing ? 'Editar produto' : 'Novo produto',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: skuController,
                    decoration: const InputDecoration(labelText: 'SKU'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    decoration:
                    const InputDecoration(labelText: 'Nome (ex: 250g)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: pricingNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome na precificação',
                      hintText: 'Ex: Mel de Bugia',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PREÇOS
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: fallbackPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Preço base (fallback)',
                            prefixText: 'R\$ ',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: originalPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Preço cheio',
                            prefixText: 'R\$ ',
                            hintText: 'Ex: 55,00',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // DESCRIÇÃO
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration:
                    const InputDecoration(labelText: 'Descrição (site)'),
                  ),
                  const SizedBox(height: 16),

                  // MOAGEM
                  Text(
                    'Opções de moagem',
                    style: Theme.of(dialogCtx).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Grão (inteiro)'),
                    value: grindGrao,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (v) {
                      grindGrao = v ?? false;
                      if (!grindGrao && defaultGrindLocal == 'Grão') {
                        if (grindMoido) defaultGrindLocal = 'Moído';
                      }
                      (dialogCtx as Element).markNeedsBuild();
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Moído'),
                    value: grindMoido,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (v) {
                      grindMoido = v ?? false;
                      if (!grindMoido && defaultGrindLocal == 'Moído') {
                        if (grindGrao) defaultGrindLocal = 'Grão';
                      }
                      (dialogCtx as Element).markNeedsBuild();
                    },
                  ),
                  if (grindGrao || grindMoido) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Moagem padrão no site/app',
                      style: Theme.of(dialogCtx)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),

                    RadioListTile<String>(
                      title: const Text('Grão'),
                      value: 'Grão',
                      groupValue: defaultGrindLocal,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: grindGrao
                          ? (v) {
                        defaultGrindLocal = v!;
                        (dialogCtx as Element).markNeedsBuild();
                      }
                          : null,
                    ),
                    RadioListTile<String>(
                      title: const Text('Moído'),
                      value: 'Moído',
                      groupValue: defaultGrindLocal,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: grindMoido
                          ? (v) {
                        defaultGrindLocal = v!;
                        (dialogCtx as Element).markNeedsBuild();
                      }
                          : null,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // IMAGEM
                  Text(
                    'Imagem do produto',
                    style: Theme.of(dialogCtx).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: () async {
                      await _pickAndUploadImage(imgController);
                      (dialogCtx as Element).markNeedsBuild();
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Selecionar imagem'),
                  ),
                  const SizedBox(height: 10),
                  if (getPreviewPath().isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: Image.network(
                          'https://smapps.16mb.com/fratheli/app/products/${getPreviewPath()}',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: tagController,
                    decoration: const InputDecoration(
                        labelText: 'Tag (ex: ORIGEM, PREMIUM)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: metaController,
                    decoration: const InputDecoration(
                      labelText: 'Meta / subtítulo',
                      hintText: 'Ex: Acidez equilibrada, corpo suave...',
                    ),
                  ),
                  const SizedBox(height: 8),

                  SwitchListTile(
                    title: const Text('Tag alternativa (tagAlt)'),
                    value: tagAlt,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) {
                      tagAlt = v;
                      (dialogCtx as Element).markNeedsBuild();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Em estoque (inStock)'),
                    value: inStock,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) {
                      inStock = v;
                      (dialogCtx as Element).markNeedsBuild();
                    },
                  ),
                ],
              ),
            ),
          ),
          actionsPadding:
          const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(dialogCtx),
            ),
            ElevatedButton(
              child: Text(isEditing ? 'Salvar alterações' : 'Adicionar'),
              onPressed: () {
                final sku = skuController.text.trim();
                final name = nameController.text.trim();
                final pricingName = pricingNameController.text.trim();

                if (sku.isEmpty || name.isEmpty || pricingName.isEmpty) return;

                final fallbackPrice = double.tryParse(
                  fallbackPriceController.text.replaceAll(',', '.').trim(),
                ) ??
                    0.0;

                final originalPrice = double.tryParse(
                  originalPriceController.text.replaceAll(',', '.').trim(),
                );

                final List<String> grindOptions = [];
                if (grindGrao) grindOptions.add('Grão');
                if (grindMoido) grindOptions.add('Moído');

                String? defaultGrind = defaultGrindLocal;
                if (!grindOptions.contains(defaultGrind)) {
                  defaultGrind =
                  grindOptions.isNotEmpty ? grindOptions.first : null;
                }

                setState(() {
                  if (isEditing) {
                    editing!.sku = sku;
                    editing.name = name;
                    editing.description = descController.text.trim();
                    editing.imagePath = imgController.text.trim();
                    editing.pricingName = pricingName;
                    editing.fallbackPrice = fallbackPrice;
                    editing.originalPrice = originalPrice;
                    editing.tag = tagController.text.trim();
                    editing.meta = metaController.text.trim();
                    editing.tagAlt = tagAlt;
                    editing.inStock = inStock;
                    editing.grindOptions = grindOptions;
                    editing.defaultGrind = defaultGrind;
                  } else {
                    _products.add(
                      CatalogProduct(
                        sku: sku,
                        name: name,
                        description: descController.text.trim(),
                        imagePath: imgController.text.trim(),
                        pricingName: pricingName,
                        fallbackPrice: fallbackPrice,
                        originalPrice: originalPrice,
                        tag: tagController.text.trim(),
                        tagAlt: tagAlt,
                        meta: metaController.text.trim(),
                        inStock: inStock,
                        grindOptions: grindOptions,
                        defaultGrind: defaultGrind,
                      ),
                    );
                  }
                });

                Navigator.pop(dialogCtx);
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
        title: const Text(
          'Catálogo de Produtos (site)',
          style: TextStyle(fontSize: 14),
        ),
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
        padding:
        const EdgeInsets.only(top: 16, bottom: 120, left: 16, right: 16),
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                        color: p.inStock
                            ? Colors.green
                            : Colors.redAccent,
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
                      icon: const Icon(Icons.edit,
                          color: Colors.amber),
                      onPressed: () =>
                          _addOrEditProduct(editing: p),
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
