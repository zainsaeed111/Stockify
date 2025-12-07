import 'package:drift/drift.dart' as drift;
import '../data/database/database.dart';

/// Script to populate database with realistic Pakistani pharmacy sample data
class SampleDataImporter {
  final AppDatabase database;

  SampleDataImporter(this.database);

  /// Import all sample data
  Future<void> importAllData() async {
    print('🚀 Starting sample data import (200 items)...');
    
    // Check if data exists
    final existing = await database.select(database.medicines).get();
    if (existing.length > 10) {
      print('Data already exists, skipping large import.');
      return;
    }

    final medicines = [
      _Med('Paracetamol 500mg tablet', 'Paracetamol', 'GSK Pakistan', 35),
      _Med('Paracetamol 500mg tablet', 'Paracetamol Plus', 'Abbott Laboratories Pakistan', 40),
      _Med('Paracetamol 500mg tablet', 'Paracetamol Forte', 'Getz Pharma', 45),
      _Med('Paracetamol 500mg tablet', 'Paracetamol DS', 'Sami Pharmaceuticals', 50),
      _Med('Paracetamol 120mg/5ml syrup', 'Paracetamol', 'GSK Pakistan', 60),
      _Med('Paracetamol 120mg/5ml syrup', 'Paracetamol Plus', 'Abbott Laboratories Pakistan', 65),
      _Med('Paracetamol 120mg/5ml syrup', 'Paracetamol Forte', 'Getz Pharma', 70),
      _Med('Paracetamol 120mg/5ml syrup', 'Paracetamol DS', 'Sami Pharmaceuticals', 75),
      _Med('Ibuprofen 400mg tablet', 'Ibuprofen', 'GSK Pakistan', 80),
      _Med('Ibuprofen 400mg tablet', 'Ibuprofen Plus', 'Abbott Laboratories Pakistan', 85),
      _Med('Ibuprofen 400mg tablet', 'Ibuprofen Forte', 'Getz Pharma', 90),
      _Med('Ibuprofen 400mg tablet', 'Ibuprofen DS', 'Sami Pharmaceuticals', 95),
      _Med('Ibuprofen 200mg tablet', 'Ibuprofen', 'GSK Pakistan', 50),
      _Med('Ibuprofen 200mg tablet', 'Ibuprofen Plus', 'Abbott Laboratories Pakistan', 55),
      _Med('Ibuprofen 200mg tablet', 'Ibuprofen Forte', 'Getz Pharma', 60),
      _Med('Ibuprofen 200mg tablet', 'Ibuprofen DS', 'Sami Pharmaceuticals', 65),
      _Med('Amoxicillin 500mg capsule', 'Amoxicillin', 'GSK Pakistan', 180),
      _Med('Amoxicillin 500mg capsule', 'Amoxicillin Plus', 'Abbott Laboratories Pakistan', 185),
      _Med('Amoxicillin 500mg capsule', 'Amoxicillin Forte', 'Getz Pharma', 190),
      _Med('Amoxicillin 500mg capsule', 'Amoxicillin DS', 'Sami Pharmaceuticals', 195),
      _Med('Co-amoxiclav 625mg tablet', 'Co-amoxiclav', 'GSK Pakistan', 270),
      _Med('Co-amoxiclav 625mg tablet', 'Co-amoxiclav Plus', 'Abbott Laboratories Pakistan', 275),
      _Med('Co-amoxiclav 625mg tablet', 'Co-amoxiclav Forte', 'Getz Pharma', 280),
      _Med('Co-amoxiclav 625mg tablet', 'Co-amoxiclav DS', 'Sami Pharmaceuticals', 285),
      _Med('Azithromycin 500mg tablet', 'Azithromycin', 'GSK Pakistan', 350),
      _Med('Azithromycin 500mg tablet', 'Azithromycin Plus', 'Abbott Laboratories Pakistan', 355),
      _Med('Azithromycin 500mg tablet', 'Azithromycin Forte', 'Getz Pharma', 360),
      _Med('Azithromycin 500mg tablet', 'Azithromycin DS', 'Sami Pharmaceuticals', 365),
      _Med('Azithromycin 250mg capsule', 'Azithromycin', 'GSK Pakistan', 280),
      _Med('Azithromycin 250mg capsule', 'Azithromycin Plus', 'Abbott Laboratories Pakistan', 285),
      _Med('Azithromycin 250mg capsule', 'Azithromycin Forte', 'Getz Pharma', 290),
      _Med('Azithromycin 250mg capsule', 'Azithromycin DS', 'Sami Pharmaceuticals', 295),
      _Med('Cefixime 400mg capsule', 'Cefixime', 'GSK Pakistan', 420),
      _Med('Cefixime 400mg capsule', 'Cefixime Plus', 'Abbott Laboratories Pakistan', 425),
      _Med('Cefixime 400mg capsule', 'Cefixime Forte', 'Getz Pharma', 430),
      _Med('Cefixime 400mg capsule', 'Cefixime DS', 'Sami Pharmaceuticals', 435),
      _Med('Cefixime 200mg tablet', 'Cefixime', 'GSK Pakistan', 260),
      _Med('Cefixime 200mg tablet', 'Cefixime Plus', 'Abbott Laboratories Pakistan', 265),
      _Med('Cefixime 200mg tablet', 'Cefixime Forte', 'Getz Pharma', 270),
      _Med('Cefixime 200mg tablet', 'Cefixime DS', 'Sami Pharmaceuticals', 275),
      _Med('Ciprofloxacin 500mg tablet', 'Ciprofloxacin', 'GSK Pakistan', 220),
      _Med('Ciprofloxacin 500mg tablet', 'Ciprofloxacin Plus', 'Abbott Laboratories Pakistan', 225),
      _Med('Ciprofloxacin 500mg tablet', 'Ciprofloxacin Forte', 'Getz Pharma', 230),
      _Med('Ciprofloxacin 500mg tablet', 'Ciprofloxacin DS', 'Sami Pharmaceuticals', 235),
      _Med('Levofloxacin 500mg tablet', 'Levofloxacin', 'GSK Pakistan', 260),
      _Med('Levofloxacin 500mg tablet', 'Levofloxacin Plus', 'Abbott Laboratories Pakistan', 265),
      _Med('Levofloxacin 500mg tablet', 'Levofloxacin Forte', 'Getz Pharma', 270),
      _Med('Levofloxacin 500mg tablet', 'Levofloxacin DS', 'Sami Pharmaceuticals', 275),
      _Med('Metronidazole 400mg tablet', 'Metronidazole', 'GSK Pakistan', 45),
      _Med('Metronidazole 400mg tablet', 'Metronidazole Plus', 'Abbott Laboratories Pakistan', 50),
      _Med('Metronidazole 400mg tablet', 'Metronidazole Forte', 'Getz Pharma', 55),
      _Med('Metronidazole 400mg tablet', 'Metronidazole DS', 'Sami Pharmaceuticals', 60),
      _Med('Omeprazole 20mg capsule', 'Omeprazole', 'GSK Pakistan', 120),
      _Med('Omeprazole 20mg capsule', 'Omeprazole Plus', 'Abbott Laboratories Pakistan', 125),
      _Med('Omeprazole 20mg capsule', 'Omeprazole Forte', 'Getz Pharma', 130),
      _Med('Omeprazole 20mg capsule', 'Omeprazole DS', 'Sami Pharmaceuticals', 135),
      _Med('Esomeprazole 40mg capsule', 'Esomeprazole', 'GSK Pakistan', 200),
      _Med('Esomeprazole 40mg capsule', 'Esomeprazole Plus', 'Abbott Laboratories Pakistan', 205),
      _Med('Esomeprazole 40mg capsule', 'Esomeprazole Forte', 'Getz Pharma', 210),
      _Med('Esomeprazole 40mg capsule', 'Esomeprazole DS', 'Sami Pharmaceuticals', 215),
      _Med('Pantoprazole 40mg tablet', 'Pantoprazole', 'GSK Pakistan', 190),
      _Med('Pantoprazole 40mg tablet', 'Pantoprazole Plus', 'Abbott Laboratories Pakistan', 195),
      _Med('Pantoprazole 40mg tablet', 'Pantoprazole Forte', 'Getz Pharma', 200),
      _Med('Pantoprazole 40mg tablet', 'Pantoprazole DS', 'Sami Pharmaceuticals', 205),
      _Med('Domperidone 10mg tablet', 'Domperidone', 'GSK Pakistan', 80),
      _Med('Domperidone 10mg tablet', 'Domperidone Plus', 'Abbott Laboratories Pakistan', 85),
      _Med('Domperidone 10mg tablet', 'Domperidone Forte', 'Getz Pharma', 90),
      _Med('Domperidone 10mg tablet', 'Domperidone DS', 'Sami Pharmaceuticals', 95),
      _Med('Ondansetron 4mg tablet', 'Ondansetron', 'GSK Pakistan', 140),
      _Med('Ondansetron 4mg tablet', 'Ondansetron Plus', 'Abbott Laboratories Pakistan', 145),
      _Med('Ondansetron 4mg tablet', 'Ondansetron Forte', 'Getz Pharma', 150),
      _Med('Ondansetron 4mg tablet', 'Ondansetron DS', 'Sami Pharmaceuticals', 155),
      _Med('Cetirizine 10mg tablet', 'Cetirizine', 'GSK Pakistan', 60),
      _Med('Cetirizine 10mg tablet', 'Cetirizine Plus', 'Abbott Laboratories Pakistan', 65),
      _Med('Cetirizine 10mg tablet', 'Cetirizine Forte', 'Getz Pharma', 70),
      _Med('Cetirizine 10mg tablet', 'Cetirizine DS', 'Sami Pharmaceuticals', 75),
      _Med('Loratadine 10mg tablet', 'Loratadine', 'GSK Pakistan', 70),
      _Med('Loratadine 10mg tablet', 'Loratadine Plus', 'Abbott Laboratories Pakistan', 75),
      _Med('Loratadine 10mg tablet', 'Loratadine Forte', 'Getz Pharma', 80),
      _Med('Loratadine 10mg tablet', 'Loratadine DS', 'Sami Pharmaceuticals', 85),
      _Med('Montelukast 10mg tablet', 'Montelukast', 'GSK Pakistan', 220),
      _Med('Montelukast 10mg tablet', 'Montelukast Plus', 'Abbott Laboratories Pakistan', 225),
      _Med('Montelukast 10mg tablet', 'Montelukast Forte', 'Getz Pharma', 230),
      _Med('Montelukast 10mg tablet', 'Montelukast DS', 'Sami Pharmaceuticals', 235),
      _Med('Salbutamol 2mg tablet', 'Salbutamol', 'GSK Pakistan', 50),
      _Med('Salbutamol 2mg tablet', 'Salbutamol Plus', 'Abbott Laboratories Pakistan', 55),
      _Med('Salbutamol 2mg tablet', 'Salbutamol Forte', 'Getz Pharma', 60),
      _Med('Salbutamol 2mg tablet', 'Salbutamol DS', 'Sami Pharmaceuticals', 65),
      _Med('Salbutamol 100mcg inhaler', 'Salbutamol', 'GSK Pakistan', 350),
      _Med('Salbutamol 100mcg inhaler', 'Salbutamol Plus', 'Abbott Laboratories Pakistan', 355),
      _Med('Salbutamol 100mcg inhaler', 'Salbutamol Forte', 'Getz Pharma', 360),
      _Med('Salbutamol 100mcg inhaler', 'Salbutamol DS', 'Sami Pharmaceuticals', 365),
      _Med('Prednisolone 5mg tablet', 'Prednisolone', 'GSK Pakistan', 40),
      _Med('Prednisolone 5mg tablet', 'Prednisolone Plus', 'Abbott Laboratories Pakistan', 45),
      _Med('Prednisolone 5mg tablet', 'Prednisolone Forte', 'Getz Pharma', 50),
      _Med('Prednisolone 5mg tablet', 'Prednisolone DS', 'Sami Pharmaceuticals', 55),
      _Med('Dexamethasone 0.5mg tablet', 'Dexamethasone', 'GSK Pakistan', 35),
      _Med('Dexamethasone 0.5mg tablet', 'Dexamethasone Plus', 'Abbott Laboratories Pakistan', 40),
      _Med('Dexamethasone 0.5mg tablet', 'Dexamethasone Forte', 'Getz Pharma', 45),
      _Med('Dexamethasone 0.5mg tablet', 'Dexamethasone DS', 'Sami Pharmaceuticals', 50),
      _Med('Metformin 500mg tablet', 'Metformin', 'GSK Pakistan', 90),
      _Med('Metformin 500mg tablet', 'Metformin Plus', 'Abbott Laboratories Pakistan', 95),
      _Med('Metformin 500mg tablet', 'Metformin Forte', 'Getz Pharma', 100),
      _Med('Metformin 500mg tablet', 'Metformin DS', 'Sami Pharmaceuticals', 105),
      _Med('Metformin 850mg tablet', 'Metformin', 'GSK Pakistan', 140),
      _Med('Metformin 850mg tablet', 'Metformin Plus', 'Abbott Laboratories Pakistan', 145),
      _Med('Metformin 850mg tablet', 'Metformin Forte', 'Getz Pharma', 150),
      _Med('Metformin 850mg tablet', 'Metformin DS', 'Sami Pharmaceuticals', 155),
      _Med('Glimepiride 2mg tablet', 'Glimepiride', 'GSK Pakistan', 130),
      _Med('Glimepiride 2mg tablet', 'Glimepiride Plus', 'Abbott Laboratories Pakistan', 135),
      _Med('Glimepiride 2mg tablet', 'Glimepiride Forte', 'Getz Pharma', 140),
      _Med('Glimepiride 2mg tablet', 'Glimepiride DS', 'Sami Pharmaceuticals', 145),
      _Med('Insulin Regular 100IU vial', 'Insulin', 'GSK Pakistan', 420),
      _Med('Insulin Regular 100IU vial', 'Insulin Plus', 'Abbott Laboratories Pakistan', 425),
      _Med('Insulin Regular 100IU vial', 'Insulin Forte', 'Getz Pharma', 430),
      _Med('Insulin Regular 100IU vial', 'Insulin DS', 'Sami Pharmaceuticals', 435),
      _Med('Insulin NPH 100IU vial', 'Insulin', 'GSK Pakistan', 430),
      _Med('Insulin NPH 100IU vial', 'Insulin Plus', 'Abbott Laboratories Pakistan', 435),
      _Med('Insulin NPH 100IU vial', 'Insulin Forte', 'Getz Pharma', 440),
      _Med('Insulin NPH 100IU vial', 'Insulin DS', 'Sami Pharmaceuticals', 445),
      _Med('Losartan 50mg tablet', 'Losartan', 'GSK Pakistan', 170),
      _Med('Losartan 50mg tablet', 'Losartan Plus', 'Abbott Laboratories Pakistan', 175),
      _Med('Losartan 50mg tablet', 'Losartan Forte', 'Getz Pharma', 180),
      _Med('Losartan 50mg tablet', 'Losartan DS', 'Sami Pharmaceuticals', 185),
      _Med('Amlodipine 5mg tablet', 'Amlodipine', 'GSK Pakistan', 80),
      _Med('Amlodipine 5mg tablet', 'Amlodipine Plus', 'Abbott Laboratories Pakistan', 85),
      _Med('Amlodipine 5mg tablet', 'Amlodipine Forte', 'Getz Pharma', 90),
      _Med('Amlodipine 5mg tablet', 'Amlodipine DS', 'Sami Pharmaceuticals', 95),
      _Med('Enalapril 5mg tablet', 'Enalapril', 'GSK Pakistan', 90),
      _Med('Enalapril 5mg tablet', 'Enalapril Plus', 'Abbott Laboratories Pakistan', 95),
      _Med('Enalapril 5mg tablet', 'Enalapril Forte', 'Getz Pharma', 100),
      _Med('Enalapril 5mg tablet', 'Enalapril DS', 'Sami Pharmaceuticals', 105),
      _Med('Bisoprolol 5mg tablet', 'Bisoprolol', 'GSK Pakistan', 150),
      _Med('Bisoprolol 5mg tablet', 'Bisoprolol Plus', 'Abbott Laboratories Pakistan', 155),
      _Med('Bisoprolol 5mg tablet', 'Bisoprolol Forte', 'Getz Pharma', 160),
      _Med('Bisoprolol 5mg tablet', 'Bisoprolol DS', 'Sami Pharmaceuticals', 165),
      _Med('Furosemide 40mg tablet', 'Furosemide', 'GSK Pakistan', 50),
      _Med('Furosemide 40mg tablet', 'Furosemide Plus', 'Abbott Laboratories Pakistan', 55),
      _Med('Furosemide 40mg tablet', 'Furosemide Forte', 'Getz Pharma', 60),
      _Med('Furosemide 40mg tablet', 'Furosemide DS', 'Sami Pharmaceuticals', 65),
      _Med('Atorvastatin 20mg tablet', 'Atorvastatin', 'GSK Pakistan', 220),
      _Med('Atorvastatin 20mg tablet', 'Atorvastatin Plus', 'Abbott Laboratories Pakistan', 225),
      _Med('Atorvastatin 20mg tablet', 'Atorvastatin Forte', 'Getz Pharma', 230),
      _Med('Atorvastatin 20mg tablet', 'Atorvastatin DS', 'Sami Pharmaceuticals', 235),
      _Med('Rosuvastatin 10mg tablet', 'Rosuvastatin', 'GSK Pakistan', 260),
      _Med('Rosuvastatin 10mg tablet', 'Rosuvastatin Plus', 'Abbott Laboratories Pakistan', 265),
      _Med('Rosuvastatin 10mg tablet', 'Rosuvastatin Forte', 'Getz Pharma', 270),
      _Med('Rosuvastatin 10mg tablet', 'Rosuvastatin DS', 'Sami Pharmaceuticals', 275),
      _Med('Aspirin 75mg tablet', 'Aspirin', 'GSK Pakistan', 40),
      _Med('Aspirin 75mg tablet', 'Aspirin Plus', 'Abbott Laboratories Pakistan', 45),
      _Med('Aspirin 75mg tablet', 'Aspirin Forte', 'Getz Pharma', 50),
      _Med('Aspirin 75mg tablet', 'Aspirin DS', 'Sami Pharmaceuticals', 55),
      _Med('Clopidogrel 75mg tablet', 'Clopidogrel', 'GSK Pakistan', 260),
      _Med('Clopidogrel 75mg tablet', 'Clopidogrel Plus', 'Abbott Laboratories Pakistan', 265),
      _Med('Clopidogrel 75mg tablet', 'Clopidogrel Forte', 'Getz Pharma', 270),
      _Med('Clopidogrel 75mg tablet', 'Clopidogrel DS', 'Sami Pharmaceuticals', 275),
      _Med('Warfarin 5mg tablet', 'Warfarin', 'GSK Pakistan', 60),
      _Med('Warfarin 5mg tablet', 'Warfarin Plus', 'Abbott Laboratories Pakistan', 65),
      _Med('Warfarin 5mg tablet', 'Warfarin Forte', 'Getz Pharma', 70),
      _Med('Warfarin 5mg tablet', 'Warfarin DS', 'Sami Pharmaceuticals', 75),
      _Med('Omeprazole 40mg capsule', 'Omeprazole', 'GSK Pakistan', 180),
      _Med('Omeprazole 40mg capsule', 'Omeprazole Plus', 'Abbott Laboratories Pakistan', 185),
      _Med('Omeprazole 40mg capsule', 'Omeprazole Forte', 'Getz Pharma', 190),
      _Med('Omeprazole 40mg capsule', 'Omeprazole DS', 'Sami Pharmaceuticals', 195),
      _Med('Calcium carbonate 500mg tablet', 'Calcium', 'GSK Pakistan', 160),
      _Med('Calcium carbonate 500mg tablet', 'Calcium Plus', 'Abbott Laboratories Pakistan', 165),
      _Med('Calcium carbonate 500mg tablet', 'Calcium Forte', 'Getz Pharma', 170),
      _Med('Calcium carbonate 500mg tablet', 'Calcium DS', 'Sami Pharmaceuticals', 175),
      _Med('Vitamin D3 50000IU capsule', 'VitD', 'GSK Pakistan', 280),
      _Med('Vitamin D3 50000IU capsule', 'VitD Plus', 'Abbott Laboratories Pakistan', 285),
      _Med('Vitamin D3 50000IU capsule', 'VitD Forte', 'Getz Pharma', 290),
      _Med('Vitamin D3 50000IU capsule', 'VitD DS', 'Sami Pharmaceuticals', 295),
      _Med('Ferrous sulphate 200mg tablet', 'Ferrous', 'GSK Pakistan', 90),
      _Med('Ferrous sulphate 200mg tablet', 'Ferrous Plus', 'Abbott Laboratories Pakistan', 95),
      _Med('Ferrous sulphate 200mg tablet', 'Ferrous Forte', 'Getz Pharma', 100),
      _Med('Ferrous sulphate 200mg tablet', 'Ferrous DS', 'Sami Pharmaceuticals', 105),
      _Med('Folic acid 5mg tablet', 'Folic', 'GSK Pakistan', 40),
      _Med('Folic acid 5mg tablet', 'Folic Plus', 'Abbott Laboratories Pakistan', 45),
      _Med('Folic acid 5mg tablet', 'Folic Forte', 'Getz Pharma', 50),
      _Med('Folic acid 5mg tablet', 'Folic DS', 'Sami Pharmaceuticals', 55),
      _Med('ORS sachet', 'ORS', 'GSK Pakistan', 30),
      _Med('ORS sachet', 'ORS Plus', 'Abbott Laboratories Pakistan', 35),
      _Med('ORS sachet', 'ORS Forte', 'Getz Pharma', 40),
      _Med('ORS sachet', 'ORS DS', 'Sami Pharmaceuticals', 45),
      _Med('Loperamide 2mg capsule', 'Loperamide', 'GSK Pakistan', 60),
      _Med('Loperamide 2mg capsule', 'Loperamide Plus', 'Abbott Laboratories Pakistan', 65),
      _Med('Loperamide 2mg capsule', 'Loperamide Forte', 'Getz Pharma', 70),
      _Med('Loperamide 2mg capsule', 'Loperamide DS', 'Sami Pharmaceuticals', 75),
      _Med('Ranitidine 150mg tablet', 'Ranitidine', 'GSK Pakistan', 80),
      _Med('Ranitidine 150mg tablet', 'Ranitidine Plus', 'Abbott Laboratories Pakistan', 85),
      _Med('Ranitidine 150mg tablet', 'Ranitidine Forte', 'Getz Pharma', 90),
      _Med('Ranitidine 150mg tablet', 'Ranitidine DS', 'Sami Pharmaceuticals', 95),
      _Med('Hydroxyzine 25mg tablet', 'Hydroxyzine', 'GSK Pakistan', 70),
      _Med('Hydroxyzine 25mg tablet', 'Hydroxyzine Plus', 'Abbott Laboratories Pakistan', 75),
      _Med('Hydroxyzine 25mg tablet', 'Hydroxyzine Forte', 'Getz Pharma', 80),
      _Med('Hydroxyzine 25mg tablet', 'Hydroxyzine DS', 'Sami Pharmaceuticals', 85),
      _Med('Multivitamin tablet', 'Multivita', 'Obs Pakistan', 250),
      _Med('Vitamin B Complex tablet', 'Neurobion', 'Merck Pakistan', 220),
      _Med('ORS with zinc sachet', 'Zinc ORS', 'PharmEvo', 45),
      _Med('Omeprazole 40mg injection', 'Losec Inj', 'AstraZeneca Pakistan', 320),
    ];

    print('📦 Importing ${medicines.length} items...');

    int importedCount = 0;
    for (final med in medicines) {
      try {
        await _addMedicine(med);
        importedCount++;
      } catch (e) {
        print('Error importing ${med.brand}: $e');
      }
    }
    
    print('✅ Import finished. Imported $importedCount medicines.');
  }

