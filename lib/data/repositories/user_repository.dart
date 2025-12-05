import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../database/database.dart';
import '../database/database.dart';

final userRepositoryProvider = Provider((ref) => UserRepository(ref.watch(databaseProvider)));

class UserRepository {
  final AppDatabase _db;

  UserRepository(this._db);

  Future<User?> login(String username, String password) async {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes).toString();

    final query = _db.select(_db.users)
      ..where((t) => t.username.equals(username) & t.passwordHash.equals(hash) & t.isActive.equals(true));
    
    return query.getSingleOrNull();
  }

  Future<int> registerUser(String username, String password, String role) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes).toString();

    return _db.into(_db.users).insert(UsersCompanion(
      username: Value(username),
      passwordHash: Value(hash),
      role: Value(role),
    ));
  }

  Future<List<User>> getAllUsers() => _db.select(_db.users).get();
}
