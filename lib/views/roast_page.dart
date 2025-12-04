import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/stock_item.dart';

class RoastRecord {
  final String greenName;
  final double greenQty;
  final double roastedQty;
  final DateTime roastDate;
  final String profile;
  final String roastLevel;
  final String temperature;
  final String roastedName;

  RoastRecord({
    required this.greenName,
    required this.greenQty,
    required this.roastedQty,
    required this.roastDate,
    required this.profile,
    required this.roastLevel,
    required this.temperature,
    required this.roastedName,
  });

  factory RoastRecord.fromJson(Map<String, dynamic> json) {
    return RoastRecord(
      greenName: json['greenName'] as String? ?? '',
      greenQty: (json['greenQty'] as num?)?.toDouble() ?? 0,
      roastedQty: (json['roastedQty'] as num?)?.toDouble() ?? 0,
      roastDate: DateTime.tryParse(json['roastDate'] as String? ?? '') ??
          DateTime.now(),
      profile: json['profile'] as String? ?? '',
      roastLevel: json['roastLevel'] as String? ?? '',
      temperature: json['temperature'] as String? ?? '',
      roastedName: json['roastedName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'greenName': greenName,
      'greenQty': greenQty,
      'roastedQty': roastedQty,
      'roastDate': roastDate.toIso8601String(),
      'profile': profile,
      'roastLevel': roastLevel,
      'temperature': temperature,
      'roastedName': roastedName,
    };
  }
}

class RoastPage extends StatefulWidget {
  const RoastPage({Key? key}) : super(key: key);

  @override
  State<RoastPage> createState() => _RoastPageState();
}

class _RoastPageState extends State<RoastPage> {
  final List<StockItem> _items = [];
  final List<RoastRecord> _roasts = [];

  bool _isLoading = true;
  bool _isSavingStock = false;
  bool _isLoadingRoasts = false;

  static const _loadStockEndpoint =
      'https://smapps.16mb.com/fratheli/app/stock/get_stock.php';
  static const _saveStockEndpoint =
      'https://smapps.16mb.com/fratheli/app/stock/save_stock.php';

  static const _getRoastsEndpoint =
      'https://smapps.16mb.com/fratheli/app/roast/get_roasts.php';
  static const _saveRoastEndpoint =
      'https://smapps.16mb.com/fratheli/app/roast/save_roast.php';

  List<StockItem> get _greenItems =>
      _items.where((i) => i.type == 'verde' && i.quantity > 0).toList();

  // ---------- Helpers ----------

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  Map<String, dynamic> _buildStockData() {
    return {
      'updatedAt': DateTime.now().toIso8601String(),
      'items': _items.map((i) => i.toJson()).toList(),
    };
  }

