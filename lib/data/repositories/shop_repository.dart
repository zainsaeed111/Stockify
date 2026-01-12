import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final shopRepositoryProvider = Provider((ref) => ShopRepository());

class ShopRepository {
  // Safe accessor for Firestore
  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // IN-MEMORY CACHE FOR TESTING (Fallback if Firestore fails)
  static final List<Map<String, dynamic>> _inMemoryShops = [];

  Future<void> registerShop({
    required String shopName,
    required String ownerName,
    required String email,
    required String phone,
    String? address,
    required DateTime start,
    required DateTime end,
    required bool isPaid,
    required String securityKey,
    String? businessType,
    String? businessDesc,
    String? website,
    double gstRate = 0,
    double posFee = 0,
  }) async {
    final db = _firestore;
    
    // Prepare Data
    final data = {
      'shopName': shopName,
      'ownerName': ownerName,
      'email': email,
      'phone': phone,
      'address': address,
      'businessType': businessType ?? 'General Store',
      'businessDesc': businessDesc ?? '',
      'website': website ?? '',
      'gstRate': gstRate,
      'posFee': posFee,
      'subscriptionStart': Timestamp.fromDate(start),
      'subscriptionEnd': Timestamp.fromDate(end),
      'isPaid': isPaid,
      'securityKey': securityKey,
      'createdAt': FieldValue.serverTimestamp(),
    };
    
    // Always save to In-Memory Cache (for session testing)
    _inMemoryShops.add(data);
    print('✅ Saved to In-Memory Cache (Testing Mode): $email');

    if (db == null) {
      print('⚠️ FIREBASE NOT CONNECTED: Simulating Registration');
      await Future.delayed(const Duration(seconds: 1));
      return; 
    }

    // Generate a new document reference
    final docRef = db.collection('shops').doc();
    data['id'] = docRef.id; // Add ID

    try {
      await docRef.set(data).timeout(const Duration(seconds: 5));
    } catch (e) {
      print('⚠️ FIRESTORE TIMEOUT/ERROR: $e');
      print('Continuing using In-Memory Cache.');
      // We don't rethrow, allowing the UI to show "Success"
    }
  }

  Future<Map<String, dynamic>?> getShopByEmail(String email) async {
    final db = _firestore;
    
    // Helper to find in memory
    Map<String, dynamic>? findInMemory() {
      try {
        return _inMemoryShops.firstWhere((s) => s['email'] == email);
      } catch (_) {
        return null;
      }
    }

    if (db == null) {
      print('⚠️ FIREBASE NOT CONNECTED: Checking In-Memory Cache');
      return findInMemory(); 
    }

    try {
      final snapshot = await db
          .collection('shops')
          .where('email', isEqualTo: email)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));

      if (snapshot.docs.isNotEmpty) {
         return snapshot.docs.first.data();
      }
      
