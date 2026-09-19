import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/history_provider.dart';
import '../providers/printer_provider.dart';
import '../providers/product_provider.dart' show databaseProvider;
import '../services/print_service.dart';
import '../utils/currency_formatter.dart';
import 'printer_screen.dart';

final _dateFormat = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Cetak')),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return const Center(child: Text('Belum ada riwayat cetak'));
          }
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final entry = history[index];
              return ListTile(
                title: Text('${entry.productName} / ${entry.unitLabel}'),
                subtitle: Text(
                  '${formatRupiah(entry.price)} x ${entry.quantity} label\n'
                  '${_dateFormat.format(entry.printedAt)}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.print),
                  tooltip: 'Cetak ulang',
                  onPressed: () => _reprint(
                    context,
                    ref,
                    entry.productName,
                    entry.unitLabel,
                    entry.price,
                    entry.quantity,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
      ),
    );
  }

  Future<void> _reprint(
    BuildContext context,
    WidgetRef ref,
    String productName,
    String unitLabel,
    int price,
    int quantity,
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

    final success = await PrintService.printLabels(
      items: [
        LabelItem(
          productName: productName,
          unitLabel: unitLabel,
          price: price,
          quantity: quantity,
        ),
      ],
      paperSizeMm: 58,
    );

    if (success) {
      final db = ref.read(databaseProvider);
      await db.addHistoryEntry(
        productName: productName,
        unitLabel: unitLabel,
        price: price,
        quantity: quantity,
      );
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Berhasil cetak ulang' : 'Gagal mencetak'),
      ),
    );
  }
}
