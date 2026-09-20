import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/printer_provider.dart';
import '../services/print_service.dart';

class PrinterScreen extends ConsumerStatefulWidget {
  const PrinterScreen({super.key});

  @override
  ConsumerState<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends ConsumerState<PrinterScreen> {
  bool _isTestPrinting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(printerProvider.notifier).loadPairedDevices(),
    );
  }

  Future<void> _testPrint() async {
    setState(() => _isTestPrinting = true);
    final ok = await PrintService.testPrint(paperSizeMm: 58);
    if (!mounted) return;
    setState(() => _isTestPrinting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Test print terkirim ke printer' : 'Gagal mencetak, cek koneksi printer',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(printerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Printer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(printerProvider.notifier).loadPairedDevices(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.error != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(12),
              child: Text(
                state.error!,
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Pastikan printer sudah di-pairing lewat Pengaturan Bluetooth '
              'Android sebelum muncul di daftar ini.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          if (state.isScanning) const LinearProgressIndicator(),
          Expanded(
            child: state.pairedDevices.isEmpty && !state.isScanning
                ? const Center(child: Text('Tidak ada printer yang di-pairing'))
                : ListView.builder(
                    itemCount: state.pairedDevices.length,
                    itemBuilder: (context, index) {
                      final device = state.pairedDevices[index];
                      final isConnected =
                          state.connected?.macAddress == device.macAddress;

                      return ListTile(
                        leading: Icon(
                          Icons.print,
                          color: isConnected ? Colors.teal : null,
                        ),
                        title: Text(device.name),
                        subtitle: Text(device.macAddress),
                        trailing: isConnected
                            ? const Icon(Icons.check_circle, color: Colors.teal)
                            : (state.isConnecting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : null),
                        onTap: state.isConnecting
                            ? null
                            : () async {
                                final ok = await ref
                                    .read(printerProvider.notifier)
                                    .connect(device);
                                if (ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Terhubung ke ${device.name}')),
                                  );
                                }
                              },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: state.connected == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: _isTestPrinting ? null : _testPrint,
                  icon: _isTestPrinting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.receipt_long),
                  label: Text(
                    _isTestPrinting
                        ? 'Mencetak...'
                        : 'Test Print ke ${state.connected!.name}',
                  ),
                ),
              ),
            ),
    );
  }
}
