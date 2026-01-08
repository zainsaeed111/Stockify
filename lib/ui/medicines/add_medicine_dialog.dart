import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/database/database.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  final Medicine? medicine;

  const AddProductDialog({super.key, this.medicine});

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Product Fields
  late TextEditingController _nameController; // Used if custom text entered
  late TextEditingController _manufacturerController;
  late TextEditingController _minStockController;
  
  // Focus Nodes for keyboard navigation
  late FocusNode _nameFocus;
  late FocusNode _manufacturerFocus;
  late FocusNode _minStockFocus;
  late FocusNode _batchNoFocus;
  late FocusNode _qtyFocus;
  late FocusNode _purchasePriceFocus;
  late FocusNode _salePriceFocus;
  
  // Categories
  String? _selectedMainCategory;
  String? _selectedSubCategory;
  
  // Categories - loaded dynamically from database
  Map<String, List<String>> _categories = {};
  // Full category details for showing images/descriptions
  List<Category> _mainCategoryList = [];
  Map<int, List<Category>> _subcategoryMap = {};

  // Initial Batch Fields (Only for new products or adding stock to existing)
  late TextEditingController _batchNoController;
  late TextEditingController _qtyController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _salePriceController;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  // Autocomplete
  List<Medicine> _allMedicines = [];
  Medicine? _selectedExistingMedicine;

  // Form Visibility Settings
  bool _showManufacturer = true;
  bool _showMinStock = true;
  bool _showBatch = true;
  bool _showExpiry = true;
  bool _showPurchasePrice = true;
  bool _showCategory = true;
  bool _showSubCategory = true;

  @override
  void initState() {
    super.initState();
    _loadFormSettings();
    // Initialize Controllers
    _nameController = TextEditingController(text: widget.medicine?.name ?? '');
    _manufacturerController = TextEditingController(text: widget.medicine?.manufacturer ?? '');
    _minStockController = TextEditingController(text: widget.medicine?.minStock.toString() ?? '10');
    
    _batchNoController = TextEditingController();
    _qtyController = TextEditingController();
    _purchasePriceController = TextEditingController();
    _salePriceController = TextEditingController();

    // Initialize Focus Nodes
    _nameFocus = FocusNode();
    _manufacturerFocus = FocusNode();
    _minStockFocus = FocusNode();
    _batchNoFocus = FocusNode();
    _qtyFocus = FocusNode();
    _purchasePriceFocus = FocusNode();
    _salePriceFocus = FocusNode();

    // Set initial state from widget
    if (widget.medicine != null) {
      _selectedMainCategory = widget.medicine!.mainCategory;
      _selectedSubCategory = widget.medicine!.subCategory;
    }
    
    _selectedExistingMedicine = widget.medicine;
    
    // Load categories from database
    _loadCategories();
    
    // Load defaults if new product
    if (widget.medicine == null) {
      _loadLastCategory();
      _loadAllMedicines();
    }
    
    // Auto-focus logic handled in Autocomplete or via post-frame
  }

  Future<void> _loadFormSettings() async {
    final repo = ref.read(settingsRepositoryProvider);
    final showMfg = await repo.getSetting('form_show_manufacturer');
    final showMin = await repo.getSetting('form_show_min_stock');
    final showBatch = await repo.getSetting('form_show_batch_number');
    final showExp = await repo.getSetting('form_show_expiry_date');
    final showBuy = await repo.getSetting('form_show_purchase_price');
    final showCat = await repo.getSetting('form_show_category');
    final showSub = await repo.getSetting('form_show_sub_category');

    if (mounted) {
      setState(() {
        _showManufacturer = showMfg != 'false'; 
        _showMinStock = showMin != 'false';
        _showBatch = showBatch != 'false';
        _showExpiry = showExp != 'false';
        _showPurchasePrice = showBuy != 'false';
        _showCategory = showCat != 'false';
        _showSubCategory = showSub != 'false';
      });
    }
  }
  
  Future<void> _loadCategories() async {
    final repo = ref.read(categoryRepositoryProvider);
    final cats = await repo.getCategoriesAsMap();
    
    // Load full category details for images/descriptions
    final mainCats = await repo.getMainCategories();
    final subMap = <int, List<Category>>{};
    for (final cat in mainCats) {
      subMap[cat.id] = await repo.getSubcategories(cat.id);
    }
    
    if (mounted) {
      setState(() {
        _categories = cats;
        _mainCategoryList = mainCats;
        _subcategoryMap = subMap;
        // Ensure selected categories exist in loaded data
        if (_selectedMainCategory != null && !_categories.containsKey(_selectedMainCategory)) {
          _categories[_selectedMainCategory!] = [];
        }
        if (_selectedMainCategory != null && _selectedSubCategory != null) {
          if (!(_categories[_selectedMainCategory]?.contains(_selectedSubCategory) ?? false)) {
            _categories[_selectedMainCategory!]?.add(_selectedSubCategory!);
          }
        }
      });
    }
  }
  
  Category? _getMainCategoryDetails(String? name) {
    if (name == null) return null;
    try {
      return _mainCategoryList.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }
  
  Category? _getSubCategoryDetails(String? mainName, String? subName) {
    if (mainName == null || subName == null) return null;
    final mainCat = _getMainCategoryDetails(mainName);
    if (mainCat == null) return null;
    try {
      final subs = _subcategoryMap[mainCat.id] ?? [];
      return subs.firstWhere((c) => c.name == subName);
    } catch (_) {
      return null;
    }
  }

  void _ensureCategoryExists(String? main, String? sub) {
    if (main != null && main.isNotEmpty) {
      if (!_categories.containsKey(main)) {
        setState(() {
          _categories[main] = [];
        });
      }
      
      if (sub != null && sub.isNotEmpty) {
        if (_categories[main] != null && !_categories[main]!.contains(sub)) {
           setState(() {
             _categories[main]!.add(sub);
           });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _minStockController.dispose();
    _batchNoController.dispose();
    _qtyController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _nameFocus.dispose();
    _manufacturerFocus.dispose();
    _minStockFocus.dispose();
    _batchNoFocus.dispose();
    _qtyFocus.dispose();
    _purchasePriceFocus.dispose();
    _salePriceFocus.dispose();
    super.dispose();
  }

  Future<void> _loadAllMedicines() async {
    final repo = ref.read(medicineRepositoryProvider);
    final meds = await repo.getAllMedicines();
    if (mounted) {
      setState(() {
        _allMedicines = meds;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final repo = ref.read(medicineRepositoryProvider);
      final settingsRepo = ref.read(settingsRepositoryProvider);
      
      // Save category preference
      if (_selectedMainCategory != null) {
        await settingsRepo.saveSetting('last_main_category', _selectedMainCategory!);
      }
      if (_selectedSubCategory != null) {
        await settingsRepo.saveSetting('last_sub_category', _selectedSubCategory!);
      }

      int medicineId;

      if (_selectedExistingMedicine != null) {
        // Updating Existing Medicine (or just adding batch to it)
        medicineId = _selectedExistingMedicine!.id;
        await repo.updateMedicine(_selectedExistingMedicine!.copyWith(
          name: _nameController.text, // Allow Rename
          mainCategory: _selectedMainCategory ?? 'Medicine',
          subCategory: drift.Value(_selectedSubCategory),
          manufacturer: drift.Value(_manufacturerController.text),
          minStock: int.tryParse(_minStockController.text) ?? 10,
        ));
      } else {
        // Creating New Medicine
        medicineId = await repo.addMedicine(MedicinesCompanion(
          name: drift.Value(_nameController.text),
          mainCategory: drift.Value(_selectedMainCategory ?? 'Medicine'),
          subCategory: drift.Value(_selectedSubCategory),
          manufacturer: drift.Value(_manufacturerController.text),
          minStock: drift.Value(int.tryParse(_minStockController.text) ?? 10),
          code: drift.Value(DateTime.now().millisecondsSinceEpoch.toString()), // Auto-generate code
        ));
      }

      // Add Batch (if provided)
      // Always allow adding batch if fields are non-empty, even for existing items
      if (_batchNoController.text.isNotEmpty || _qtyController.text.isNotEmpty) {
         if (_batchNoController.text.isEmpty) {
           // If user forgot batch number but entered quantity, gen timestamp
           _batchNoController.text = 'B-${DateTime.now().millisecondsSinceEpoch}';
         }
         
        await repo.addBatch(BatchesCompanion(
          medicineId: drift.Value(medicineId),
          batchNumber: drift.Value(_batchNoController.text),
          quantity: drift.Value(int.tryParse(_qtyController.text) ?? 0),
          purchasePrice: drift.Value(double.tryParse(_purchasePriceController.text) ?? 0.0),
          salePrice: drift.Value(double.tryParse(_salePriceController.text) ?? 0.0),
          expiryDate: drift.Value(_expiryDate),
        ));
      }
      
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _loadLastCategory() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final lastMain = await settingsRepo.getSetting('last_main_category');
    final lastSub = await settingsRepo.getSetting('last_sub_category');
    
    if (mounted && _selectedMainCategory == null) {
      setState(() {
        if (lastMain != null && _categories.containsKey(lastMain)) {
          _selectedMainCategory = lastMain;
          if (lastSub != null && _categories[lastMain]!.contains(lastSub)) {
            _selectedSubCategory = lastSub;
          }
        } else {
          _selectedMainCategory = 'Medicine'; // Default
        }
      });
    }
  }

  void _onProductSelected(Medicine selection) {
    setState(() {
      _selectedExistingMedicine = selection;
      _nameController.text = selection.name;
      _manufacturerController.text = selection.manufacturer ?? '';
      _minStockController.text = selection.minStock.toString();
      _selectedMainCategory = selection.mainCategory;
      _selectedSubCategory = selection.subCategory;
      
      // Ensure the selected category exists in our dropdowns to avoid crash
      _ensureCategoryExists(_selectedMainCategory, _selectedSubCategory);
    });
    // Jump straight to adding stock
    _batchNoFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isNewEntry = widget.medicine == null && _selectedExistingMedicine == null;
    final isEditing = _selectedExistingMedicine != null;

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.enter): _SubmitIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): _CancelIntent(),
      },
      child: Actions(
        actions: {
          _SubmitIntent: CallbackAction<_SubmitIntent>(onInvoke: (_) => _handleSubmit()),
          _CancelIntent: CallbackAction<_CancelIntent>(onInvoke: (_) => Navigator.pop(context)),
        },
      child: Focus(
          autofocus: false, // Don't autofocus container, let widgets handle it
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 800; // Breakpoint for Tablet/Mobile
              
              return Dialog(
                insetPadding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  width: isMobile ? double.infinity : 900, 
                  height: isMobile ? double.infinity : 600,
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEditing ? 'Data Entry & Stock' : 'Add New Product',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.teal),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (isEditing)
                                    Text('Editing existing product (#${_selectedExistingMedicine!.id})', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              tooltip: 'Close (Esc)',
                            )
                          ],
                        ),
                    const Divider(height: 30),
                    Expanded(
                      child: isMobile 
                        ? SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildProductInfoSection(),
                                const SizedBox(height: 24),
                                const Divider(),
                                const SizedBox(height: 24),
                                _buildStockInfoSection(),
                              ],
                            ),
                          )
                        : Row(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             // LEFT COLUMN: Product Details
                             Expanded(
                               flex: 3,
                               child: SingleChildScrollView(
                                 child: _buildProductInfoSection(),
                               ), // End Left Col
                             ),
                             
                             const VerticalDivider(width: 48),
                             
                             // RIGHT COLUMN: Stock/Batch Details
                             Expanded(
                               flex: 4,
                               child: _buildStockInfoSection(),
                             ), // End Right Col
                           ],
                        ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Footer Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isMobile) ...[
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                            child: const Text('Cancel (Esc)'),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Expanded(
                          flex: isMobile ? 1 : 0,
                          child: ElevatedButton.icon(
                            onPressed: _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.check),
                            label: Text(
                               (_selectedExistingMedicine != null && _qtyController.text.isNotEmpty) ? 'Update & Add Stock' : 
                               (_selectedExistingMedicine != null) ? 'Update Product' : 'Save Product'
                            ),
                          ),
                        ),
                      ],
                    ),
                      ],
                    ),
                  ),
                ),
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 24, color: Colors.teal),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ],
    );
  }

  Widget _buildProductInfoSection() {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
       _buildSectionHeader('Product Info'),
       const SizedBox(height: 16),
       
       // Name / Search Field
       if (widget.medicine == null) // Search Mode
         LayoutBuilder(
           builder: (context, constraints) {
             return Autocomplete<Medicine>(
               optionsBuilder: (TextEditingValue textEditingValue) {
                 if (textEditingValue.text == '') {
                   return const Iterable<Medicine>.empty();
                 }
                 return _allMedicines.where((Medicine option) {
                   return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                 });
               },
               displayStringForOption: (Medicine option) => option.name,
               onSelected: _onProductSelected,
               optionsViewBuilder: (context, onSelected, options) {
                 return Align(
                   alignment: Alignment.topLeft,
                   child: Material(
                     elevation: 4.0,
                     child: SizedBox(
                       width: constraints.maxWidth,
                       child: ListView.builder(
                         padding: EdgeInsets.zero,
                         shrinkWrap: true,
                         itemCount: options.length,
                         itemBuilder: (BuildContext context, int index) {
                           final Medicine option = options.elementAt(index);
                           return ListTile(
                             title: Text(option.name),
                              subtitle: Text('${option.mainCategory} • Stock: ${option.id}'), // Dummy Stock ID for now
                             onTap: () => onSelected(option),
                           );
                         },
                       ),
                     ),
                   ),
                 );
               },
               fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  // Sync internal controller with autocomplete
                  textEditingController.addListener(() {
                    _nameController.text = textEditingController.text;
                    // If user clears text, reset selection
                    if(textEditingController.text.isEmpty && _selectedExistingMedicine != null) {
                      setState(() {
                        _selectedExistingMedicine = null;
                        // optionally reset other fields?
                      });
                    }
                  });
                  // If we already have a selection (e.g. from existing obj), set text
                  if (_nameController.text.isNotEmpty && textEditingController.text.isEmpty) {
                    textEditingController.text = _nameController.text;
                  }
                  
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Product Name', 
                      prefixIcon: Icon(Icons.search),
                      helperText: 'Type to search existing products',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _manufacturerFocus.requestFocus(),
                  );
               },
             );
           }
         )
       else // Direct Edit Mode (passed Medicine object)
         TextFormField(
           controller: _nameController,
           focusNode: _nameFocus,
           decoration: const InputDecoration(labelText: 'Product Name', prefixIcon: Icon(Icons.shopping_bag), border: OutlineInputBorder()),
           validator: (v) => v!.isEmpty ? 'Required' : null,
           textInputAction: TextInputAction.next,
           onFieldSubmitted: (_) => _manufacturerFocus.requestFocus(),
         ),

       const SizedBox(height: 16),
       
       if (isMobile) ...[
         DropdownButtonFormField<String>(
           value: _selectedMainCategory,
           decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category), border: OutlineInputBorder()),
           items: _categories.keys.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
           onChanged: (val) {
             setState(() {
               _selectedMainCategory = val;
               _selectedSubCategory = null; 
             });
           },
           validator: (v) => v == null ? 'Required' : null,
         ),
         const SizedBox(height: 16),
         DropdownButtonFormField<String>(
           value: _selectedSubCategory,
           decoration: const InputDecoration(labelText: 'Sub Category', prefixIcon: Icon(Icons.subdirectory_arrow_right), border: OutlineInputBorder()),
           items: _selectedMainCategory == null 
               ? [] 
               : _categories[_selectedMainCategory]!.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
           onChanged: (val) => setState(() => _selectedSubCategory = val),
         ),
       ] else 
       Row(
         children: [
           Expanded(
             child: DropdownButtonFormField<String>(
               value: _selectedMainCategory,
               decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category), border: OutlineInputBorder()),
               items: _categories.keys.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
               onChanged: (val) {
                 setState(() {
                   _selectedMainCategory = val;
                   _selectedSubCategory = null; 
                 });
               },
               validator: (v) => v == null ? 'Required' : null,
             ),
           ),
           const SizedBox(width: 12),
           Expanded(
             child: DropdownButtonFormField<String>(
               value: _selectedSubCategory,
               decoration: const InputDecoration(labelText: 'Sub Category', prefixIcon: Icon(Icons.subdirectory_arrow_right), border: OutlineInputBorder()),
               items: _selectedMainCategory == null 
                   ? [] 
                   : _categories[_selectedMainCategory]!.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
               onChanged: (val) => setState(() => _selectedSubCategory = val),
             ),
           ),
         ],
       ),
       
       const SizedBox(height: 16),
       
       TextFormField(
          controller: _manufacturerController,
          focusNode: _manufacturerFocus,
          decoration: const InputDecoration(labelText: 'Manufacturer / Brand', prefixIcon: Icon(Icons.factory), border: OutlineInputBorder()),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _minStockFocus.requestFocus(),
       ),
       
       const SizedBox(height: 16),
       
       TextFormField(
          controller: _minStockController,
          focusNode: _minStockFocus,
          decoration: const InputDecoration(labelText: 'Low Stock Alert Level', prefixIcon: Icon(Icons.warning_amber), border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _batchNoFocus.requestFocus(),
       ),
     ],
   );
  }

  Widget _buildStockInfoSection() {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
     padding: const EdgeInsets.all(20),
     decoration: BoxDecoration(
       color: Colors.teal.shade50.withOpacity(0.5),
       borderRadius: BorderRadius.circular(12),
       border: Border.all(color: Colors.teal.shade100),
     ),
     child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         _buildSectionHeader('Add Stock / Batch'),
         const SizedBox(height: 8),
         Text('Enter new stock details below. Leave empty if just updating product info.', 
           style: TextStyle(fontSize: 12, color: Colors.grey[700], fontStyle: FontStyle.italic)),
         const SizedBox(height: 24),
         
         if (isMobile) ...[
            TextFormField(
              controller: _batchNoController,
              focusNode: _batchNoFocus,
              decoration: const InputDecoration(labelText: 'Batch Number', prefixIcon: Icon(Icons.qr_code), filled: true, fillColor: Colors.white),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _qtyFocus.requestFocus(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _qtyController,
              focusNode: _qtyFocus,
              decoration: const InputDecoration(labelText: 'Quantity', prefixIcon: Icon(Icons.numbers), filled: true, fillColor: Colors.white),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _purchasePriceFocus.requestFocus(),
            ),
         ] else
         Row(
           children: [
             Expanded(
                child: TextFormField(
                  controller: _batchNoController,
                  focusNode: _batchNoFocus,
                  decoration: const InputDecoration(labelText: 'Batch Number', prefixIcon: Icon(Icons.qr_code), filled: true, fillColor: Colors.white),
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _qtyFocus.requestFocus(),
                ),
              ),
             const SizedBox(width: 12),
             Expanded(
               child: TextFormField(
                 controller: _qtyController,
                 focusNode: _qtyFocus,
                 decoration: const InputDecoration(labelText: 'Quantity', prefixIcon: Icon(Icons.numbers), filled: true, fillColor: Colors.white),
                 keyboardType: TextInputType.number,
                 textInputAction: TextInputAction.next,
                 onFieldSubmitted: (_) => _purchasePriceFocus.requestFocus(),
               ),
             ),
           ],
         ),
         
         const SizedBox(height: 16),
         
         if (isMobile) ...[
            TextFormField(
              controller: _purchasePriceController,
              focusNode: _purchasePriceFocus,
              decoration: const InputDecoration(labelText: 'Purchase (PKR)', prefixIcon: Icon(Icons.currency_pound), filled: true, fillColor: Colors.white),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _salePriceFocus.requestFocus(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _salePriceController,
              focusNode: _salePriceFocus,
              // Auto-run if this is the last field
              decoration: const InputDecoration(labelText: 'Sale (PKR)', prefixIcon: Icon(Icons.sell), filled: true, fillColor: Colors.white),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleSubmit(),
            ),
         ] else
         Row(
           children: [
             Expanded(
                child: TextFormField(
                  controller: _purchasePriceController,
                  focusNode: _purchasePriceFocus,
                  decoration: const InputDecoration(labelText: 'Purchase (PKR)', prefixIcon: Icon(Icons.currency_pound), filled: true, fillColor: Colors.white),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _salePriceFocus.requestFocus(),
                ),
              ),
             const SizedBox(width: 12),
             Expanded(
               child: TextFormField(
                 controller: _salePriceController,
                 focusNode: _salePriceFocus,
                 // Auto-run if this is the last field
                 decoration: const InputDecoration(labelText: 'Sale (PKR)', prefixIcon: Icon(Icons.sell), filled: true, fillColor: Colors.white),
                 keyboardType: TextInputType.number,
                 textInputAction: TextInputAction.done,
                 onFieldSubmitted: (_) => _handleSubmit(),
               ),
             ),
           ],
         ),
         
         const SizedBox(height: 16),
         
         InkWell(
           onTap: () async {
             final picked = await showDatePicker(
               context: context,
               initialDate: _expiryDate,
               firstDate: DateTime.now(),
               lastDate: DateTime.now().add(const Duration(days: 3650)),
             );
             if (picked != null) setState(() => _expiryDate = picked);
           },
           child: InputDecorator(
             decoration: const InputDecoration(
               labelText: 'Expiry Date',
               prefixIcon: Icon(Icons.calendar_today),
               filled: true, 
               fillColor: Colors.white,
             ),
             child: Text(DateFormat.yMMMd().format(_expiryDate)),
           ),
         ),
       ],
     ),
   );
  }
}

class _SubmitIntent extends Intent {
  const _SubmitIntent();
}

class _CancelIntent extends Intent {
  const _CancelIntent();
}
