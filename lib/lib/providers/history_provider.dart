import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import 'product_provider.dart';

final historyListProvider = StreamProvider<List<PrintHistory>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchHistory();
});
