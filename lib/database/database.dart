import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Tabel produk: menyimpan nama barang & harga yang pernah dibuatkan label.
/// Data ini yang membuat user bisa mencetak ulang label tanpa mengetik ulang.
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get price => integer()(); // harga dalam rupiah, tanpa desimal
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Products])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ---- Query produk ----

  Future<List<Product>> getAllProducts() {
    return (select(products)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Stream<List<Product>> watchAllProducts() {
    return (select(products)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<int> insertProduct(ProductsCompanion entry) {
    return into(products).insert(entry);
  }

  Future<bool> updateProduct(Product entry) {
    return update(products).replace(
      entry.copyWith(updatedAt: DateTime.now()),
    );
  }

  Future<int> deleteProduct(int id) {
    return (delete(products)..where((t) => t.id.equals(id))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'label_harga.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