  // ---------- Carregar estoque + histórico ----------

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  Future<void> _initLoad() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadStock(),
      _loadRoastsHistory(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _editRoast(RoastRecord record, int index) async {
    final qtyController = TextEditingController(text: record.greenQty.toString());
    final roastLevelController = TextEditingController(text: record.roastLevel);
    final profileController = TextEditingController(text: record.profile);
    final tempController = TextEditingController(text: record.temperature);
    final roastedNameController = TextEditingController(text: record.roastedName);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar torra'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: roastedNameController,
                  decoration: const InputDecoration(labelText: 'Nome do lote torrado'),
                ),
                TextField(
                  controller: roastLevelController,
                  decoration: const InputDecoration(labelText: 'Ponto de torra'),
                ),
                TextField(
                  controller: profileController,
                  decoration: const InputDecoration(labelText: 'Perfil'),
                ),
                TextField(
                  controller: tempController,
                  decoration: const InputDecoration(labelText: 'Temperatura'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              child: const Text('Salvar'),
              onPressed: () async {
                final updated = {
                  "roastedName": roastedNameController.text.trim(),
                  "roastLevel": roastLevelController.text.trim(),
                  "profile": profileController.text.trim(),
                  "temperature": tempController.text.trim(),
                };

                final uri = Uri.parse("https://smapps.16mb.com/fratheli/app/roast/edit_roast.php");
                final response = await http.post(
                  uri,
                  headers: {"Content-Type": "application/json; charset=utf-8"},
                  body: jsonEncode({"index": index, "newData": updated}),
                );

                if (response.statusCode == 200) {
                  setState(() {
                    _roasts[index] = RoastRecord(
                      greenName: record.greenName,
                      greenQty: record.greenQty,
                      roastedQty: record.roastedQty,
                      roastDate: record.roastDate,
                      profile: updated["profile"]!,
                      roastLevel: updated["roastLevel"]!,
                      temperature: updated["temperature"]!,
                      roastedName: updated["roastedName"]!,
                    );
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Torra atualizada.')),
                  );
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> _deleteRoast(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir torra?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirm != true) return;

    final uri = Uri.parse("https://smapps.16mb.com/fratheli/app/roast/delete_roast.php");

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: jsonEncode({"index": index}),
    );

    if (response.statusCode == 200) {
      setState(() => _roasts.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Torra excluída.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir torra: ${response.body}')),
      );
    }
  }


  Future<void> _loadStock() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch.toString();
      final uri = Uri.parse(_loadStockEndpoint)
          .replace(queryParameters: {'v': now});

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
    }
  }

  Future<void> _loadRoastsHistory() async {
    setState(() => _isLoadingRoasts = true);
    try {
      final now = DateTime.now().millisecondsSinceEpoch.toString();
      final uri = Uri.parse(_getRoastsEndpoint)
          .replace(queryParameters: {'v': now});

      final response = await http.get(uri);

      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        final decoded = jsonDecode(response.body);
        final roastsJson = decoded['roasts'];

        if (roastsJson is List) {
          _roasts
            ..clear()
            ..addAll(
              roastsJson
                  .where((e) => e is Map<String, dynamic>)
                  .map((e) => RoastRecord.fromJson(e as Map<String, dynamic>))
              // mais recente primeiro
                  .toList()
                  .reversed,
            );
        }
      }
    } catch (_) {
      // se der erro, deixa lista vazia mesmo
    } finally {
      if (mounted) setState(() => _isLoadingRoasts = false);
    }
  }

  // ---------- Salvar estoque + torra -----------

  Future<void> _saveStockToServer() async {
    setState(() => _isSavingStock = true);

    try {
      final uri = Uri.parse(_saveStockEndpoint);
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(_buildStockData()),
      );

      if (mounted && response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Falha ao salvar estoque (HTTP ${response.statusCode}).',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar estoque: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingStock = false);
    }
  }

  Future<void> _saveRoastToServer(RoastRecord record) async {
    try {
      final uri = Uri.parse(_saveRoastEndpoint);
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(record.toJson()),
      );

      if (mounted && response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Falha ao salvar histórico de torra (HTTP ${response.statusCode}).',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar histórico de torra: $e')),
        );
      }
    }
  }

  // ---------- Nova torra ----------

  Future<void> _openNewRoastDialog() async {
    if (_greenItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não há café verde em estoque para torrar.'),
        ),
      );
      return;
    }

    StockItem selectedGreen = _greenItems.first;
    final qtyGreenController = TextEditingController(text: '10');
    final roastDateController =
    TextEditingController(text: _formatDate(DateTime.now()));
    final profileController = TextEditingController();
    final roastLevelController = TextEditingController(text: 'Média');
    final tempController = TextEditingController();
    final roastedNameController = TextEditingController();
    DateTime roastDate = DateTime.now();

    void suggestRoastedName() {
      var name = selectedGreen.name;
      if (name.toLowerCase().contains('verde')) {
        name = name.replaceAll(RegExp(r'(?i)verde'), 'Torrado');
      } else {
        name = '$name - Torrado';
      }
      if (roastedNameController.text.trim().isEmpty) {
        roastedNameController.text = name;
      }
    }

    suggestRoastedName();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: roastDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setModalState(() {
                  roastDate = picked;
                  roastDateController.text = _formatDate(picked);
                });
              }
            }

            return AlertDialog(
              title: const Text('Nova torra'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<StockItem>(
                      value: selectedGreen,
                      isExpanded: true, // 👈 importante
                      decoration: const InputDecoration(
                        labelText: 'Café verde',
                      ),
                      items: _greenItems.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.name} (${item.quantity.toStringAsFixed(1)} ${item.unit})',
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis, // corta com "..."
                                style: TextStyle(fontSize: 12),),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (item) {
                        if (item == null) return;
                        setModalState(() {
                          selectedGreen = item;
                        });
                        suggestRoastedName();
                      },
                    ),

                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Disponível: ${selectedGreen.quantity.toStringAsFixed(2)} ${selectedGreen.unit}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: qtyGreenController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Quantidade de café verde (ex: kg)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: roastDateController,
                      readOnly: true,
                      onTap: pickDate,
                      decoration: const InputDecoration(
                        labelText: 'Data da torra',
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: profileController,
                      decoration: const InputDecoration(
                        labelText: 'Perfil de torra',
                        hintText: 'Ex: Natural, Pulped Natural, Experimental…',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: roastLevelController,
                      decoration: const InputDecoration(
                        labelText: 'Ponto de torra',
                        hintText: 'Clara, Média, Escura…',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: tempController,
                      decoration: const InputDecoration(
                        labelText: 'Temperaturas (opcional)',
                        hintText: 'Ex: Charge 190°C / Drop 205°C',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: roastedNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do lote torrado',
                        hintText: 'Ex: Microlote 01 - Torra Média',
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
                ElevatedButton.icon(
                  icon: const Icon(Icons.local_fire_department),
                  label: const Text('Registrar'),
                  onPressed: () async {
                    final qtyGreen = double.tryParse(
                      qtyGreenController.text.replaceAll(',', '.'),
                    ) ??
                        0;
                    if (qtyGreen <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                          Text('Informe uma quantidade de café verde válida.'),
                        ),
                      );
                      return;
                    }
                    if (qtyGreen > selectedGreen.quantity) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Quantidade maior que o estoque disponível (${selectedGreen.quantity.toStringAsFixed(2)} ${selectedGreen.unit}).',
                          ),
                        ),
                      );
                      return;
                    }

                    final roastedName =
                    roastedNameController.text.trim().isEmpty
                        ? '${selectedGreen.name} - Torrado'
                        : roastedNameController.text.trim();

                    final profile = profileController.text.trim();
                    final level = roastLevelController.text.trim();
                    final temperature = tempController.text.trim();

                    // simples: rendimento fixo 85% por enquanto
                    const yieldFactor = 0.85;
                    final roastedQty = qtyGreen * yieldFactor;

                    // Atualiza estoque + cria registro
                    late RoastRecord record;

                    setState(() {
                      // baixa café verde
                      selectedGreen.quantity -= qtyGreen;

                      // cria/atualiza item torrado
                      final existingRoasted = _items.firstWhere(
                            (i) =>
                        i.type == 'torrado' && i.name == roastedName,
                        orElse: () => StockItem(
                          name: roastedName,
                          unit: selectedGreen.unit,
                          quantity: 0,
                          minQuantity: 0,
                          type: 'torrado',
                        ),
                      );

                      if (!_items.contains(existingRoasted)) {
                        _items.add(existingRoasted);
                      }
                      existingRoasted.quantity += roastedQty;

                      record = RoastRecord(
                        greenName: selectedGreen.name,
                        greenQty: qtyGreen,
                        roastedQty: roastedQty,
                        roastDate: roastDate,
                        profile: profile,
                        roastLevel: level,
                        temperature: temperature,
                        roastedName: roastedName,
                      );

                      _roasts.insert(0, record);
                    });

                    Navigator.pop(context);

                    await _saveStockToServer();
                    await _saveRoastToServer(record);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Torra registrada com sucesso.'),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Torra & Lotes'),
        actions: [
          if (_isSavingStock)
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewRoastDialog,
        icon: const Icon(Icons.local_fire_department),
        label: const Text('Nova torra'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fluxo',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '• Escolha um café VERDE do estoque\n'
                  '• Informe quantidade, data e dados técnicos da torra\n'
                  '• Baixa café VERDE e credita lote de CAFÉ TORRADO no estoque\n'
                  '• Histórico fica salvo em servidor (roasts_data.json)',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Histórico de torras',
                  style: theme.textTheme.titleMedium,
                ),
                if (_isLoadingRoasts) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _roasts.isEmpty
                  ? Center(
                child: Text(
                  _greenItems.isEmpty
                      ? 'Nenhum café verde disponível.\nCadastre cafés verdes na tela de Estoque.'
                      : 'Nenhuma torra registrada ainda.\nUse o botão "Nova torra" para começar.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              )
                  : ListView.separated(
                itemCount: _roasts.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final r = _roasts[index];
                  return Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          // título
                          Row(
                            children: [
                              const Icon(Icons.local_fire_department, size: 20),
                              const SizedBox(width: 8),

                              // Nome da torra
                              Expanded(
                                child: Text(
                                  r.roastedName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              // BOTÃO ⋮ DE OPÇÕES
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _editRoast(r, index); // ← função que já deixei pronta
                                  } else if (value == 'delete') {
                                    _deleteRoast(index);  // ← função que já deixei pronta
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar torra'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Excluir torra'),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),
                          Text(
                            'De: ${r.greenName}',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            'Quantidade: ${r.greenQty.toStringAsFixed(2)} → ${r.roastedQty.toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            'Data da torra: ${_formatDate(r.roastDate)}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(
                                color: Colors.grey[700]),
                          ),
                          if (r.roastLevel.isNotEmpty ||
                              r.profile.isNotEmpty)
                            Padding(
                              padding:
                              const EdgeInsets.only(top: 4),
                              child: Text(
                                [
                                  if (r.roastLevel.isNotEmpty)
                                    'Ponto: ${r.roastLevel}',
                                  if (r.profile.isNotEmpty)
                                    'Perfil: ${r.profile}',
                                ].join(' · '),
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          if (r.temperature.isNotEmpty)
                            Padding(
                              padding:
                              const EdgeInsets.only(top: 2),
                              child: Text(
                                'Temperaturas: ${r.temperature}',
                                style: theme.textTheme.bodySmall,
                              ),
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
