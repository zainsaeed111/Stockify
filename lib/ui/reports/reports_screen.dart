import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/sale_repository.dart';
import '../../data/database/database.dart';
import '../theme/app_colors.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleRepo = ref.watch(saleRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportReport(context, ref),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Last 7 Days Sales', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<Sale>>(
                stream: saleRepo.watchAllSales(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  
                  final sales = snapshot.data!;
                  final groupedSales = _groupSalesByDate(sales);
                  
                  if (groupedSales.isEmpty) return const Center(child: Text('No sales data available.'));

                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: groupedSales.values.reduce((a, b) => a > b ? a : b) * 1.2,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(DateFormat('MM/dd').format(date), style: const TextStyle(fontSize: 10)),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: groupedSales.entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key.millisecondsSinceEpoch,
                          barRods: [
                            BarChartRodData(toY: entry.value, color: AppColors.primary, width: 16),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<DateTime, double> _groupSalesByDate(List<Sale> sales) {
    final Map<DateTime, double> data = {};
    final now = DateTime.now();
    // Initialize last 7 days with 0
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      data[date] = 0.0;
    }

    for (var sale in sales) {
      final date = DateTime(sale.date.year, sale.date.month, sale.date.day);
      if (data.containsKey(date)) {
        data[date] = data[date]! + sale.grandTotal;
      }
    }
    return data;
  }

  Future<void> _exportReport(BuildContext context, WidgetRef ref) async {
    try {
      final saleRepo = ref.read(saleRepositoryProvider);
      final sales = await saleRepo.getAllSales(); // Need to expose this or use stream value if possible
      // For simplicity, fetching again.
      
      List<List<dynamic>> rows = [];
      rows.add(['Invoice', 'Date', 'SubTotal', 'Discount', 'Tax', 'Total']);
      
      for (var sale in sales) {
        rows.add([
          sale.invoiceNumber,
          DateFormat('yyyy-MM-dd HH:mm').format(sale.date),
          sale.subTotal,
          sale.discount,
          sale.tax,
          sale.grandTotal
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Report',
        fileName: 'sales_report_${DateTime.now().millisecondsSinceEpoch}.csv',
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(csv);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report Exported!')));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export Failed: $e')));
    }
  }
}

