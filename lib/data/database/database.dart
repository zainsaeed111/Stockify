import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// --- Core Tables ---

@DataClassName('User')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get role => text()(); // Admin, Manager, Cashier
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

@DataClassName('Setting')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

// --- Inventory Tables ---

@DataClassName('Medicine')
class Medicines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get code => text().unique()(); // Barcode/Unique ID
  TextColumn get mainCategory => text().withDefault(const Constant('Medicine'))(); // Medicine, Inventory, General, Electronics
  TextColumn get subCategory => text().nullable()(); // Tablet, Syrup, etc.
  TextColumn get manufacturer => text().nullable()();
  TextColumn get description => text().nullable()();
  IntColumn get minStock => integer().withDefault(const Constant(10))(); // Low stock alert level
}

@DataClassName('Batch')
class Batches extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get medicineId => integer().references(Medicines, #id)();
  TextColumn get batchNumber => text()();
  DateTimeColumn get expiryDate => dateTime()();
  RealColumn get purchasePrice => real()();
  RealColumn get salePrice => real()();
  IntColumn get quantity => integer()(); // Current stock in this batch
}

// --- Sales & Billing Tables ---

@DataClassName('Sale')
class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text().unique()();
  // Removed patientId
  DateTimeColumn get date => dateTime()();
  RealColumn get subTotal => real()();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get tax => real().withDefault(const Constant(0.0))();
  RealColumn get grandTotal => real()();
  TextColumn get paymentMethod => text().withDefault(const Constant('Cash'))();
  IntColumn get userId => integer().nullable().references(Users, #id)(); // Who processed the sale
}

@DataClassName('SaleItem')
class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  IntColumn get batchId => integer().references(Batches, #id)();
  IntColumn get quantity => integer()();
  RealColumn get price => real()(); // Price at moment of sale
  RealColumn get total => real()();
}

@DriftDatabase(tables: [Users, Settings, Medicines, Batches, Sales, SaleItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3; // Bumped version

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 3) {
          // For dev, we might need to recreate tables or add columns
          // Adding columns to Medicines
          try {
            await m.addColumn(medicines, medicines.mainCategory);
            await m.addColumn(medicines, medicines.subCategory);
          } catch (e) {
            // Columns might already exist if re-running
          }
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pharmacy_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
