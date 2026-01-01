import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../data/repositories/category_repository.dart';
import '../../data/database/database.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> {
  List<Category> _mainCategories = [];
  Map<int, List<Category>> _subcategoriesMap = {};
  Set<int> _expandedCategories = {};
  bool _isLoading = true;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    
    try {
      final repo = ref.read(categoryRepositoryProvider);
      await repo.initializeDefaultCategories().timeout(
        const Duration(seconds: 5),
        onTimeout: () => debugPrint('Category initialization timed out'),
      );
      
      final mainCats = await repo.getMainCategories();
      final subsMap = <int, List<Category>>{};
      
      for (final cat in mainCats) {
        subsMap[cat.id] = await repo.getSubcategories(cat.id);
      }
      
      if (mounted) {
        setState(() {
          _mainCategories = mainCats;
          _subcategoriesMap = subsMap;
          _isLoading = false;
          // Auto-expand first category
          if (mainCats.isNotEmpty && _expandedCategories.isEmpty) {
            _expandedCategories.add(mainCats.first.id);
            _selectedCategoryId = mainCats.first.id;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String?> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
      
      if (image != null) {
        // Copy to app directory for persistence
        final appDir = await getApplicationDocumentsDirectory();
        final categoryImagesDir = Directory(p.join(appDir.path, 'category_images'));
        if (!await categoryImagesDir.exists()) {
          await categoryImagesDir.create(recursive: true);
        }
        
        final fileName = 'cat_${DateTime.now().millisecondsSinceEpoch}.png';
        final savedPath = p.join(categoryImagesDir.path, fileName);
        await File(image.path).copy(savedPath);
        
        return savedPath;
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
    }
    return null;
  }

  void _showCategoryDialog({Category? category, Category? parent, bool isSubcategory = false}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(text: category?.description ?? '');
    String? imagePath = category?.imageUrl;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSubcategory 
                        ? [Colors.orange.shade400, Colors.deepOrange.shade400]
                        : [Colors.teal.shade400, Colors.cyan.shade400],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSubcategory ? Icons.subdirectory_arrow_right : Icons.category,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category != null 
                          ? 'Edit ${isSubcategory ? "Subcategory" : "Category"}'
                          : 'Add ${isSubcategory ? "Subcategory" : "Category"}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (parent != null)
                      Text('Under: ${parent.name}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image Picker
                GestureDetector(
                  onTap: () async {
                    final path = await _pickImage();
                    if (path != null) {
                      setDialogState(() => imagePath = path);
                    }
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      image: imagePath != null && imagePath!.isNotEmpty
                          ? DecorationImage(
                              image: FileImage(File(imagePath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imagePath == null || imagePath!.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 4),
                              Text('Add Image', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              Text('(Optional)', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                            ],
                          )
                        : Stack(
                            children: [
                              Positioned(
                                top: 4,
                                right: 4,
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.red,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.close, size: 14, color: Colors.white),
                                    onPressed: () => setDialogState(() => imagePath = null),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Name Field
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: '${isSubcategory ? "Subcategory" : "Category"} Name *',
                    hintText: isSubcategory ? 'e.g., Hot Drinks' : 'e.g., Beverages',
                    prefixIcon: const Icon(Icons.label),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description Field
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Brief description...',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSubcategory ? Colors.orange : Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name is required')),
                  );
                  return;
                }
                
                final repo = ref.read(categoryRepositoryProvider);
                
                if (category != null) {
                  // Update existing
                  await repo.updateCategory(
                    id: category.id,
                    name: nameController.text.trim(),
                    description: descController.text.trim().isNotEmpty 
                        ? descController.text.trim() 
                        : null,
                    imageUrl: imagePath,
                  );
                } else {
                  // Add new
                  await repo.addCategory(
                    name: nameController.text.trim(),
                    parentId: parent?.id,
                    description: descController.text.trim().isNotEmpty 
                        ? descController.text.trim() 
                        : null,
                    imageUrl: imagePath,
                  );
                }
                
                if (ctx.mounted) Navigator.pop(ctx);
                _loadCategories();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(category != null ? 'Updated!' : 'Added!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: Icon(category != null ? Icons.save : Icons.add),
              label: Text(category != null ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Category category, {bool isSubcategory = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.delete_forever, color: Colors.red.shade700),
            ),
            const SizedBox(width: 12),
            const Text('Delete?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to delete "${category.name}"?',
              textAlign: TextAlign.center,
            ),
            if (!isSubcategory) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This will also delete all subcategories!',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final repo = ref.read(categoryRepositoryProvider);
              await repo.deleteCategory(category.id);
              
              if (ctx.mounted) Navigator.pop(ctx);
              _loadCategories();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Deleted!'), backgroundColor: Colors.red),
              );
            },
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    final subcategories = _subcategoriesMap[category.id] ?? [];
    final isExpanded = _expandedCategories.contains(category.id);
    final isSelected = _selectedCategoryId == category.id;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.teal : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: Colors.teal.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
            : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.white,
          child: Column(
            children: [
              // Main Category Header
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategoryId = category.id;
                    if (_expandedCategories.contains(category.id)) {
                      _expandedCategories.remove(category.id);
                    } else {
                      _expandedCategories.add(category.id);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Category Image or Icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: category.imageUrl != null && category.imageUrl!.isNotEmpty
                              ? null
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.teal.shade300, Colors.cyan.shade400],
                                ),
                          image: category.imageUrl != null && category.imageUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: FileImage(File(category.imageUrl!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: category.imageUrl == null || category.imageUrl!.isEmpty
                            ? const Icon(Icons.folder, color: Colors.white, size: 28)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      
                      // Category Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            if (category.description != null && category.description!.isNotEmpty)
                              Text(
                                category.description!,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            else
                              Row(
                                children: [
                                  Icon(Icons.layers, size: 14, color: Colors.grey.shade400),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${subcategories.length} subcategories',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      
                      // Action Buttons
                      IconButton(
                        icon: Icon(Icons.add, color: Colors.teal.shade400),
                        tooltip: 'Add Subcategory',
                        onPressed: () => _showCategoryDialog(parent: category, isSubcategory: true),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue.shade400),
                        tooltip: 'Edit',
                        onPressed: () => _showCategoryDialog(category: category),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red.shade400),
                        tooltip: 'Delete',
                        onPressed: () => _showDeleteConfirmation(category),
                      ),
                      if (subcategories.isNotEmpty)
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.grey.shade400,
                        ),
                    ],
                  ),
                ),
              ),
              
              // Subcategories
              if (isExpanded && subcategories.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Column(
                    children: subcategories.map((sub) => _buildSubcategoryTile(sub, category)).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubcategoryTile(Category sub, Category parent) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const SizedBox(width: 24),
            // Subcategory Image or Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: sub.imageUrl != null && sub.imageUrl!.isNotEmpty ? null : Colors.orange.shade100,
                image: sub.imageUrl != null && sub.imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: FileImage(File(sub.imageUrl!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: sub.imageUrl == null || sub.imageUrl!.isEmpty
                  ? Icon(Icons.label, color: Colors.orange.shade700, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            
            // Subcategory Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  if (sub.description != null && sub.description!.isNotEmpty)
                    Text(
                      sub.description!,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            
            // Actions
            IconButton(
              icon: Icon(Icons.edit, size: 18, color: Colors.blue.shade400),
              onPressed: () => _showCategoryDialog(category: sub, parent: parent, isSubcategory: true),
            ),
            IconButton(
              icon: Icon(Icons.delete, size: 18, color: Colors.red.shade400),
              onPressed: () => _showDeleteConfirmation(sub, isSubcategory: true),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.white],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade400, Colors.cyan.shade400],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.category, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Categories',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Organize your products',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                      onPressed: _loadCategories,
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _mainCategories.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.category_outlined, size: 64, color: Colors.teal.shade300),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'No categories yet',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add your first category to organize products',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => _showCategoryDialog(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add First Category'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _mainCategories.length,
                            itemBuilder: (context, index) => _buildCategoryCard(_mainCategories[index]),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _mainCategories.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: Colors.teal,
              onPressed: () => _showCategoryDialog(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Category', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }
}
