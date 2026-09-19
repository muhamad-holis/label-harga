import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';

/// Instance database, hidup selama aplikasi berjalan.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Stream daftar produk, otomatis update saat ada tambah/edit/hapus.
final productListProvider = StreamProvider<List<Product>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllProducts();
});

/// Set produk (by id) yang sedang dipilih untuk dicetak labelnya.
final selectedProductIdsProvider =
    StateNotifierProvider<SelectedProductsNotifier, Map<int, int>>(
  (ref) => SelectedProductsNotifier(),
);

/// Menyimpan { productId: jumlahLabel } untuk sesi cetak saat ini.
class SelectedProductsNotifier extends StateNotifier<Map<int, int>> {
  SelectedProductsNotifier() : super({});

  void toggle(int productId) {
    final next = Map<int, int>.from(state);
    if (next.containsKey(productId)) {
      next.remove(productId);
    } else {
      next[productId] = 1;
    }
    state = next;
  }

  void setQuantity(int productId, int qty) {
    if (qty <= 0) return;
    final next = Map<int, int>.from(state);
    next[productId] = qty;
    state = next;
  }

  void clear() => state = {};
}
