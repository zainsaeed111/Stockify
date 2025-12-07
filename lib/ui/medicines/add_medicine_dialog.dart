import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../data/repositories/settings_repository.dart';
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
  late TextEditingController _nameController;
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
  
  final Map<String, List<String>> _categories = {
    'Medicine': ['Tablet', 'Syrup', 'Injection', 'Capsule', 'Drops', 'Ointment'],
    'Inventory': ['Raw Material', 'Packaging', 'Equipment'],
    'General': ['Stationery', 'Cleaning', 'Snacks'],
    'Electronics': ['Computer', 'Printer', 'Scanner', 'Accessories'],
  };

  // Initial Batch Fields (Only for new products)
  late TextEditingController _batchNoController;
  late TextEditingController _qtyController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _salePriceController;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medicine?.name ?? '');
    _manufacturerController = TextEditingController(text: widget.medicine?.manufacturer ?? '');
    _minStockController = TextEditingController(text: widget.medicine?.minStock.toString() ?? '10');
    
    _selectedMainCategory = widget.medicine?.mainCategory;
    _selectedSubCategory = widget.medicine?.subCategory;

    _batchNoController = TextEditingController();
    _qtyController = TextEditingController();
    _purchasePriceController = TextEditingController();
    _salePriceController = TextEditingController();

    // Initialize focus nodes
    _nameFocus = FocusNode();
    _manufacturerFocus = FocusNode();
    _minStockFocus = FocusNode();
    _batchNoFocus = FocusNode();
    _qtyFocus = FocusNode();
    _purchasePriceFocus = FocusNode();
    _salePriceFocus = FocusNode();

    if (widget.medicine == null) {
      _loadLastCategory();
    }
    
    // Auto-focus first field after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
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

      final isEditing = widget.medicine != null;
      if (isEditing) {
        await repo.updateMedicine(widget.medicine!.copyWith(
          name: _nameController.text,
          mainCategory: _selectedMainCategory ?? 'Medicine',
          subCategory: drift.Value(_selectedSubCategory),
          manufacturer: drift.Value(_manufacturerController.text),
          minStock: int.tryParse(_minStockController.text) ?? 10,
        ));
      } else {
        // Add Medicine
        final medId = await repo.addMedicine(MedicinesCompanion(
          name: drift.Value(_nameController.text),
          mainCategory: drift.Value(_selectedMainCategory ?? 'Medicine'),
          subCategory: drift.Value(_selectedSubCategory),
          manufacturer: drift.Value(_manufacturerController.text),
          minStock: drift.Value(int.tryParse(_minStockController.text) ?? 10),
          code: drift.Value(DateTime.now().millisecondsSinceEpoch.toString()), // Auto-generate code
        ));
        
        // Add Initial Batch if details provided
        if (_batchNoController.text.isNotEmpty) {
          await repo.addBatch(BatchesCompanion(
            medicineId: drift.Value(medId),
            batchNumber: drift.Value(_batchNoController.text),
            quantity: drift.Value(int.tryParse(_qtyController.text) ?? 0),
            purchasePrice: drift.Value(double.tryParse(_purchasePriceController.text) ?? 0.0),
            salePrice: drift.Value(double.tryParse(_salePriceController.text) ?? 0.0),
            expiryDate: drift.Value(_expiryDate),
          ));
        }
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.medicine != null;

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
          autofocus: true,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 600,
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Product' : 'Add New Product',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.teal),
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
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Product Details'),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              focusNode: _nameFocus,
                              decoration: const InputDecoration(labelText: 'Product Name', prefixIcon: Icon(Icons.shopping_bag)),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => _manufacturerFocus.requestFocus(),
                            ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedMainCategory,
                              decoration: const InputDecoration(labelText: 'Main Category', prefixIcon: Icon(Icons.category)),
                              items: _categories.keys.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedMainCategory = val;
                                  _selectedSubCategory = null; // Reset sub
                                });
                              },
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedSubCategory,
                              decoration: const InputDecoration(labelText: 'Sub Category', prefixIcon: Icon(Icons.subdirectory_arrow_right)),
                              items: _selectedMainCategory == null 
                                  ? [] 
                                  : _categories[_selectedMainCategory]!.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              onChanged: (val) => setState(() => _selectedSubCategory = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _manufacturerController,
                              focusNode: _manufacturerFocus,
                              decoration: const InputDecoration(labelText: 'Manufacturer/Brand', prefixIcon: Icon(Icons.factory)),
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => _minStockFocus.requestFocus(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _minStockController,
                              focusNode: _minStockFocus,
                              decoration: const InputDecoration(labelText: 'Low Stock Alert', prefixIcon: Icon(Icons.warning_amber)),
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) {
                                if (!isEditing) {
                                  _batchNoFocus.requestFocus();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      if (!isEditing) ...[
                        const SizedBox(height: 32),
                        _buildSectionHeader('Initial Stock (First Batch)'),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.teal.withOpacity(0.2)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _batchNoController,
                                      focusNode: _batchNoFocus,
                                      decoration: const InputDecoration(labelText: 'Batch Number', prefixIcon: Icon(Icons.qr_code)),
                                      textInputAction: TextInputAction.next,
                                      onFieldSubmitted: (_) => _qtyFocus.requestFocus(),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _qtyController,
                                      focusNode: _qtyFocus,
                                      decoration: const InputDecoration(labelText: 'Quantity', prefixIcon: Icon(Icons.numbers)),
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      onFieldSubmitted: (_) => _purchasePriceFocus.requestFocus(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _purchasePriceController,
                                      focusNode: _purchasePriceFocus,
                                      decoration: const InputDecoration(labelText: 'Purchase Price (PKR)', prefixIcon: Icon(Icons.attach_money)),
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      onFieldSubmitted: (_) => _salePriceFocus.requestFocus(),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _salePriceController,
                                      focusNode: _salePriceFocus,
                                      decoration: const InputDecoration(labelText: 'Sale Price (PKR)', prefixIcon: Icon(Icons.price_check)),
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
                                  ),
                                  child: Text(DateFormat.yMMMd().format(_expiryDate)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                    child: const Text('Cancel (Esc)'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(isEditing ? 'Update Product (Enter)' : 'Save Product (Enter)'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}

// Intent classes for keyboard shortcuts
class _SubmitIntent extends Intent {
  const _SubmitIntent();
}

class _CancelIntent extends Intent {
  const _CancelIntent();
}
