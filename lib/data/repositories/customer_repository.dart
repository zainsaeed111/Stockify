import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';

final customerRepositoryProvider = Provider((ref) => CustomerRepository(ref.watch(databaseProvider)));

class CustomerRepository {
  final AppDatabase _db;

  CustomerRepository(this._db);

  Future<List<Customer>> getAllCustomers() => _db.select(_db.customers).get();
  
  Stream<List<Customer>> watchAllCustomers() => _db.select(_db.customers).watch();
  
  Future<List<Customer>> searchCustomers(String query) {
    return (_db.select(_db.customers)
      ..where((c) => c.name.like('%$query%') | c.phoneNumber.like('%$query%')))
        .get();
  }

  Future<Customer?> getCustomerById(int id) {
    return (_db.select(_db.customers)..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  Future<Customer?> getCustomerByPhone(String phoneNumber) {
    return (_db.select(_db.customers)..where((c) => c.phoneNumber.equals(phoneNumber))).getSingleOrNull();
  }

  Future<int> addCustomer(CustomersCompanion customer) => _db.into(_db.customers).insert(customer);
  
  Future<bool> updateCustomer(Customer customer) => _db.update(_db.customers).replace(customer);
  
  Future<int> deleteCustomer(int id) => (_db.delete(_db.customers)..where((t) => t.id.equals(id))).go();

  // Create or get customer by name and phone
  Future<Customer> createOrGetCustomer(String name, String? phoneNumber) async {
    // If phone number provided, check if customer exists
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final existing = await getCustomerByPhone(phoneNumber);
      if (existing != null) {
        return existing;
      }
    }
    
    // Create new customer
    final customerId = await addCustomer(CustomersCompanion(
      name: Value(name),
      phoneNumber: Value(phoneNumber),
    ));
    
    return (await getCustomerById(customerId))!;
  }
}


