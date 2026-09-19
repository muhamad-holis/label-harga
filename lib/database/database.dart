import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Master barang — hanya nama. Harga disimpan terpisah per satuan
/// (misal Dus/Pack/Pcs) di tabel [ProductUnits], karena satu barang
/// bisa dijual dengan beberapa satuan & harga berbeda.
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Satuan + harga untuk sebuah produk, misal:
/// (Indomie Goreng, "Dus", 120000), (Indomie Goreng, "Pcs", 3500)
/// Label satuan bebas diisi apa saja, tidak dibatasi dus/pack/pcs.
class ProductUnits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.cascade)();
  TextColumn get unitLabel => text().withLength(min: 1, max: 30)();
  IntColumn get price => integer()();
}

/// Snapshot tiap kali label dicetak, agar riwayat tetap utuh walau
/// produk aslinya sudah diubah/dihapus. Dipakai juga untuk "cetak ulang".
class PrintHistories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get productName => text()();
  TextColumn get unitLabel => text()();
  IntColumn get price => integer()();
  IntColumn get quantity => integer()();
  DateTimeColumn get printedAt => dateTime().withDefault(currentDateAndTime)();
}

class ProductWithUnits {
  final Product product;
  final List<ProductUnit> units;
  ProductWithUnits(this.product, this.units);
}

@DriftDatabase(tables: [Products, ProductUnits, PrintHistories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  // ---- Produk + satuan ----

  Stream<List<ProductWithUnits>> watchProductsWithUnits() {
    final productsStream = (select(products)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();

    return productsStream.asyncMap((productList) async {
      final result = <ProductWithUnits>[];
      for (final prod in productList) {
        final units = await (select(productUnits)
              ..where((u) => u.productId.equals(prod.id)))
            .get();
        result.add(ProductWithUnits(prod, units));
      }
      return result;
    });
  }

  Future<int> insertProduct(String name) {
    return into(products).insert(ProductsCompanion.insert(name: name));
  }

  Future<void> updateProductName(int id, String name) {
    return (update(products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(name: Value(name), updatedAt: Value(DateTime.now())),
    );
  }

  Future<void> deleteProduct(int id) {
    return (delete(products)..where((t) => t.id.equals(id))).go();
  }

  Future<int> insertUnit(int productId, String unitLabel, int price) {
    return into(productUnits).insert(
      ProductUnitsCompanion.insert(
        productId: productId,
        unitLabel: unitLabel,
        price: price,
      ),
    );
  }

  Future<void> updateUnit(int unitId, String unitLabel, int price) {
    return (update(productUnits)..where((t) => t.id.equals(unitId))).write(
      ProductUnitsCompanion(
        unitLabel: Value(unitLabel),
        price: Value(price),
      ),
    );
  }

  Future<void> deleteUnit(int unitId) {
    return (delete(productUnits)..where((t) => t.id.equals(unitId))).go();
  }

  // ---- Riwayat cetak ----

  Stream<List<PrintHistory>> watchHistory() {
    return (select(printHistories)
          ..orderBy([(t) => OrderingTerm.desc(t.printedAt)]))
        .watch();
  }

  Future<void> addHistoryEntry({
    required String productName,
    required String unitLabel,
    required int price,
    required int quantity,
  }) {
    return into(printHistories).insert(
      PrintHistoriesCompanion.insert(
        productName: productName,
        unitLabel: unitLabel,
        price: price,
        quantity: quantity,
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'label_harga.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