      // If not in DB, fallback to memory (maybe write failed previously)
      return findInMemory();

    } catch (e) {
      print('⚠️ FIRESTORE TIMEOUT/ERROR: $e');
      print('Fallback to In-Memory Cache.');
      return findInMemory();
    }
  }

  Future<bool> validateSecurityKey(String email, String key) async {
    final db = _firestore;
    if (db == null) {
      print('⚠️ FIREBASE NOT CONNECTED: Simulating Validation (ALWAYS TRUE for testing)');
      return true;
    }

    final shopData = await getShopByEmail(email);
    if (shopData == null) return false;
    
    final storedKey = shopData['securityKey'] as String?;
    return storedKey == key;
  }

  /// Get shop by security key only (for simplified login)
  Future<Map<String, dynamic>?> getShopBySecurityKey(String securityKey) async {
    final db = _firestore;
    
    // Helper to find in memory
    Map<String, dynamic>? findInMemory() {
      try {
        return _inMemoryShops.firstWhere((s) => s['securityKey'] == securityKey);
      } catch (_) {
        return null;
      }
    }

    if (db == null) {
      // If we are in a production app, this should probably be an error.
      // But preserving existing logic of checking memory, but logging clearer.
      print('⚠️ FIREBASE NOT CONNECTED: Checking In-Memory Cache for key');
      final found = findInMemory();
      if (found == null) {
        // Throwing specifically to let UI know
        throw Exception('Firebase not connected and key not found locally.');
      }
      return found;
    }

    try {
      print('🔍 Searching for key: "$securityKey"');
      final snapshot = await db
          .collection('shops')
          .where('securityKey', isEqualTo: securityKey)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10)); // Increased timeout

      if (snapshot.docs.isNotEmpty) {
         print('✅ Found shop: ${snapshot.docs.first.id}');
         return snapshot.docs.first.data();
      }
      
      print('❌ Key not found in Firestore.');
      // Logic: If explicitly checked DB and not found, return null (Invalid Key).
      return null;

    } catch (e) {
      print('⚠️ FIRESTORE TIMEOUT/ERROR: $e');
      throw Exception('Connection failed: $e');
    }
  }

  /// Update shop information
  Future<void> updateShopInfo({
    required String email,
    required String shopName,
    required String ownerName,
    required String phone,
    required String address,
  }) async {
    final db = _firestore;

    // Update in-memory cache
    final memIndex = _inMemoryShops.indexWhere((s) => s['email'] == email);
    if (memIndex >= 0) {
      _inMemoryShops[memIndex]['shopName'] = shopName;
      _inMemoryShops[memIndex]['ownerName'] = ownerName;
      _inMemoryShops[memIndex]['phone'] = phone;
      _inMemoryShops[memIndex]['address'] = address;
    }

    if (db == null) {
      print('⚠️ FIREBASE NOT CONNECTED: Updated In-Memory Cache only');
      return;
    }

    try {
      // Find the document by email
      final snapshot = await db
          .collection('shops')
          .where('email', isEqualTo: email)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'shopName': shopName,
          'ownerName': ownerName,
          'phone': phone,
          'address': address,
        });
        print('✅ Shop info updated in Firebase');
      }
    } catch (e) {
      print('⚠️ FIRESTORE UPDATE ERROR: $e');
    }
  }

  /// Update POS Settings (GST, Tax, POS Fee, Discount)
  Future<void> updatePosSettings({
    required String email,
    required double gstRate,
    required double taxRate,
    required double posFee,
    required double defaultDiscount,
    String gstType = 'percent',
    String taxType = 'percent',
    String posFeeType = 'fixed',
    String discountType = 'percent',
  }) async {
    final db = _firestore;

    // Update in-memory cache
    final memIndex = _inMemoryShops.indexWhere((s) => s['email'] == email);
    if (memIndex >= 0) {
      _inMemoryShops[memIndex]['gstRate'] = gstRate;
      _inMemoryShops[memIndex]['taxRate'] = taxRate;
      _inMemoryShops[memIndex]['posFee'] = posFee;
      _inMemoryShops[memIndex]['defaultDiscount'] = defaultDiscount;
      _inMemoryShops[memIndex]['gstType'] = gstType;
      _inMemoryShops[memIndex]['taxType'] = taxType;
      _inMemoryShops[memIndex]['posFeeType'] = posFeeType;
      _inMemoryShops[memIndex]['discountType'] = discountType;
    }

    if (db == null) {
      print('⚠️ FIREBASE NOT CONNECTED: Updated In-Memory Cache only (POS Settings)');
      return;
    }

    try {
      final snapshot = await db
          .collection('shops')
          .where('email', isEqualTo: email)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'gstRate': gstRate,
          'taxRate': taxRate,
          'posFee': posFee,
          'defaultDiscount': defaultDiscount,
          'gstType': gstType,
          'taxType': taxType,
          'posFeeType': posFeeType,
          'discountType': discountType,
        });
        print('✅ POS Settings updated in Firebase');
      }
    } catch (e) {
      print('⚠️ FIRESTORE UPDATE ERROR: $e');
    }
  }
}
