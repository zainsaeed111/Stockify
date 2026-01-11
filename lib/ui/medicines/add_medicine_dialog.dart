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

enum PricingMode { single, pack }

class AddProductDialog extends ConsumerStatefulWidget {
  final Medicine? medicine;

  const AddProductDialog({super.key, this.medicine});

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Product Fields
  late TextEditingController _nameController;
  late TextEditingController _manufacturerController;
  late TextEditingController _minStockController;
  
  // Categories
  String? _selectedMainCategory;
  String? _selectedSubCategory;
  Map<String, List<String>> _categories = {};
  
  // Pricing Mode
  PricingMode _pricingMode = PricingMode.single;
  
  // Stock & Pricing Fields
  late TextEditingController _batchNoController;
  
  // Controllers - Unified Logic
  // We will have "Unit" fields that are always the source of truth for the DB.
  // "Pack" fields are helpers that auto-populate the Unit fields.
  late TextEditingController _qtyController; // Total Units
  late TextEditingController _unitPurchasePriceController; // Cost per Unit
  late TextEditingController _unitSalePriceController; // Price per Unit
  
  // Pack Helper Controllers
  late TextEditingController _packSizeController;
  late TextEditingController _numPacksController;
  late TextEditingController _packPurchasePriceController;
  late TextEditingController _packSalePriceController;

  // Focus Nodes
  late FocusNode _nameFocus;
  late FocusNode _manufacturerFocus;
  late FocusNode _minStockFocus;
  late FocusNode _batchNoFocus;
  
  late FocusNode _qtyFocus;
  late FocusNode _unitPurchaseFocus;
  late FocusNode _unitSaleFocus;
  
  late FocusNode _packSizeFocus;
  late FocusNode _numPacksFocus;
  late FocusNode _packPurchaseFocus;
  late FocusNode _packSaleFocus;

  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  // Autocomplete
  List<Medicine> _allMedicines = [];
  Medicine? _selectedExistingMedicine;

  bool _showManufacturer = true;
  bool _showMinStock = true;

  @override
  void initState() {
    super.initState();
    _loadFormSettings();
    
    _nameController = TextEditingController(text: widget.medicine?.name ?? '');
    _manufacturerController = TextEditingController(text: widget.medicine?.manufacturer ?? '');
    _minStockController = TextEditingController(text: widget.medicine?.minStock.toString() ?? '10');
    
    _batchNoController = TextEditingController();
    
    _qtyController = TextEditingController();
    _unitPurchasePriceController = TextEditingController();
    _unitSalePriceController = TextEditingController();
    
    _packSizeController = TextEditingController(text: '10');
    _numPacksController = TextEditingController();
    _packPurchasePriceController = TextEditingController();
    _packSalePriceController = TextEditingController();

    _nameFocus = FocusNode();
    _manufacturerFocus = FocusNode();
    _minStockFocus = FocusNode();
    _batchNoFocus = FocusNode();
    
    _qtyFocus = FocusNode();
    _unitPurchaseFocus = FocusNode();
    _unitSaleFocus = FocusNode();
    
    _packSizeFocus = FocusNode();
    _numPacksFocus = FocusNode();
    _packPurchaseFocus = FocusNode();
    _packSaleFocus = FocusNode();

    // Set initial state from widget
    if (widget.medicine != null) {
      _selectedMainCategory = widget.medicine!.mainCategory;
      _selectedSubCategory = widget.medicine!.subCategory;
    }
    
    _selectedExistingMedicine = widget.medicine;
    
    _loadCategories();
    
    if (widget.medicine == null) {
      _loadLastCategory();
      _loadAllMedicines();
    }
    
    // Add Listeners for Auto-Calculation
    _packSizeController.addListener(_calculateUnitFromPack);
    _packSalePriceController.addListener(_calculateUnitFromPack);
    _packPurchasePriceController.addListener(_calculateUnitFromPack);
    _numPacksController.addListener(_calculateTotalQtyFromPack);
  }

  void _calculateUnitFromPack() {
    if (_pricingMode == PricingMode.pack) {
      final size = double.tryParse(_packSizeController.text) ?? 1;
      final safeSize = size <= 0 ? 1 : size;
      
      final pSale = double.tryParse(_packSalePriceController.text) ?? 0;
      final pCost = double.tryParse(_packPurchasePriceController.text) ?? 0;
      
      final uSale = pSale / safeSize;
      final uCost = pCost / safeSize;
      
      if (_packSalePriceController.text.isNotEmpty) {
        _unitSalePriceController.text = uSale.toStringAsFixed(2);
      }
      if (_packPurchasePriceController.text.isNotEmpty) {
        _unitPurchasePriceController.text = uCost.toStringAsFixed(2);
      }
    }
  }

