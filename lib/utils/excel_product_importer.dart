import 'dart:io';
import 'package:billingly/data/database/database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

class ExcelProductImporter {
  final AppDatabase db;

  ExcelProductImporter(this.db);

  Future<Map<String, int>> importProducts(String filePath) async {
    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    
    int importedCount = 0;
    int skippedCount = 0;
    int updatedCount = 0;

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null || sheet.maxRows <= 1) continue;

      // Header mapping
      final headerRow = sheet.rows[0];
      int nameIdx = -1;
      int formulaIdx = -1;
      int companyIdx = -1;
      int typeIdx = -1;
      int packInfoIdx = -1;
      int priceIdx = -1;

      for (int i = 0; i < headerRow.length; i++) {
        final val = headerRow[i]?.value?.toString().toLowerCase() ?? '';
        if (val.contains('name')) nameIdx = i;
        else if (val.contains('formula')) formulaIdx = i;
        else if (val.contains('company')) companyIdx = i;
        else if (val.contains('type')) typeIdx = i;
        else if (val.contains('pack info')) packInfoIdx = i;
        else if (val.contains('price')) priceIdx = i;
      }

      if (nameIdx == -1) continue;

      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        if (row.length <= nameIdx || row[nameIdx] == null) continue;

        final name = row[nameIdx]?.value?.toString().trim() ?? '';
        if (name.isEmpty) continue;

        final formula = formulaIdx != -1 ? row[formulaIdx]?.value?.toString().trim() : null;
        final company = companyIdx != -1 ? row[companyIdx]?.value?.toString().trim() : null;
        final type = typeIdx != -1 ? row[typeIdx]?.value?.toString().trim() : null;
        final packInfo = packInfoIdx != -1 ? row[packInfoIdx]?.value?.toString().trim() : '';
        final priceStr = priceIdx != -1 ? row[priceIdx]?.value?.toString() : '0';
        final salePrice = double.tryParse(priceStr ?? '0') ?? 0.0;

        // Analysis: 
        // 1. Category logic
        String mainCategory = 'General';
        // If it's a medicine (most of these look like it), set as Medicine
        if (type != null && (type.toLowerCase().contains('tablet') || 
            type.toLowerCase().contains('syrup') || 
            type.toLowerCase().contains('injection') ||
            type.toLowerCase().contains('capsule') ||
            type.toLowerCase().contains('suspension'))) {
          mainCategory = 'Medicine';
        } else if (name.toLowerCase().contains('tablet') || name.toLowerCase().contains('syrup')) {
           mainCategory = 'Medicine';
        }

        // 2. Pack Size extraction
        int packSize = 1;
        if (packInfo != null && packInfo.toLowerCase().contains('pack of')) {
          final match = RegExp(r'pack of (\d+)').firstMatch(packInfo.toLowerCase());
          if (match != null) {
            packSize = int.tryParse(match.group(1) ?? '1') ?? 1;
          }
        }

        // 3. Duplicate check & Import
        final existing = await (db.select(db.medicines)..where((t) => t.name.equals(name))).getSingleOrNull();

        int medicineId;
        if (existing != null) {
          medicineId = existing.id;
          // Update existing if needed (subtitle/manufacturer etc)
          await (db.update(db.medicines)..where((t) => t.id.equals(medicineId))).write(MedicinesCompanion(
            subtitle: formula != null ? drift.Value(formula) : const drift.Value.absent(),
            manufacturer: company != null ? drift.Value(company) : const drift.Value.absent(),
            subCategory: type != null ? drift.Value(type) : const drift.Value.absent(),
          ));
          updatedCount++;
        } else {
          // Generate a unique code (slugified name + hash or just random)
          final code = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-') + '-' + DateTime.now().millisecondsSinceEpoch.toString().substring(10);
          
          medicineId = await db.into(db.medicines).insert(MedicinesCompanion.insert(
            name: name,
            subtitle: drift.Value(formula),
            code: code,
            mainCategory: drift.Value(mainCategory),
            subCategory: drift.Value(type),
            manufacturer: drift.Value(company),
            minStock: const drift.Value(10), // Default as requested
          ));
          importedCount++;
        }

        // 4. Create initial batch only if price is provided and it's a new medicine
        // or if we want to update the latest batch price.
        // For import, we'll add one default batch with the current price and 0 stock.
        final unitPrice = salePrice / packSize;
        final batches = await (db.select(db.batches)..where((t) => t.medicineId.equals(medicineId))).get();
        if (batches.isEmpty) {
          await db.into(db.batches).insert(BatchesCompanion.insert(
            medicineId: medicineId,
            batchNumber: 'INITIAL-IMPORT',
            expiryDate: DateTime.now().add(const Duration(days: 365 * 2)), // 2 years default
            purchasePrice: 0.0, // We don't have purchase price in XLSX
            salePrice: unitPrice,
            quantity: 0,
            packSize: drift.Value(packSize),
          ));
        } else {
          // Update the latest batch price if it was 0 or just update it
          final latest = batches.reduce((a, b) => a.id > b.id ? a : b);
          await (db.update(db.batches)..where((t) => t.id.equals(latest.id))).write(BatchesCompanion(
            salePrice: drift.Value(unitPrice),
            packSize: drift.Value(packSize),
          ));
        }
      }
    }

    return {
      'imported': importedCount,
      'updated': updatedCount,
      'skipped': skippedCount,
    };
  }
}
