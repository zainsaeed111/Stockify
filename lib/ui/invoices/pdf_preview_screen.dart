import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/patient_repository.dart';
import '../../data/database/database.dart';

class PdfPreviewScreen extends ConsumerWidget {
  final int invoiceId;

  const PdfPreviewScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceRepo = ref.watch(invoiceRepositoryProvider);
    final patientRepo = ref.watch(patientRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Invoice Preview')),
      body: PdfPreview(
        build: (format) async {
          // Fetch data
          final invoices = await invoiceRepo.getAllInvoices();
          final invoice = invoices.firstWhere((i) => i.id == invoiceId);
          
          final patients = await patientRepo.getAllPatients();
          final patient = patients.firstWhere((p) => p.id == invoice.patientId);
          
          final items = await invoiceRepo.getInvoiceItems(invoiceId);
          final services = await invoiceRepo.getAllServices();

          return _generatePdf(format, invoice, patient, items, services);
        },
      ),
    );
  }

  Future<Uint8List> _generatePdf(
    PdfPageFormat format,
    Invoice invoice,
    Patient patient,
    List<InvoiceItem> items,
    List<Service> services,
  ) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Medical Invoice', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Invoice #${invoice.id}', style: const pw.TextStyle(fontSize: 18)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(patient.name),
                      if (patient.address != null) pw.Text(patient.address!),
                      if (patient.contact != null) pw.Text(patient.contact!),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Date: ${DateFormat.yMMMd().format(invoice.date)}'),
                      pw.Text('Status: ${invoice.status}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Table.fromTextArray(
                context: context,
                headers: ['Service', 'Quantity', 'Unit Cost', 'Total'],
                data: items.map((item) {
                  final serviceName = services.firstWhere((s) => s.id == item.serviceId, orElse: () => const Service(id: -1, name: 'Unknown', cost: 0)).name;
                  return [
                    serviceName,
                    item.quantity.toString(),
                    '\$${item.cost.toStringAsFixed(2)}',
                    '\$${(item.cost * item.quantity).toStringAsFixed(2)}',
                  ];
                }).toList(),
              ),
              pw.Divider(),
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Total Amount: \$${invoice.totalAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Spacer(),
              pw.Footer(
                leading: pw.Text('Thank you for your business!'),
                trailing: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}'),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}
