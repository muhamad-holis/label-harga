import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/product_provider.dart';

class _UnitRowData {
  final int? existingUnitId; // null kalau baris baru (belum tersimpan)
  final TextEditingController labelController;
  final TextEditingController priceController;

  _UnitRowData({
    this.existingUnitId,
    required String label,
    required String price,
  })  : labelController = TextEditingController(text: label),
        priceController = TextEditingController(text: price);

  void dispose() {
    labelController.dispose();
    priceController.dispose();
  }
}

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? existing;
  const ProductFormScreen({super.key, this.existing});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final List<_UnitRowData> _unitRows = [];
  final List<int> _deletedUnitIds = [];
  bool _loadedExistingUnits = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');

    if (widget.existing == null) {
      // Produk baru: mulai dengan satu baris kosong.
      _unitRows.add(_UnitRowData(label: '', price: ''));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final row in _unitRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _loadExistingUnitsOnce(List<ProductUnit> units) {
    if (_loadedExistingUnits) return;
    _loadedExistingUnits = true;
    if (units.isEmpty) {
      _unitRows.add(_UnitRowData(label: '', price: ''));
    } else {
      for (final u in units) {
        _unitRows.add(_UnitRowData(
          existingUnitId: u.id,
          label: u.unitLabel,
          price: u.price.toString(),
        ));
      }
    }
  }

  void _addUnitRow() {
    setState(() {
      _unitRows.add(_UnitRowData(label: '', price: ''));
    });
  }

  void _removeUnitRow(int index) {
    setState(() {
      final row = _unitRows.removeAt(index);
      if (row.existingUnitId != null) {
        _deletedUnitIds.add(row.existingUnitId!);
      }
      row.dispose();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final db = ref.read(databaseProvider);
    final name = _nameController.text.trim();

    int productId;
    if (widget.existing == null) {
      productId = await db.insertProduct(name);
    } else {
      productId = widget.existing!.id;
      await db.updateProductName(productId, name);
    }

    for (final id in _deletedUnitIds) {
      await db.deleteUnit(id);
    }

    for (final row in _unitRows) {
      final label = row.labelController.text.trim();
      final price = int.tryParse(row.priceController.text.trim());
      if (label.isEmpty || price == null) continue;

      if (row.existingUnitId != null) {
        await db.updateUnit(row.existingUnitId!, label, price);
      } else {
        await db.insertUnit(productId, label, price);
      }
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteProduct() async {
    final db = ref.read(databaseProvider);
    await db.deleteProduct(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    // Muat satuan yang sudah ada (sekali saja) kalau mode edit.
    if (isEditing && !_loadedExistingUnits) {
      final productsAsync = ref.watch(productListProvider);
      productsAsync.whenData((list) {
        final match = list.where((p) => p.product.id == widget.existing!.id);
        if (match.isNotEmpty) {
          _loadExistingUnitsOnce(match.first.units);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Barang' : 'Tambah Barang'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteProduct,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Barang',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Nama barang wajib diisi'
                  : null,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  'Satuan & Harga',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addUnitRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah satuan'),
                ),
              ],
            ),
            const Text(
              'Contoh: Dus, Pack, Pcs — bebas, minimal satu satuan.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < _unitRows.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _unitRows[i].labelController,
                        decoration: const InputDecoration(
                          labelText: 'Satuan',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        controller: _unitRows[i].priceController,
                        decoration: const InputDecoration(
                          labelText: 'Harga',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _unitRows.length > 1
                          ? () => _removeUnitRow(i)
                          : null,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _save,
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
