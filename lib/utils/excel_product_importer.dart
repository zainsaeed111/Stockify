import 'dart:io';
import 'package:billingly/data/database/database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';

class ExcelProductImporter {
  final AppDatabase db;

  ExcelProductImporter(this.db);

  Future<Map<String, int>> importProducts(String filePath) async {
    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    
    int importedCount = 0;
    int updatedCount = 0;
    int skippedCount = 0;

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null || sheet.maxRows <= 0) continue;

      // The analysis showed that each row might be a single string containing CSV data
      for (int i = 0; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;

        String rowData = '';
        if (row.length == 1 && row[0] != null) {
          // Single cell with comma separated data
          rowData = row[0]?.value?.toString() ?? '';
        } else {
          // Multiple cells - join them with commas to treat as CSV if needed, 
          // but better to just handle them as parts.
          // However, if the user says "showing comma separated already", 
          // it's likely the XML string we saw.
          rowData = row.map((m) => m?.value?.toString() ?? '').join(',');
        }

        if (rowData.isEmpty || rowData.toLowerCase().contains('medicine name')) {
          continue; // Skip empty or header
        }

        // Use CSV parser to handle quotes and multiple commas correctly
        final converter = const CsvToListConverter();
        final List<List<dynamic>> rows = converter.convert(rowData);
        if (rows.isEmpty || rows[0].length < 2) continue;
        
        final parts = rows[0].map((e) => e.toString().trim()).toList();
        
        // Mapping based on: Medicine Name,Formula,Company,Type,Pack Info,Price (PKR)
        final name = parts.length > 0 ? parts[0] : '';
        final formula = parts.length > 1 ? parts[1] : '';
        final company = parts.length > 2 ? parts[2] : '';
        final type = parts.length > 3 ? parts[3] : '';
        final packInfo = parts.length > 4 ? parts[4] : '';
        final priceStr = parts.length > 5 ? parts[5] : '0';
        
        if (name.isEmpty) continue;

        final salePricePack = double.tryParse(priceStr.replaceAll(',', '')) ?? 0.0;

        // 1. Category logic
        String mainCategory = 'General';
        if (type.toLowerCase().contains('tablet') || 
            type.toLowerCase().contains('syrup') || 
            type.toLowerCase().contains('injection') ||
            type.toLowerCase().contains('capsule') ||
            type.toLowerCase().contains('suspension') ||
            type.toLowerCase().contains('drops') ||
            type.toLowerCase().contains('cream') ||
            type.toLowerCase().contains('gel')) {
          mainCategory = 'Medicine';
        } else if (name.toLowerCase().contains('tablet') || name.toLowerCase().contains('syrup')) {
           mainCategory = 'Medicine';
        }

        // 2. Pack Size extraction
        int packSize = 1;
        if (packInfo.toLowerCase().contains('pack of')) {
          final match = RegExp(r'pack of (\d+)').firstMatch(packInfo.toLowerCase());
          if (match != null) {
            packSize = int.tryParse(match.group(1) ?? '1') ?? 1;
          }
        } else if (packInfo.toLowerCase().contains('bottle') || packInfo.toLowerCase().contains('ml')) {
          packSize = 1; // Syrups usually count as 1 unit per bottle
        }

        // 3. Unit Price calculation
        final unitPrice = salePricePack / packSize;

        // 4. Description mapping: "Formula: [Formula] \n Type: ([Type]) [Pack Info]"
        final description = "Formula: ${formula.isNotEmpty ? formula : 'N/A'}\nType: ($type) [${packInfo.isNotEmpty ? packInfo : 'Standard'}]";

        // 5. Duplicate check & Import/Update
        final existing = await (db.select(db.medicines)..where((t) => t.name.equals(name))).getSingleOrNull();

        int medicineId;
        if (existing != null) {
          medicineId = existing.id;
          await (db.update(db.medicines)..where((t) => t.id.equals(medicineId))).write(MedicinesCompanion(
            subtitle: drift.Value(formula),
            manufacturer: drift.Value(company),
            subCategory: drift.Value(type),
            description: drift.Value(description),
            mainCategory: drift.Value(mainCategory),
          ));
          updatedCount++;
        } else {
          final code = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-') + '-' + DateTime.now().millisecondsSinceEpoch.toString().substring(11);
          
          medicineId = await db.into(db.medicines).insert(MedicinesCompanion.insert(
            name: name,
            subtitle: drift.Value(formula),
            code: code,
            mainCategory: drift.Value(mainCategory),
            subCategory: drift.Value(type),
            manufacturer: drift.Value(company),
            description: drift.Value(description),
            minStock: const drift.Value(10),
          ));
          importedCount++;
        }

        // 6. Handle Batches (Pricing)
        final batches = await (db.select(db.batches)..where((t) => t.medicineId.equals(medicineId))).get();
        if (batches.isEmpty) {
          await db.into(db.batches).insert(BatchesCompanion.insert(
            medicineId: medicineId,
            batchNumber: 'INITIAL-IMPORT',
            expiryDate: DateTime.now().add(const Duration(days: 365 * 2)), 
            purchasePrice: 0.0, 
            salePrice: unitPrice,
            quantity: 0,
            packSize: drift.Value(packSize),
          ));
        } else {
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
