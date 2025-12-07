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
    Customer? customer,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Receipt format
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('STOCKIFY PHARMACY', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))),
              pw.Center(child: pw.Text('Point of Sale System')),
              pw.Center(child: pw.Text('Phone: +92-XXX-XXXXXXX')),
              pw.Divider(),
              pw.Text('Invoice: ${sale.invoiceNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(sale.date)}'),
              if (customer != null) ...[
                pw.Divider(),
                pw.Text('Customer: ${customer.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                if (customer.phoneNumber != null) pw.Text('Phone: ${customer.phoneNumber}'),
              ],
              pw.Divider(),
              pw.Table.fromTextArray(
                context: context,
                headers: ['Item', 'Qty', 'Price', 'Total'],
                data: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final medicine = index < medicines.length ? medicines[index] : null;
                  return [
                    medicine?.name ?? 'Item #${item.batchId}',
                    item.quantity.toString(),
                    'PKR ${item.price.toStringAsFixed(2)}',
                    'PKR ${item.total.toStringAsFixed(2)}',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                cellStyle: const pw.TextStyle(fontSize: 8),
              ),
              pw.Divider(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Subtotal:'),
                pw.Text('PKR ${sale.subTotal.toStringAsFixed(2)}'),
              ]),
              if (sale.discount > 0)
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('Discount:'),
                  pw.Text('PKR ${sale.discount.toStringAsFixed(2)}'),
                ]),
              pw.Divider(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text('PKR ${sale.grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ]),
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
