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
}
