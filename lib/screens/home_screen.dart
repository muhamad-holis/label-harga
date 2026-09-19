import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/printer_provider.dart';
import '../providers/product_provider.dart';
import '../utils/currency_formatter.dart';
import 'history_screen.dart';
import 'print_preview_screen.dart';
import 'printer_screen.dart';
import 'product_form_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(filteredProductListProvider);
    final selected = ref.watch(selectedUnitsProvider);
    final printerState = ref.watch(printerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Label Harga'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat cetak',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            icon: Icon(
              printerState.connected != null
                  ? Icons.print
                  : Icons.print_disabled,
            ),
            tooltip: printerState.connected?.name ?? 'Belum ada printer',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrinterScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama barang...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const _EmptyState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final item = products[index];
                    return _ProductCard(
                      productWithUnits: item,
                      selected: selected,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (selected.isNotEmpty)
            FloatingActionButton.extended(
              heroTag: 'preview',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrintPreviewScreen()),
              ),
              icon: const Icon(Icons.visibility_outlined),
              label: Text('Preview (${selected.length})'),
            ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProductFormScreen()),
            ),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final ProductWithUnits productWithUnits;
  final Map<int, SelectedUnitItem> selected;

  const _ProductCard({required this.productWithUnits, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = productWithUnits.product;
    final units = productWithUnits.units;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: units.isEmpty
                  ? const Text('Belum ada satuan/harga')
                  : null,
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductFormScreen(existing: product),
                  ),
                ),
              ),
            ),
            for (final unit in units)
              _UnitRow(
                unit: unit,
                productName: product.name,
                selectedItem: selected[unit.id],
              ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _UnitRow extends ConsumerWidget {
  final ProductUnit unit;
  final String productName;
  final SelectedUnitItem? selectedItem;

  const _UnitRow({
    required this.unit,
    required this.productName,
    required this.selectedItem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = selectedItem != null;

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (_) => ref
                .read(selectedUnitsProvider.notifier)
                .toggle(unit, productName),
          ),
          Expanded(
            child: Text('${unit.unitLabel} — ${formatRupiah(unit.price)}'),
          ),
          if (isSelected)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: selectedItem!.quantity > 1
                      ? () => ref
                          .read(selectedUnitsProvider.notifier)
                          .setQuantity(unit.id, selectedItem!.quantity - 1)
                      : null,
                ),
                Text('${selectedItem!.quantity}'),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => ref
                      .read(selectedUnitsProvider.notifier)
                      .setQuantity(unit.id, selectedItem!.quantity + 1),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sell_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Belum ada produk.\nTekan tombol + untuk menambahkan barang.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
