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
    double? amountReceived,
    double? changeGiven,
    String? discountType,
    double? discountValue,
  }) async {
    final doc = pw.Document();
    
    // Get shop info from shopData or use defaults
    final shopName = shopData?['shopName'] ?? 'My Business';
    final shopPhone = shopData?['phone'] ?? '';
    final shopAddress = shopData?['address'] ?? '';
    final shopEmail = shopData?['email'] ?? '';
    final shopWebsite = shopData?['website'] ?? '';
    final shopDesc = shopData?['businessDesc'] ?? '';
    final businessType = shopData?['businessType'] ?? '';

    // Get types for labels
    final gstType = shopData?['gstType'] ?? 'percent';
    final gstRate = (shopData?['gstRate'] as num?)?.toDouble() ?? 0.0;
    final taxType = shopData?['taxType'] ?? 'percent';
    final taxRate = (shopData?['taxRate'] as num?)?.toDouble() ?? 0.0;
    final posFeeType = shopData?['posFeeType'] ?? 'fixed';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // ===== HEADER =====
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.only(bottom: 10),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 2)),
                ),
                child: pw.Column(
                  children: [
                    // Business Name - Stylish
                    pw.Text(
                      shopName.toString().toUpperCase(),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                      if (businessType.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          businessType,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    if (shopDesc.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          shopDesc,
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    pw.SizedBox(height: 4),
                    if (shopAddress.isNotEmpty)
                      pw.Text(shopAddress, style: const pw.TextStyle(fontSize: 9)),
                    if (shopPhone.isNotEmpty)
                      pw.Text('Tel: $shopPhone', style: const pw.TextStyle(fontSize: 9)),
                    if (shopEmail.isNotEmpty)
                      pw.Text(shopEmail, style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 10),
              
              // ===== INVOICE INFO =====
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('INVOICE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Text('#${sale.invoiceNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                    pw.Divider(height: 8, thickness: 0.5),
                    _buildInfoRow('Date', DateFormat('dd MMM yyyy').format(sale.date)),
                    _buildInfoRow('Time', DateFormat('hh:mm a').format(sale.date)),
                    _buildInfoRow('Payment', sale.paymentMethod ?? 'Cash'),
                  ],
                ),
              ),
              
              // ===== CUSTOMER INFO =====
              if (customer != null) ...[
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CUSTOMER', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(customer.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      if (customer.phoneNumber != null && customer.phoneNumber!.isNotEmpty)
                        pw.Text('Tel: ${customer.phoneNumber}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
              ],
              
              pw.SizedBox(height: 10),
              
              // ===== ITEMS TABLE =====
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    // Table Header
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFEEF2FF),
                        borderRadius: pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(3),
                          topRight: pw.Radius.circular(3),
                        ),
                      ),
                      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                      child: pw.Row(
                        children: [
                          pw.SizedBox(width: 18, child: pw.Text('No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                          pw.Expanded(flex: 5, child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                          pw.SizedBox(width: 28, child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center)),
                          pw.SizedBox(width: 35, child: pw.Text('Rate', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                          pw.SizedBox(width: 42, child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                        ],
                      ),
                    ),
                    // Table Rows
                    ...items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final medicine = index < medicines.length ? medicines[index] : null;
                      final isEven = index % 2 == 0;
                      
                      return pw.Container(
                        color: isEven ? PdfColors.white : PdfColors.grey50,
                        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.SizedBox(width: 18, child: pw.Text('${index + 1}.', style: const pw.TextStyle(fontSize: 9))),
                            pw.Expanded(
                              flex: 5, 
                              child: pw.Text(
                                medicine?.name ?? 'Item', 
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            ),
                            pw.SizedBox(width: 28, child: pw.Text('${item.quantity}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
                            pw.SizedBox(width: 35, child: pw.Text('${item.price.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                            pw.SizedBox(width: 42, child: pw.Text('${item.total.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 10),
              
              // ===== TOTALS =====
              pw.Container(
                width: double.infinity,
                child: pw.Column(
                  children: [
                    _buildTotalRow('Subtotal', 'PKR ${sale.subTotal.toStringAsFixed(0)}'),
                    if (sale.discount > 0)
                      _buildTotalRow(
                        'Discount${(discountType == 'percent' && discountValue != null) ? ' (${discountValue.toStringAsFixed(0)}%)' : ''}', 
                        '- PKR ${sale.discount.toStringAsFixed(0)}', 
                        color: PdfColor.fromInt(0xFF10B981) // Brand Success
                      ),
                    if (sale.tax > 0)
                      _buildTotalRow(
                        'GST/Tax${(gstType == 'percent' && gstRate > 0) ? ' ($gstRate%)' : ''}${(taxType == 'percent' && taxRate > 0) ? ' + Tax $taxRate%' : ''}', 
                        'PKR ${sale.tax.toStringAsFixed(0)}'
                      ),
                    if (sale.posFee > 0)
                      _buildTotalRow(
                        'POS Fees', 
                        'PKR ${sale.posFee.toStringAsFixed(0)}'
                      ),
                    pw.Container(
                      margin: const pw.EdgeInsets.symmetric(vertical: 6),
                      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF4F46E5), // Brand Primary (Indigo 600)
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.white)),
                          pw.Text('PKR ${sale.grandTotal.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // ===== PAYMENT INFO =====
              if (amountReceived != null) ...[
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      _buildInfoRow('Amount Paid', 'PKR ${amountReceived.toStringAsFixed(0)}'),
                      if (changeGiven != null && changeGiven > 0)
                        _buildInfoRow('Change', 'PKR ${changeGiven.toStringAsFixed(0)}'),
                    ],
                  ),
                ),
              ],
              
              pw.SizedBox(height: 16),
              
              // ===== THANK YOU MESSAGE =====
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1, color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      '- - - THANK YOU - - -',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'We appreciate your business!',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Please visit again',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 10),
              
              // ===== FOOTER =====
              if (shopWebsite.isNotEmpty || shopEmail.isNotEmpty || shopPhone.isNotEmpty)
                pw.Container(
                  width: double.infinity,
                  child: pw.Column(
                    children: [
                      if (shopWebsite.isNotEmpty)
                        pw.Text('Web: $shopWebsite', style: const pw.TextStyle(fontSize: 8)),
                      if (shopEmail.isNotEmpty)
                        pw.Text('Email: $shopEmail', style: const pw.TextStyle(fontSize: 8)),
                      if (shopPhone.isNotEmpty)
                        pw.Text('Phone: $shopPhone', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
              
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5),
              pw.Text(
                'Powered by Billingly',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
  
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
  
  static pw.Widget _buildTotalRow(String label, String value, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(
            value, 
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: color ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
