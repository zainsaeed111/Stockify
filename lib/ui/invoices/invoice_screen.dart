import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/database/database.dart';
import 'create_invoice_screen.dart';
import 'pdf_preview_screen.dart';

class InvoiceScreen extends ConsumerWidget {
  const InvoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceRepo = ref.watch(invoiceRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Invoice>>(
        stream: invoiceRepo.watchAllInvoices(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final invoices = snapshot.data!;

          if (invoices.isEmpty) {
            return const Center(child: Text('No invoices found. Create one!'));
          }

          return ListView.builder(
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text('Invoice #${invoice.id}'),
                subtitle: Text('${DateFormat.yMMMd().format(invoice.date)} - ${invoice.status}'),
                trailing: Text('\$${invoice.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onTap: () {
                  // Open PDF Preview
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfPreviewScreen(invoiceId: invoice.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
