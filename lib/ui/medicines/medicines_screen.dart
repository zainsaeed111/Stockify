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
            child: StreamBuilder<List<Medicine>>(
              stream: medicineRepo.watchAllMedicines(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var medicines = snapshot.data!;
                if (_searchQuery.isNotEmpty) {
                  medicines = medicines.where((m) => 
                    m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    (m.mainCategory?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
                  ).toList();
                }

                if (medicines.isEmpty) {
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
                    if (constraints.maxWidth > 800) {
                      return _buildDesktopTable(medicines, medicineRepo);
                    } else {
                      return _buildMobileList(medicines, medicineRepo);
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

  Widget _buildDesktopTable(List<Medicine> medicines, MedicineRepository medicineRepo) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowHeight: 56,
            dataRowMinHeight: 52,
            dataRowMaxHeight: 52,
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Sub Category')),
              DataColumn(label: Text('Manufacturer')),
              DataColumn(label: Text('Min Stock')),
              DataColumn(label: Text('Actions')),
            ],
            rows: medicines.map((medicine) {
              return DataRow(cells: [
                DataCell(Text('#${medicine.id}', style: const TextStyle(color: Colors.grey))),
                DataCell(Text(medicine.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text(medicine.mainCategory ?? '-', style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                )),
                DataCell(Text(medicine.subCategory ?? '-')),
                DataCell(Text(medicine.manufacturer ?? '-')),
                DataCell(Row(
                  children: [
                    if (medicine.minStock < 5) const Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    Text(medicine.minStock.toString()),
                  ],
                )),
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
                      onPressed: () {
                         medicineRepo.deleteMedicine(medicine.id);
                      },
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

  Widget _buildMobileList(List<Medicine> medicines, MedicineRepository medicineRepo) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: medicines.length,
      itemBuilder: (context, index) {
        final medicine = medicines[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal.shade50,
              child: const Icon(Icons.medication, color: Colors.teal),
            ),
            title: Text(medicine.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${medicine.mainCategory} > ${medicine.subCategory}'),
                Text('Stock Alert: ${medicine.minStock}'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  showDialog(
                    context: context,
                    builder: (context) => AddProductDialog(medicine: medicine),
                  );
                } else if (value == 'delete') {
                  medicineRepo.deleteMedicine(medicine.id);
                }
              },
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