  void _calculateTotalQtyFromPack() {
    if (_pricingMode == PricingMode.pack) {
      final size = int.tryParse(_packSizeController.text) ?? 1;
      final packs = int.tryParse(_numPacksController.text) ?? 0;
      _qtyController.text = (packs * size).toString();
    }
  }

  Future<void> _loadFormSettings() async {
    final repo = ref.read(settingsRepositoryProvider);
    final showMfg = await repo.getSetting('form_show_manufacturer');
    final showMin = await repo.getSetting('form_show_min_stock');

    if (mounted) {
      setState(() {
        _showManufacturer = showMfg != 'false'; 
        _showMinStock = showMin != 'false';
      });
    }
  }
  
  Future<void> _loadCategories() async {
    final repo = ref.read(categoryRepositoryProvider);
    final cats = await repo.getCategoriesAsMap();
    if (mounted) {
      setState(() {
        _categories = cats;
        if (_selectedMainCategory != null && !_categories.containsKey(_selectedMainCategory)) {
          _categories[_selectedMainCategory!] = [];
        }
      });
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
    _unitPurchasePriceController.dispose();
    _unitSalePriceController.dispose();
    _packSizeController.dispose();
    _numPacksController.dispose();
    _packPurchasePriceController.dispose();
    _packSalePriceController.dispose();

    _nameFocus.dispose();
    _manufacturerFocus.dispose();
    _minStockFocus.dispose();
    _batchNoFocus.dispose();
    _qtyFocus.dispose();
    _unitPurchaseFocus.dispose();
    _unitSaleFocus.dispose();
    _packSizeFocus.dispose();
    _numPacksFocus.dispose();
    _packPurchaseFocus.dispose();
    _packSaleFocus.dispose();
    
    super.dispose();
  }

  Future<void> _loadAllMedicines() async {
    final repo = ref.read(medicineRepositoryProvider);
    final meds = await repo.getAllMedicines();
    if (mounted) setState(() => _allMedicines = meds);
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final repo = ref.read(medicineRepositoryProvider);
      final settingsRepo = ref.read(settingsRepositoryProvider);
      
      if (_selectedMainCategory != null) {
        await settingsRepo.saveSetting('last_main_category', _selectedMainCategory!);
      }
      if (_selectedSubCategory != null) {
        await settingsRepo.saveSetting('last_sub_category', _selectedSubCategory!);
      }

      int medicineId;

      if (_selectedExistingMedicine != null) {
        medicineId = _selectedExistingMedicine!.id;
        await repo.updateMedicine(_selectedExistingMedicine!.copyWith(
          name: _nameController.text,
          mainCategory: _selectedMainCategory ?? 'Medicine',
          subCategory: drift.Value(_selectedSubCategory),
          manufacturer: drift.Value(_manufacturerController.text),
          minStock: int.tryParse(_minStockController.text) ?? 10,
        ));
      } else {
        medicineId = await repo.addMedicine(MedicinesCompanion(
          name: drift.Value(_nameController.text),
          mainCategory: drift.Value(_selectedMainCategory ?? 'Medicine'),
          subCategory: drift.Value(_selectedSubCategory),
          manufacturer: drift.Value(_manufacturerController.text),
          minStock: drift.Value(int.tryParse(_minStockController.text) ?? 10),
          code: drift.Value(DateTime.now().millisecondsSinceEpoch.toString()),
        ));
      }

      // --- Get Final Values ---
      final finalQty = int.tryParse(_qtyController.text) ?? 0;
      final finalPurchasePrice = double.tryParse(_unitPurchasePriceController.text) ?? 0.0;
      final finalSalePrice = double.tryParse(_unitSalePriceController.text) ?? 0.0;

      // Check if we have stock to add
      bool hasStockData = finalQty > 0 || finalSalePrice > 0;

      if (hasStockData) {
         if (_batchNoController.text.isEmpty) {
           _batchNoController.text = 'B-${DateTime.now().millisecondsSinceEpoch}';
         }

         int packSizeToSave = 1;
         if (_pricingMode == PricingMode.pack) {
            packSizeToSave = int.tryParse(_packSizeController.text) ?? 1;
         }
         
        await repo.addBatch(BatchesCompanion(
          medicineId: drift.Value(medicineId),
          batchNumber: drift.Value(_batchNoController.text),
          quantity: drift.Value(finalQty),
          purchasePrice: drift.Value(finalPurchasePrice),
          salePrice: drift.Value(finalSalePrice),
          expiryDate: drift.Value(_expiryDate),
          packSize: drift.Value(packSizeToSave),
        ));
      }
      
      if (context.mounted) {
         if (_selectedExistingMedicine == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product Added Successfully!'), backgroundColor: Colors.teal),
            );
         }
         Navigator.pop(context);
      }
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
          _selectedMainCategory = 'General';
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
      _ensureCategoryExists(_selectedMainCategory, _selectedSubCategory);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _selectedExistingMedicine != null;

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.enter): const _SubmitIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const _CancelIntent(),
      },
      child: Actions(
        actions: {
          _SubmitIntent: CallbackAction<_SubmitIntent>(onInvoke: (_) => _handleSubmit()),
          _CancelIntent: CallbackAction<_CancelIntent>(onInvoke: (_) => Navigator.pop(context)),
        },
      child: Focus(
          autofocus: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              
              return Dialog(
                insetPadding: isMobile ? const EdgeInsets.all(10) : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  width: isMobile ? double.infinity : 850, 
                  height: isMobile ? double.infinity : 750,
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- Header ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isEditing ? 'Update Inventory' : 'New Product',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
                            ),
                            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                          ],
                        ),
                        const Divider(height: 20),
                        
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // --- Section 1: Product Definition ---
                                _buildSectionTitle('Product Information'),
                                const SizedBox(height: 12),
                                _buildNameField(),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(child: _buildCategoryField()),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildSubCategoryField()),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(child: _buildManufacturerField()),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildMinStockField()),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // --- Section 2: Stock & Pricing ---
                                _buildSectionTitle('Inventory & Pricing'),
                                const SizedBox(height: 12),
                                
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.shade50.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blueGrey.shade100),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 1. Pricing Type Selection
                                      DropdownButtonFormField<PricingMode>(
                                        value: _pricingMode,
                                        decoration: const InputDecoration(
                                          labelText: 'Pricing Unit Type',
                                          prefixIcon: Icon(Icons.style),
                                          filled: true, fillColor: Colors.white,
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                        ),
                                        items: const [
                                          DropdownMenuItem(value: PricingMode.single, child: Text('Standard Unit (Per Piece)')),
                                          DropdownMenuItem(value: PricingMode.pack, child: Text('Bulk Pack / Box')),
                                        ],
                                        onChanged: (val) => setState(() => _pricingMode = val!),
                                      ),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // 2. Dynamic Fields
                                      if (_pricingMode == PricingMode.pack)
                                        _buildPackInputs(),
                                      
                                      const SizedBox(height: 16),
                                      const Divider(),
                                      const SizedBox(height: 16),
                                      
                                      // 3. Common/Result Fields (Unit Price meant for DB)
                                      Text('Unit Details (Final)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade600)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: _qtyController,
                                              readOnly: _pricingMode == PricingMode.pack, // Auto-calc in pack mode
                                              decoration: InputDecoration(
                                                labelText: 'Total Quantity',
                                                prefixIcon: const Icon(Icons.numbers),
                                                filled: true, 
                                                fillColor: _pricingMode == PricingMode.pack ? Colors.grey.shade100 : Colors.white,
                                                border: const OutlineInputBorder(),
                                              ),
                                              keyboardType: TextInputType.number,
                                              validator: (v) => (_pricingMode == PricingMode.single && (v == null || v.isEmpty)) ? 'Required' : null,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _unitSalePriceController,
                                              readOnly: _pricingMode == PricingMode.pack, // Auto-calc in pack mode
                                              decoration: InputDecoration(
                                                labelText: 'Unit Sale Price',
                                                prefixIcon: const Icon(Icons.sell),
                                                filled: true,
                                                fillColor: _pricingMode == PricingMode.pack ? Colors.grey.shade100 : Colors.white,
                                                border: const OutlineInputBorder(),
                                              ),
                                              keyboardType: TextInputType.number,
                                              validator: (v) => v!.isEmpty ? 'Required' : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // 4. Batch & Cost
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: _unitPurchasePriceController,
                                              readOnly: _pricingMode == PricingMode.pack,
                                              decoration: InputDecoration(
                                                labelText: 'Unit Purchase Cost',
                                                prefixIcon: const Icon(Icons.currency_pound),
                                                filled: true,
                                                fillColor: _pricingMode == PricingMode.pack ? Colors.grey.shade100 : Colors.white,
                                                border: const OutlineInputBorder(),
                                                helperText: 'Optional',
                                              ),
                                              keyboardType: TextInputType.number,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _batchNoController,
                                              decoration: const InputDecoration(
                                                labelText: 'Batch Number',
                                                prefixIcon: Icon(Icons.qr_code),
                                                filled: true, fillColor: Colors.white,
                                                border: OutlineInputBorder(),
                                                helperText: 'Auto-ID if empty',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                       const SizedBox(height: 12),
                                       
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
                                            border: OutlineInputBorder(),
                                            filled: true, fillColor: Colors.white,
                                          ),
                                          child: Text(DateFormat.yMMMd().format(_expiryDate)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context), 
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              icon: const Icon(Icons.check),
                              label: const Text('Save Product'),
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

  Widget _buildPackInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pack Configuration', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _packSizeController,
                decoration: const InputDecoration(
                  labelText: 'Units per Pack',
                  prefixIcon: Icon(Icons.apps),
                  border: OutlineInputBorder(),
                  filled: true, fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _numPacksController,
                decoration: const InputDecoration(
                  labelText: 'Number of Packs',
                  prefixIcon: Icon(Icons.inventory_2),
                  border: OutlineInputBorder(),
                  filled: true, fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _packSalePriceController,
                decoration: const InputDecoration(
                  labelText: 'Pack Sale Price',
                  prefixIcon: Icon(Icons.sell),
                  border: OutlineInputBorder(),
                  filled: true, fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _packPurchasePriceController,
                decoration: const InputDecoration(
                  labelText: 'Pack Purchase Cost',
                  prefixIcon: Icon(Icons.currency_pound),
                  border: OutlineInputBorder(),
                  filled: true, fillColor: Colors.white,
                  helperText: 'Optional',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal));
  }

  Widget _buildNameField() {
    if (widget.medicine == null) {
       return LayoutBuilder(builder: (context, constraints) {
          return RawAutocomplete<Medicine>(
             textEditingController: _nameController, // Direct control
             focusNode: _nameFocus,
             optionsBuilder: (TextEditingValue textEditingValue) {
               if (textEditingValue.text == '') return const Iterable<Medicine>.empty();
               return _allMedicines.where((Medicine option) => option.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
             },
             displayStringForOption: (Medicine option) => option.name,
             onSelected: _onProductSelected,
             fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: textEditingController, // This is now _nameController
                  focusNode: focusNode,
                  decoration: const InputDecoration(labelText: 'Product Name', prefixIcon: Icon(Icons.search), border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _manufacturerFocus.requestFocus(),
                );
             },
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
                         return ListTile(title: Text(option.name), subtitle: Text(option.mainCategory), onTap: () => onSelected(option));
                       },
                     ),
                   ),
                 ),
               );
             },
          );
      });
    } else {
      return TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(labelText: 'Product Name', prefixIcon: Icon(Icons.shopping_bag), border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
        validator: (v) => v!.isEmpty ? 'Required' : null,
      );
    }
  }
  
  // Helpers
  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      value: _selectedMainCategory,
      decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category), border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
      items: _categories.keys.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (val) {
        setState(() { _selectedMainCategory = val; _selectedSubCategory = null; });
      },
      validator: (v) => v == null ? 'Required' : null,
    );
  }
  
  Widget _buildSubCategoryField() {
    return DropdownButtonFormField<String>(
       value: _selectedSubCategory,
       decoration: const InputDecoration(labelText: 'Sub Category', prefixIcon: Icon(Icons.subdirectory_arrow_right), border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
       items: _selectedMainCategory == null ? [] : _categories[_selectedMainCategory]!.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
       onChanged: (val) => setState(() => _selectedSubCategory = val),
    );
  }
  
  Widget _buildManufacturerField() {
     return TextFormField(
        controller: _manufacturerController,
        focusNode: _manufacturerFocus,
        decoration: const InputDecoration(labelText: 'Manufacturer / Brand', prefixIcon: Icon(Icons.factory), border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
        textInputAction: TextInputAction.next,
     );
  }
  
  Widget _buildMinStockField() {
     return TextFormField(
        controller: _minStockController,
        decoration: const InputDecoration(labelText: 'Min. Alert Lvl', prefixIcon: Icon(Icons.warning_amber), border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
        keyboardType: TextInputType.number,
     );
  }
}

class _SubmitIntent extends Intent { const _SubmitIntent(); }
class _CancelIntent extends Intent { const _CancelIntent(); }
