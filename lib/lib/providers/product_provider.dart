import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Semua produk beserta daftar satuan-harganya, otomatis update.
final productListProvider = StreamProvider<List<ProductWithUnits>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchProductsWithUnits();
});

/// Kata kunci pencarian nama barang.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Hasil produk setelah difilter oleh [searchQueryProvider].
/// Produk tanpa satuan yang cocok pencarian tetap tampil apa adanya
/// (filter hanya berdasarkan nama produk, bukan nama satuan).
final filteredProductListProvider = Provider<AsyncValue<List<ProductWithUnits>>>(
  (ref) {
    final query = ref.watch(searchQueryProvider).trim().toLowerCase();
    final productsAsync = ref.watch(productListProvider);

    return productsAsync.whenData((list) {
      if (query.isEmpty) return list;
      return list
          .where((p) => p.product.name.toLowerCase().contains(query))
          .toList();
    });
  },
);

/// Item satuan yang dipilih untuk dicetak: { unitId: jumlah label }.
/// Disimpan bersama data produk+satuannya agar layar preview tidak perlu
/// query ulang.
class SelectedUnitItem {
  final ProductUnit unit;
  final String productName;
  final int quantity;

  const SelectedUnitItem({
    required this.unit,
    required this.productName,
    required this.quantity,
  });

  SelectedUnitItem copyWith({int? quantity}) => SelectedUnitItem(
        unit: unit,
        productName: productName,
        quantity: quantity ?? this.quantity,
      );
}

final selectedUnitsProvider =
    StateNotifierProvider<SelectedUnitsNotifier, Map<int, SelectedUnitItem>>(
  (ref) => SelectedUnitsNotifier(),
);

class SelectedUnitsNotifier extends StateNotifier<Map<int, SelectedUnitItem>> {
  SelectedUnitsNotifier() : super({});

  void toggle(ProductUnit unit, String productName) {
    final next = Map<int, SelectedUnitItem>.from(state);
    if (next.containsKey(unit.id)) {
      next.remove(unit.id);
    } else {
      next[unit.id] = SelectedUnitItem(
        unit: unit,
        productName: productName,
        quantity: 1,
      );
    }
    state = next;
  }

  void setQuantity(int unitId, int qty) {
    if (qty <= 0) return;
    final current = state[unitId];
    if (current == null) return;
    state = {
      ...state,
      unitId: current.copyWith(quantity: qty),
    };
  }

  void remove(int unitId) {
    final next = Map<int, SelectedUnitItem>.from(state);
    next.remove(unitId);
    state = next;
  }

  /// Buang seleksi yang unitId-nya sudah tidak ada lagi di database
  /// (misal satuan/produknya baru saja dihapus atau diedit).
  void pruneToExisting(Set<int> validUnitIds) {
    if (state.isEmpty) return;
    final next = Map<int, SelectedUnitItem>.from(state)
      ..removeWhere((unitId, _) => !validUnitIds.contains(unitId));
    if (next.length != state.length) {
      state = next;
    }
  }

  void clear() => state = {};
}
