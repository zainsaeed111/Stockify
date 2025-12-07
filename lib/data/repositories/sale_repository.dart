import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';

final saleRepositoryProvider = Provider((ref) => SaleRepository(ref.watch(databaseProvider)));

class SaleRepository {
  final AppDatabase _db;

  SaleRepository(this._db);

  Future<List<Sale>> getAllSales() => _db.select(_db.sales).get();
  Stream<List<Sale>> watchAllSales() => _db.select(_db.sales).watch();

  Future<int> createSale(SalesCompanion sale, List<SaleItemsCompanion> items) {
    return _db.transaction(() async {
      final saleId = await _db.into(_db.sales).insert(sale);
      for (var item in items) {
        // Deduct stock
        final batchId = item.batchId.value;
        final qty = item.quantity.value;
        
        final batch = await (_db.select(_db.batches)..where((t) => t.id.equals(batchId))).getSingle();
        await (_db.update(_db.batches)..where((t) => t.id.equals(batchId))).write(BatchesCompanion(
          quantity: Value(batch.quantity - qty),
        ));

        await _db.into(_db.saleItems).insert(item.copyWith(saleId: Value(saleId)));
      }
      return saleId;
    });
  }

  Future<List<SaleItem>> getSaleItems(int saleId) => 
      (_db.select(_db.saleItems)..where((t) => t.saleId.equals(saleId))).get();
}
