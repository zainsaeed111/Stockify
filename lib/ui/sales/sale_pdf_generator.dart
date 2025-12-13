import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../data/database/database.dart';

class SalePdfGenerator {
  static Future<Uint8List> generateSalePdf({
    required Sale sale,
    required List<SaleItem> items,
    required List<Medicine> medicines,
    Customer? customer,
    Map<String, dynamic>? shopData,
  }) async {
    final doc = pw.Document();
    
    // Get shop info from shopData or use defaults
    final shopName = shopData?['shopName'] ?? 'Stockify Pharmacy';
    final shopPhone = shopData?['phone'] ?? '';
    final shopAddress = shopData?['address'] ?? '';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Receipt format
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Shop Header
              pw.Center(
                child: pw.Text(
                  shopName.toUpperCase(),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                ),
              ),
              if (shopAddress.isNotEmpty)
                pw.Center(child: pw.Text(shopAddress, style: const pw.TextStyle(fontSize: 9))),
              if (shopPhone.isNotEmpty)
                pw.Center(child: pw.Text('Phone: $shopPhone', style: const pw.TextStyle(fontSize: 9))),
              pw.Divider(),
              
              // Invoice Info
              pw.Text('Invoice: ${sale.invoiceNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(sale.date)}'),
              pw.Text('Payment: ${sale.paymentMethod ?? 'Cash'}'),
              
              // Customer / Doctor Info
              if (customer != null) ...[
                pw.Divider(),
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Patient/Customer: ${customer.name}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                      if (customer.phoneNumber != null && customer.phoneNumber!.isNotEmpty)
                        pw.Text('Phone: ${customer.phoneNumber}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
              ],
              pw.Divider(),
              
              // Items Table
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
                    'PKR ${item.price.toStringAsFixed(0)}',
                    'PKR ${item.total.toStringAsFixed(0)}',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                cellStyle: const pw.TextStyle(fontSize: 8),
              ),
              pw.Divider(),
              
              // Totals
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Subtotal:'),
                pw.Text('PKR ${sale.subTotal.toStringAsFixed(0)}'),
              ]),
              if (sale.discount > 0)
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('Discount:'),
                  pw.Text('PKR ${sale.discount.toStringAsFixed(0)}'),
                ]),
              pw.Divider(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text('PKR ${sale.grandTotal.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ]),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Thank you for your purchase!', style: const pw.TextStyle(fontSize: 10))),
              pw.SizedBox(height: 4),
              pw.Center(child: pw.Text('Get well soon!', style: const pw.TextStyle(fontSize: 8))),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}
