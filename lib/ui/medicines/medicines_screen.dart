import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/repositories/medicine_repository.dart';
import '../../data/database/database.dart';
import 'add_medicine_dialog.dart';

class MedicinesScreen extends ConsumerStatefulWidget {
  const MedicinesScreen({super.key});

  @override
  ConsumerState<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends ConsumerState<MedicinesScreen> {
  String _searchQuery = '';
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus search field when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  void _handleAddProduct() {
    showDialog(
      context: context,
      builder: (context) => const AddProductDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medicineRepo = ref.watch(medicineRepositoryProvider);

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): _FocusSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): _AddProductIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): _ClearSearchIntent(),
      },
      child: Actions(
        actions: {
          _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(onInvoke: (_) {
            _searchFocus.requestFocus();
            return null;
          }),
          _AddProductIntent: CallbackAction<_AddProductIntent>(onInvoke: (_) {
            _handleAddProduct();
            return null;
          }),
          _ClearSearchIntent: CallbackAction<_ClearSearchIntent>(onInvoke: (_) {
            setState(() => _searchQuery = '');
            _searchFocus.requestFocus();
            return null;
          }),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Products Management'),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: FloatingActionButton.small(
                    heroTag: 'import',
                    onPressed: () => _importCsv(context, ref),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.teal,
                    child: const Icon(Icons.upload_file),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.teal,
                  child: TextField(
                    focusNode: _searchFocus,
                    decoration: InputDecoration(
                      hintText: 'Search Products... (Ctrl+F)',
                      prefixIcon: const Icon(Icons.search),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                    textInputAction: TextInputAction.search,
                  ),
                ),
          Expanded(
            child: StreamBuilder<List<MedicineWithStock>>(
              stream: medicineRepo.watchMedicinesWithStock(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var items = snapshot.data!;
                if (_searchQuery.isNotEmpty) {
                  items = items.where((item) => 
                    item.medicine.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    (item.medicine.mainCategory?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
                  ).toList();
                }

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No products found', style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 900) {
                      return _buildDesktopTable(items, medicineRepo);
                    } else {
                      return _buildMobileList(items, medicineRepo);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'add',
              onPressed: _handleAddProduct,
              icon: const Icon(Icons.add),
              label: const Text('Add Product (Ctrl+N)'),
              backgroundColor: Colors.teal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List<MedicineWithStock> items, MedicineRepository medicineRepo) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowHeight: 56,
            dataRowMinHeight: 72, // Increased height for details
            dataRowMaxHeight: 72,
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Product')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Stock')),
              DataColumn(label: Text('Unit Price')),
              DataColumn(label: Text('Pack Info')),
              DataColumn(label: Text('Actions')),
            ],
            rows: items.map((item) {
              final medicine = item.medicine;
              final isPack = item.packSize > 1;
              final packPrice = item.latestPrice * item.packSize;
              
              return DataRow(cells: [
                DataCell(Text('#${medicine.id}', style: const TextStyle(color: Colors.grey))),
                DataCell(Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50, 
                        shape: BoxShape.circle,
                        image: (medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty)
                            ? DecorationImage(
                                image: medicine.imageUrl!.startsWith('http') 
                                    ? NetworkImage(medicine.imageUrl!) 
                                    : FileImage(File(medicine.imageUrl!)) as ImageProvider,
                                fit: BoxFit.cover
                              )
                            : null,
                      ),
                      child: (medicine.imageUrl == null || medicine.imageUrl!.isEmpty) 
                          ? const Icon(Icons.medication, color: Colors.teal, size: 20) 
                          : null,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(medicine.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        if (medicine.subtitle != null && medicine.subtitle!.isNotEmpty)
                          Text(medicine.subtitle!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ],
                )),
                DataCell(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                      child: Text(medicine.mainCategory ?? '-', style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                    ),
                    if (medicine.subCategory != null)
                      Text(medicine.subCategory!, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  ],
                )),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.totalQuantity <= medicine.minStock) const Icon(Icons.warning_amber, color: Colors.red, size: 16),
                    if (item.totalQuantity <= medicine.minStock) const SizedBox(width: 4),
                    Text(item.totalQuantity.toString(), style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: item.totalQuantity <= medicine.minStock ? Colors.red : Colors.black87
                    )),
                  ],
                )),
                DataCell(Text(item.latestPrice.toStringAsFixed(2))),
                DataCell(isPack 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Pack: ${packPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('${item.packSize} units/pack', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                      child: Text('Standard Unit', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    )
                ),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                      tooltip: 'Edit',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AddProductDialog(medicine: medicine),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      tooltip: 'Delete',
                      onPressed: () => medicineRepo.deleteMedicine(medicine.id),
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(List<MedicineWithStock> items, MedicineRepository medicineRepo) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final medicine = item.medicine;
        final isPack = item.packSize > 1;
        final packPrice = item.latestPrice * item.packSize;
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Title & Subtitle + Action
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50, 
                        borderRadius: BorderRadius.circular(25),
                        image: (medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty)
                            ? DecorationImage(
                                image: medicine.imageUrl!.startsWith('http') 
                                    ? NetworkImage(medicine.imageUrl!) 
                                    : FileImage(File(medicine.imageUrl!)) as ImageProvider,
                                fit: BoxFit.cover
                              )
                            : null,
                      ),
                      child: (medicine.imageUrl == null || medicine.imageUrl!.isEmpty) 
                          ? const Icon(Icons.medication, color: Colors.teal) 
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(medicine.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (medicine.subtitle != null && medicine.subtitle!.isNotEmpty)
                            Text(medicine.subtitle!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      padding: EdgeInsets.zero,
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                      onSelected: (value) {
                         if (value == 'edit') {
                           showDialog(context: context, builder: (context) => AddProductDialog(medicine: medicine));
                         } else if (value == 'delete') {
                           medicineRepo.deleteMedicine(medicine.id);
                         }
                      },
                    ),
                  ],
                ),
                const Divider(height: 20),
                
                // 2. Info Row: Category | Stock
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     // Category Chip
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                       child: Text(medicine.mainCategory ?? 'General', style: TextStyle(color: Colors.blue.shade800, fontSize: 12, fontWeight: FontWeight.w500)),
                     ),
                     // Stock
                     Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.totalQuantity <= medicine.minStock ? Colors.red.shade50 : Colors.green.shade50, 
                          borderRadius: BorderRadius.circular(6)
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 14, color: item.totalQuantity <= medicine.minStock ? Colors.red : Colors.green),
                            const SizedBox(width: 4),
                            Text('${item.totalQuantity} Units', style: TextStyle(
                              color: item.totalQuantity <= medicine.minStock ? Colors.red.shade800 : Colors.green.shade800, 
                              fontWeight: FontWeight.bold, fontSize: 12
                            )),
                          ],
                        ),
                     ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // 3. Pricing Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: isPack 
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Spread out for pack
                      children: [
                         // Pack Price
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.center,
                             children: [
                               Text('Pack Price', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                               const SizedBox(height: 2),
                               Text(packPrice.toStringAsFixed(2), style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 15)),
                               Text('(${item.packSize}/pk)', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                             ],
                           ),
                         ),
                         Container(width: 1, height: 30, color: Colors.grey.shade300),
                         
                         // Unit Price
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.center,
                             children: [
                               Text('Unit Price', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                               const SizedBox(height: 2),
                               Text(item.latestPrice.toStringAsFixed(2), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 15)),
                             ],
                           ),
                         ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Center for single
                      children: [
                         Column(
                           children: [
                             Text('Standard Unit Price', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                             const SizedBox(height: 2),
                             Text(item.latestPrice.toStringAsFixed(2), style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 16)),
                           ],
                         ),
                      ],
                    ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _importCsv(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final input = file.openRead();
        final fields = await input.transform(utf8.decoder).transform(const CsvToListConverter()).toList();

        final repo = ref.read(medicineRepositoryProvider);
        int count = 0;

        // Skip header row if present (assuming row 0 is header)
        for (var i = 1; i < fields.length; i++) {
          final row = fields[i];
          if (row.length >= 2) {
            // Simple assumption: Col 0 = Name, Col 1 = Code
            await repo.addMedicine(MedicinesCompanion(
              name: drift.Value(row[0].toString()),
              code: drift.Value(row[1].toString()),
              minStock: const drift.Value(10),
            ));
            count++;
          }
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported $count medicines')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import Failed: $e')));
      }
    }
  }
}

// Intent classes for keyboard shortcuts
class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _AddProductIntent extends Intent {
  const _AddProductIntent();
}

class _ClearSearchIntent extends Intent {
  const _ClearSearchIntent();
}
