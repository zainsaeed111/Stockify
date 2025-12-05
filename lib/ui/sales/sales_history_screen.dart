import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/sale_repository.dart';
import '../../data/database/database.dart';

class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleRepo = ref.watch(saleRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sales History')),
      body: StreamBuilder<List<Sale>>(
        stream: saleRepo.watchAllSales(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final sales = snapshot.data!;

          if (sales.isEmpty) return const Center(child: Text('No sales recorded.'));

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Transaction History', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          headingRowHeight: 56,
                          dataRowMinHeight: 52,
                          dataRowMaxHeight: 52,
                          columns: const [
                            DataColumn(label: Text('Invoice #')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Items')),
                            DataColumn(label: Text('Total')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: sales.map((sale) {
                            return DataRow(cells: [
                              DataCell(Text(sale.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(Text(DateFormat('MMM dd, yyyy HH:mm').format(sale.date))),
                              DataCell(FutureBuilder<List<SaleItem>>(
                                future: saleRepo.getSaleItems(sale.id),
                                builder: (context, itemSnapshot) {
                                  if (!itemSnapshot.hasData) return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                                    child: Text('${itemSnapshot.data!.length} Items', style: const TextStyle(fontSize: 12)),
                                  );
                                },
                              )),
                              DataCell(Text('\$${sale.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
                              DataCell(IconButton(
                                icon: const Icon(Icons.print_outlined, color: Colors.grey),
                                tooltip: 'Reprint Receipt',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reprinting not implemented yet')));
                                },
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
