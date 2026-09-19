import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/printer_provider.dart';
import '../providers/product_provider.dart';
import '../services/print_service.dart';
import '../utils/currency_formatter.dart';
import 'printer_screen.dart';
import 'product_form_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);
    final selected = ref.watch(selectedProductIdsProvider);
    final printerState = ref.watch(printerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Label Harga'),
        actions: [
          IconButton(
            icon: Icon(
              printerState.connected != null
                  ? Icons.print
                  : Icons.print_disabled,
              color: printerState.connected != null ? Colors.white : null,
            ),
            tooltip: printerState.connected?.name ?? 'Belum ada printer',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrinterScreen()),
            ),
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return const _EmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final qty = selected[product.id];
              final isSelected = qty != null;

              return ListTile(
                leading: Checkbox(
                  value: isSelected,
                  onChanged: (_) => ref
                      .read(selectedProductIdsProvider.notifier)
                      .toggle(product.id),
                ),
                title: Text(product.name),
                subtitle: Text(formatRupiah(product.price)),
                trailing: isSelected
                    ? _QuantityStepper(
                        qty: qty,
                        onChanged: (newQty) => ref
                            .read(selectedProductIdsProvider.notifier)
                            .setQuantity(product.id, newQty),
                      )
                    : IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductFormScreen(existing: product),
                          ),
                        ),
                      ),
                onTap: () => ref
                    .read(selectedProductIdsProvider.notifier)
                    .toggle(product.id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (selected.isNotEmpty)
            FloatingActionButton.extended(
              heroTag: 'print',
              onPressed: () => _handlePrint(context, ref),
              icon: const Icon(Icons.print),
              label: Text('Cetak ${selected.length} label'),
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

  Future<void> _handlePrint(BuildContext context, WidgetRef ref) async {
    final printerState = ref.read(printerProvider);
    if (printerState.connected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hubungkan printer terlebih dahulu')),
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PrinterScreen()),
      );
      return;
    }

    final products = ref.read(productListProvider).value ?? <Product>[];
    final selected = ref.read(selectedProductIdsProvider);
    final toPrint =
        products.where((p) => selected.containsKey(p.id)).toList();

    final success = await PrintService.printLabels(
      products: toPrint,
      quantities: selected,
      paperSizeMm: 58, // ganti ke 80 jika memakai kertas 80mm
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Label berhasil dicetak' : 'Gagal mencetak label'),
      ),
    );

    if (success) {
      ref.read(selectedProductIdsProvider.notifier).clear();
    }
  }
}

class _QuantityStepper extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onChanged;

  const _QuantityStepper({required this.qty, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: qty > 1 ? () => onChanged(qty - 1) : null,
        ),
        Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => onChanged(qty + 1),
        ),
      ],
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
