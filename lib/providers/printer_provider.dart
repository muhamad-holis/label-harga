import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrinterDevice {
  final String name;
  final String macAddress;
  const PrinterDevice({required this.name, required this.macAddress});
}

class PrinterState {
  final List<PrinterDevice> pairedDevices;
  final PrinterDevice? connected;
  final bool isScanning;
  final bool isConnecting;
  final String? error;

  const PrinterState({
    this.pairedDevices = const [],
    this.connected,
    this.isScanning = false,
    this.isConnecting = false,
    this.error,
  });

  PrinterState copyWith({
    List<PrinterDevice>? pairedDevices,
    PrinterDevice? connected,
    bool clearConnected = false,
    bool? isScanning,
    bool? isConnecting,
    String? error,
    bool clearError = false,
  }) {
    return PrinterState(
      pairedDevices: pairedDevices ?? this.pairedDevices,
      connected: clearConnected ? null : (connected ?? this.connected),
      isScanning: isScanning ?? this.isScanning,
      isConnecting: isConnecting ?? this.isConnecting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final printerProvider =
    StateNotifierProvider<PrinterNotifier, PrinterState>((ref) {
  return PrinterNotifier();
});

/// Mengelola pairing list, koneksi, dan status printer Bluetooth thermal.
/// Catatan: printer harus sudah di-pairing lebih dulu lewat Pengaturan
/// Bluetooth Android sebelum muncul di daftar ini.
class PrinterNotifier extends StateNotifier<PrinterState> {
  PrinterNotifier() : super(const PrinterState());

  Future<void> loadPairedDevices() async {
    state = state.copyWith(isScanning: true, clearError: true);
    try {
      final bool permitted = await PrintBluetoothThermal.bluetoothEnabled;
      if (!permitted) {
        state = state.copyWith(
          isScanning: false,
          error: 'Bluetooth tidak aktif. Aktifkan Bluetooth terlebih dahulu.',
        );
        return;
      }
      final List<BluetoothInfo> list =
          await PrintBluetoothThermal.pairedBluetooths;
      state = state.copyWith(
        pairedDevices: list
            .map((d) => PrinterDevice(name: d.name, macAddress: d.macAdress))
            .toList(),
        isScanning: false,
      );
    } catch (e) {
      state = state.copyWith(isScanning: false, error: 'Gagal memuat daftar printer: $e');
    }
  }

  Future<bool> connect(PrinterDevice device) async {
    state = state.copyWith(isConnecting: true, clearError: true);
    try {
      final bool result =
          await PrintBluetoothThermal.connect(macPrinterAddress: device.macAddress);
      if (result) {
        state = state.copyWith(connected: device, isConnecting: false);
      } else {
        state = state.copyWith(
          isConnecting: false,
          error: 'Gagal terhubung ke ${device.name}. Pastikan printer menyala.',
        );
      }
      return result;
    } catch (e) {
      state = state.copyWith(isConnecting: false, error: 'Gagal terhubung: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    await PrintBluetoothThermal.disconnect;
    state = state.copyWith(clearConnected: true);
  }
}
