import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../utils/currency_formatter.dart';

/// Satu baris label yang akan dicetak: nama barang, label satuan
/// (Dus/Pack/Pcs/dll), harga, dan berapa lembar yang mau dicetak.
class LabelItem {
  final String productName;
  final String unitLabel;
  final int price;
  final int quantity;

  const LabelItem({
    required this.productName,
    required this.unitLabel,
    required this.price,
    required this.quantity,
  });
}

class PrintService {
  static Future<CapabilityProfile> _profile() => CapabilityProfile.load();

  /// Mencetak setiap [LabelItem] sebanyak quantity-nya.
  static Future<bool> printLabels({
    required List<LabelItem> items,
    required int paperSizeMm, // 58 atau 80
  }) async {
    final profile = await _profile();
    final paper = paperSizeMm == 80 ? PaperSize.mm80 : PaperSize.mm58;
    final generator = Generator(paper, profile);

    List<int> bytes = [];
    for (final item in items) {
      for (int i = 0; i < item.quantity; i++) {
        bytes += _buildSingleLabel(generator, item);
      }
    }

    if (bytes.isEmpty) return false;

    final bool connected = await PrintBluetoothThermal.connectionStatus;
    if (!connected) return false;

    return PrintBluetoothThermal.writeBytes(bytes);
  }

  /// Cetak satu label uji coba, untuk memastikan printer & koneksi benar.
  static Future<bool> testPrint({required int paperSizeMm}) async {
    final bool connected = await PrintBluetoothThermal.connectionStatus;
    if (!connected) return false;

    final profile = await _profile();
    final paper = paperSizeMm == 80 ? PaperSize.mm80 : PaperSize.mm58;
    final generator = Generator(paper, profile);

    List<int> bytes = [];
    bytes += generator.text(
      'TEST PRINT',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.text(
      'Label Harga',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Printer terhubung dengan baik',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr(ch: '-');
    bytes += generator.feed(2);

    return PrintBluetoothThermal.writeBytes(bytes);
  }

  /// Format satu label: nama produk (bold) + satuan (kecil) + harga
  /// (besar, tengah) + garis potong.
  static List<int> _buildSingleLabel(Generator generator, LabelItem item) {
    List<int> bytes = [];

    bytes += generator.text(
      item.productName,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size1,
        width: PosTextSize.size1,
      ),
    );

    bytes += generator.text(
      '/ ${item.unitLabel}',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.text(
      formatRupiah(item.price),
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    bytes += generator.hr(ch: '-');
    bytes += generator.text(
      '- - - - - - gunting di sini - - - - - -',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(1);

    return bytes;
  }
}
