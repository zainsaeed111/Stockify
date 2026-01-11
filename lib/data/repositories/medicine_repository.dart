import 'package:drift/drift.dart' hide Batch;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';

final medicineRepositoryProvider = Provider((ref) => MedicineRepository(ref.watch(databaseProvider)));

class MedicineRepository {
  final AppDatabase _db;

  MedicineRepository(this._db);

  Future<List<Medicine>> getAllMedicines() => _db.select(_db.medicines).get();
  Stream<List<Medicine>> watchAllMedicines() => _db.select(_db.medicines).watch();
  
  Future<int> addMedicine(MedicinesCompanion medicine) => _db.into(_db.medicines).insert(medicine);
  Future<bool> updateMedicine(Medicine medicine) => _db.update(_db.medicines).replace(medicine);
  Future<int> deleteMedicine(int id) => (_db.delete(_db.medicines)..where((t) => t.id.equals(id))).go();

  // Batches
  Future<List<Batch>> getBatchesForMedicine(int medicineId) => 
      (_db.select(_db.batches)..where((t) => t.medicineId.equals(medicineId))).get();
      
  Stream<List<Batch>> watchBatchesForMedicine(int medicineId) => 
      (_db.select(_db.batches)..where((t) => t.medicineId.equals(medicineId))).watch();

  Future<int> addBatch(BatchesCompanion batch) => _db.into(_db.batches).insert(batch);
  
  // Stock Management
  Future<void> updateStock(int batchId, int quantityChange) async {
    // This should be transactional in a real app
    final batch = await (_db.select(_db.batches)..where((t) => t.id.equals(batchId))).getSingle();
    final newQuantity = batch.quantity + quantityChange;
    await (_db.update(_db.batches)..where((t) => t.id.equals(batchId))).write(BatchesCompanion(
      quantity: Value(newQuantity),
    ));
  }
  
  Stream<List<MedicineWithStock>> watchMedicinesWithStock() {
    final query = _db.select(_db.medicines).join([
      leftOuterJoin(_db.batches, _db.batches.medicineId.equalsExp(_db.medicines.id))
    ]);

    return query.watch().map((rows) {
      final grouped = <Medicine, List<Batch>>{};
      for (final row in rows) {
        final med = row.readTable(_db.medicines);
        final batch = row.readTableOrNull(_db.batches);
        
        if (!grouped.containsKey(med)) {
          grouped[med] = [];
        }
        if (batch != null) {
          grouped[med]!.add(batch);
        }
      }

      return grouped.entries.map((entry) {
        final med = entry.key;
        final batches = entry.value;

        // Calculate aggregates
        final totalQty = batches.fold(0, (sum, b) => sum + b.quantity);
        
        // Use latest batch (by ID) for display price
        Batch? latestBatch;
        if (batches.isNotEmpty) {
           latestBatch = batches.reduce((curr, next) => next.id > curr.id ? next : curr);
        }

        return MedicineWithStock(
          medicine: med,
          totalQuantity: totalQty,
          latestPrice: latestBatch?.salePrice ?? 0.0,
          packSize: latestBatch?.packSize ?? 1,
        );
      }).toList();
    });
  }
}

class MedicineWithStock {
  final Medicine medicine;
  final int totalQuantity;
  final double latestPrice; // Unit Sale Price
  final int packSize;      // Context from latest batch

  MedicineWithStock({
    required this.medicine,
    required this.totalQuantity,
    required this.latestPrice,
    required this.packSize,
  });
}
