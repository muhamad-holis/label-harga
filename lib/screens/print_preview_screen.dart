import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/printer_provider.dart';
import '../providers/product_provider.dart';
import '../services/print_service.dart';
import '../utils/currency_formatter.dart';
import 'printer_screen.dart';

class PrintPreviewScreen extends ConsumerStatefulWidget {
  const PrintPreviewScreen({super.key});

  @override
  ConsumerState<PrintPreviewScreen> createState() =>
      _PrintPreviewScreenState();
}

class _PrintPreviewScreenState extends ConsumerState<PrintPreviewScreen> {
  bool _printing = false;

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedUnitsProvider);
    final items = selected.values.toList();
    final totalLabel = items.fold<int>(0, (sum, e) => sum + e.quantity);

    return Scaffold(
      appBar: AppBar(title: const Text('Preview Label')),
      body: items.isEmpty
          ? const Center(child: Text('Tidak ada label dipilih'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _LabelPreviewCard(
                  productName: item.productName,
                  unitLabel: item.unit.unitLabel,
                  price: item.unit.price,
                  quantity: item.quantity,
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: (items.isEmpty || _printing)
                ? null
                : () => _handlePrint(context, items),
            icon: _printing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.print),
            label: Text(
              _printing ? 'Mencetak...' : 'Cetak Sekarang ($totalLabel label)',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePrint(
    BuildContext context,
    List<SelectedUnitItem> items,
  ) async {
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

    setState(() => _printing = true);

    final labelItems = items
        .map((e) => LabelItem(
              productName: e.productName,
              unitLabel: e.unit.unitLabel,
              price: e.unit.price,
              quantity: e.quantity,
            ))
        .toList();

    final success = await PrintService.printLabels(
      items: labelItems,
      paperSizeMm: 58, // ganti ke 80 jika memakai kertas 80mm
    );

    if (success) {
      final db = ref.read(databaseProvider);
      for (final item in labelItems) {
        await db.addHistoryEntry(
          productName: item.productName,
          unitLabel: item.unitLabel,
          price: item.price,
          quantity: item.quantity,
        );
      }
    }

    if (!mounted) return;
    setState(() => _printing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Label berhasil dicetak' : 'Gagal mencetak label'),
      ),
    );

    if (success) {
      ref.read(selectedUnitsProvider.notifier).clear();
      if (mounted) Navigator.of(context).pop();
    }
  }
}

/// Kartu preview yang meniru tampilan label asli: nama besar/bold,
/// satuan kecil, harga besar di tengah, garis gunting di bawah.
class _LabelPreviewCard extends StatelessWidget {
  final String productName;
  final String unitLabel;
  final int price;
  final int quantity;

  const _LabelPreviewCard({
    required this.productName,
    required this.unitLabel,
    required this.price,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              productName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '/ $unitLabel',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              formatRupiah(price),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Text(
              '- - - - - - gunting di sini - - - - - -',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Chip(label: Text('x$quantity lembar')),
            ),
          ],
        ),
      ),
    );
  }
}
