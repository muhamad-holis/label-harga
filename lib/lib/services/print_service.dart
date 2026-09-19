import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../database/database.dart';
import '../utils/currency_formatter.dart';

class PrintService {
  /// paperSize 58 atau 80 (mm), menentukan profil kertas ESC/POS.
  static Future<CapabilityProfile> _profile() =>
      CapabilityProfile.load();

  /// Mencetak satu label per produk sesuai jumlah yang diminta.
  /// [items] adalah map productId -> qty, [products] daftar produk lengkap.
  static Future<bool> printLabels({
    required List<Product> products,
    required Map<int, int> quantities,
    required int paperSizeMm, // 58 atau 80
  }) async {
    final profile = await _profile();
    final paper = paperSizeMm == 80 ? PaperSize.mm80 : PaperSize.mm58;
    final generator = Generator(paper, profile);

    List<int> bytes = [];

    for (final product in products) {
      final qty = quantities[product.id] ?? 0;
      for (int i = 0; i < qty; i++) {
        bytes += _buildSingleLabel(generator, product);
      }
    }

    if (bytes.isEmpty) return false;

    final bool connected = await PrintBluetoothThermal.connectionStatus;
    if (!connected) return false;

    return PrintBluetoothThermal.writeBytes(bytes);
  }

  /// Format satu label: nama produk (bold, besar) + harga (lebih besar,
  /// tengah) + garis putus-putus sebagai tanda potong.
  static List<int> _buildSingleLabel(Generator generator, Product product) {
    List<int> bytes = [];

    bytes += generator.text(
      product.name,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size1,
        width: PosTextSize.size1,
      ),
    );

    bytes += generator.text(
      formatRupiah(product.price),
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
