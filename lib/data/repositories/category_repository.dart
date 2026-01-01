import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryRepository(db);
});

class CategoryRepository {
  final AppDatabase _db;
  
  CategoryRepository(this._db);
  
  // Default categories when none exist
  static const defaultCategories = {
    'General': ['Miscellaneous'],
    'Medicine': ['Tablet', 'Syrup', 'Injection', 'Cream', 'Drops', 'Capsule'],
    'Food': ['Deal', 'Starter', 'Main Course', 'Dessert', 'Beverage', 'Fast Food'],
    'Electronics': ['Mobile', 'Laptop', 'Accessories', 'Appliances'],
    'Clothing': ['Men', 'Women', 'Kids', 'Accessories'],
  };
  
  /// Get all main categories (parentId == null)
  Future<List<Category>> getMainCategories() async {
    return await (_db.select(_db.categories)
      ..where((c) => c.parentId.isNull()))
      .get();
  }
  
  /// Get subcategories for a given parent ID
  Future<List<Category>> getSubcategories(int parentId) async {
    return await (_db.select(_db.categories)
      ..where((c) => c.parentId.equals(parentId)))
      .get();
  }
  
  /// Get all categories (flat list)
  Future<List<Category>> getAllCategories() async {
    return await _db.select(_db.categories).get();
  }
  
  /// Get category by ID
  Future<Category?> getCategoryById(int id) async {
    return await (_db.select(_db.categories)
      ..where((c) => c.id.equals(id)))
      .getSingleOrNull();
  }
  
  /// Get category by name
  Future<Category?> getCategoryByName(String name, {int? parentId}) async {
    if (parentId == null) {
      return await (_db.select(_db.categories)
        ..where((c) => c.name.equals(name) & c.parentId.isNull()))
        .getSingleOrNull();
    } else {
      return await (_db.select(_db.categories)
        ..where((c) => c.name.equals(name) & c.parentId.equals(parentId)))
        .getSingleOrNull();
    }
  }
  
  /// Add a new category
  Future<int> addCategory({
    required String name,
    int? parentId,
    String? description,
    String? imageUrl,
  }) async {
    return await _db.into(_db.categories).insert(
      CategoriesCompanion.insert(
        name: name,
        parentId: Value(parentId),
        description: Value(description),
        imageUrl: Value(imageUrl),
      ),
    );
  }
  
  /// Update a category
  Future<bool> updateCategory({
    required int id,
    required String name,
    String? description,
    String? imageUrl,
  }) async {
    return await (_db.update(_db.categories)
      ..where((c) => c.id.equals(id)))
      .write(CategoriesCompanion(
        name: Value(name),
        description: Value(description),
        imageUrl: Value(imageUrl),
      )) > 0;
  }
  
  /// Delete a category (and its subcategories)
  Future<int> deleteCategory(int id) async {
    // First delete all subcategories
    await (_db.delete(_db.categories)..where((c) => c.parentId.equals(id))).go();
    // Then delete the category itself
    return await (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
  }
  
  /// Initialize default categories if none exist
  Future<void> initializeDefaultCategories() async {
    final existing = await getAllCategories();
    if (existing.isNotEmpty) return; // Already has categories
    
    for (final mainCat in defaultCategories.entries) {
      final mainCatId = await addCategory(name: mainCat.key);
      
      for (final subCat in mainCat.value) {
        await addCategory(name: subCat, parentId: mainCatId);
      }
    }
  }
  
  /// Get categories as a map for dropdowns (main category name -> list of subcategory names)
  Future<Map<String, List<String>>> getCategoriesAsMap() async {
    final mainCats = await getMainCategories();
    final result = <String, List<String>>{};
    
    for (final cat in mainCats) {
      final subs = await getSubcategories(cat.id);
      result[cat.name] = subs.map((s) => s.name).toList();
    }
    
    // If empty, return defaults
    if (result.isEmpty) {
      return defaultCategories;
    }
    
    return result;
  }
  
  /// Get main category names for dropdown
  Future<List<String>> getMainCategoryNames() async {
    final cats = await getMainCategories();
    if (cats.isEmpty) return defaultCategories.keys.toList();
    return cats.map((c) => c.name).toList();
  }
  
  /// Get subcategory names for a main category
  Future<List<String>> getSubcategoryNames(String mainCategoryName) async {
    final mainCat = await getCategoryByName(mainCategoryName);
    if (mainCat == null) {
      return defaultCategories[mainCategoryName] ?? [];
    }
    final subs = await getSubcategories(mainCat.id);
    return subs.map((s) => s.name).toList();
  }
}
