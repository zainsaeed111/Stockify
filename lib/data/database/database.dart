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

// --- Categories Table ---

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()(); // Category name (required)
  IntColumn get parentId => integer().nullable()(); // For subcategories - references parent category ID
  TextColumn get description => text().nullable()(); // Optional description
  TextColumn get imageUrl => text().nullable()(); // Optional image path/URL
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// --- Inventory Tables ---

@DataClassName('Medicine')
class Medicines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get code => text().unique()(); // Barcode/Unique ID
  TextColumn get mainCategory => text().withDefault(const Constant('General'))(); // Category name
  TextColumn get subCategory => text().nullable()(); // Subcategory name
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
  IntColumn get packSize => integer().withDefault(const Constant(1))(); // Added in v7
}

// --- Customer Tables ---

@DataClassName('Customer')
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()(); // Required
  TextColumn get phoneNumber => text().nullable()(); // Optional but validated if provided
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// --- Sales & Billing Tables ---

@DataClassName('Sale')
class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text().unique()();
  IntColumn get customerId => integer().nullable().references(Customers, #id)(); // Customer who made the purchase
  DateTimeColumn get date => dateTime()();
  RealColumn get subTotal => real()();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get tax => real().withDefault(const Constant(0.0))();
  RealColumn get posFee => real().withDefault(const Constant(0.0))(); // POS Fee column
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

@DriftDatabase(tables: [Users, Settings, Categories, Medicines, Batches, Customers, Sales, SaleItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 7; // Changed to 7

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 3) {
          try {
            await m.addColumn(medicines, medicines.mainCategory);
            await m.addColumn(medicines, medicines.subCategory);
          } catch (e) { /* ignore */ }
        }
        if (from < 4) {
          try {
            await m.createTable(customers);
            await m.addColumn(sales, sales.customerId);
          } catch (e) { /* ignore */ }
        }
        if (from < 5) {
          try {
            await m.createTable(categories);
          } catch (e) { /* ignore */ }
        }
        if (from < 6) {
          try {
            await m.addColumn(sales, sales.posFee);
          } catch (e) { /* ignore */ }
        }
        if (from < 7) {
          // Add packSize to Batches
          try {
            await m.addColumn(batches, batches.packSize);
          } catch (e) { /* ignore */ }
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
