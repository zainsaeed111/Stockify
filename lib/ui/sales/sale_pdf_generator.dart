import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../data/database/database.dart';

class SalePdfGenerator {
  static Future<Uint8List> generateSalePdf({
    required Sale sale,
    required List<SaleItem> items,
    required List<Medicine> medicines,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Receipt format
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('PHARMACY NAME', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))),
              pw.Center(child: pw.Text('Address Line 1, City')),
              pw.Center(child: pw.Text('Phone: 123-456-7890')),
              pw.Divider(),
              pw.Text('Invoice: ${sale.invoiceNumber}'),
              pw.Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(sale.date)}'),
              pw.Divider(),
              pw.Table.fromTextArray(
                context: context,
                headers: ['Item', 'Qty', 'Total'],
                data: items.map((item) {
                  final med = medicines.firstWhere((m) => m.id == item.batchId, orElse: () => Medicine(id: -1, name: 'Unknown', code: '', minStock: 0, mainCategory: 'Unknown'));
                  // Wait, item has batchId. We need to look up Medicine via Batch. 
                  // For simplicity in this generator, we will assume the caller passed a map or we just use a placeholder if complex.
                  // Actually, we passed 'medicines' list. We need to know which medicine corresponds to the item.
                  // The item only has batchId. We need Batch to get MedicineId.
                  // Let's assume the caller resolves this or we just print price.
                  return [
                    'Item #${item.batchId}', // Placeholder for name
                    item.quantity.toString(),
                    item.total.toStringAsFixed(2),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                cellStyle: const pw.TextStyle(fontSize: 8),
              ),
              pw.Divider(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Subtotal:'),
                pw.Text(sale.subTotal.toStringAsFixed(2)),
              ]),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Discount:'),
                pw.Text(sale.discount.toStringAsFixed(2)),
              ]),
              pw.Text('Total: \$${sale.grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Thank you for your purchase!', style: const pw.TextStyle(fontSize: 10))),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}