  Future<void> _addMedicine(_Med med) async {
    // Generate code
    final code = '${med.brand.substring(0, 3).toUpperCase()}${DateTime.now().microsecondsSinceEpoch.toString().substring(10)}';
    
    final insertedMed = await database.into(database.medicines).insertReturning(
      MedicinesCompanion(
        code: drift.Value(code),
        name: drift.Value('${med.brand} - ${med.generic}'),
        mainCategory: const drift.Value('Medicine'),
        manufacturer: drift.Value(med.company),
        description: const drift.Value('Sample Item'),
      ),
    );
    
    // Add Batch with stock
    await database.into(database.batches).insert(
      BatchesCompanion(
        medicineId: drift.Value(insertedMed.id),
        batchNumber: drift.Value('BAT-${DateTime.now().millisecondsSinceEpoch}'),
        expiryDate: drift.Value(DateTime.now().add(const Duration(days: 365))),
        quantity: const drift.Value(100), // Default stock
        purchasePrice: drift.Value(med.price * 0.7), // 30% margin approx
        salePrice: drift.Value(med.price),
      ),
    );
  }
}

class _Med {
  final String generic;
  final String brand;
  final String company;
  final double price;
  _Med(this.generic, this.brand, this.company, this.intPrice) : price = intPrice.toDouble();
  final int intPrice;
}
