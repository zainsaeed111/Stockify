import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/repositories/sale_repository.dart';
import '../../data/database/database.dart';
import 'package:printing/printing.dart';
import '../sales/sale_pdf_generator.dart';
import 'cart_provider.dart';

class CheckoutDialog extends ConsumerStatefulWidget {
  const CheckoutDialog({super.key});

  @override
  ConsumerState<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends ConsumerState<CheckoutDialog> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return AlertDialog(
      title: const Text('Checkout'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total Amount: \$${cart.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            // Patient selection removed
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isProcessing ? null : () async {
            setState(() => _isProcessing = true);
            
            try {
              final saleRepo = ref.read(saleRepositoryProvider);
              
              // Create Sale
              final saleId = await saleRepo.createSale(
                SalesCompanion(
                  invoiceNumber: drift.Value('INV-${DateTime.now().millisecondsSinceEpoch}'),
                  date: drift.Value(DateTime.now()),
                  subTotal: drift.Value(cart.subTotal),
                  discount: drift.Value(cart.discount),
                  grandTotal: drift.Value(cart.grandTotal),
                  // patientId removed
                ),
                cart.items.map((item) => SaleItemsCompanion(
                  batchId: drift.Value(item.batch.id),
                  quantity: drift.Value(item.quantity),
                  price: drift.Value(item.batch.salePrice),
                  total: drift.Value(item.total),
                )).toList(),
              );
              
              // Generate PDF
              final pdfBytes = await SalePdfGenerator.generateSalePdf(
                sale: Sale(
                  id: saleId,
                  invoiceNumber: 'INV-$saleId',
                  date: DateTime.now(),
                  subTotal: cart.subTotal,
                  discount: cart.discount,
                  tax: cart.taxAmount,
                  grandTotal: cart.grandTotal,
                  paymentMethod: 'Cash',
                  userId: null,
                ),
                items: cart.items.map((i) => SaleItem(
                  id: 0,
                  saleId: saleId,
                  batchId: i.batch.id,
                  quantity: i.quantity,
                  price: i.batch.salePrice,
                  total: i.total,
                )).toList(),
                medicines: cart.items.map((i) => i.medicine).toList(),
              );

              // Clear Cart
              ref.read(cartProvider.notifier).clear();
              
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                // Show PDF Preview
                await Printing.layoutPdf(onLayout: (format) => pdfBytes);
              }
            } catch (e) {
              if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            } finally {
              if (mounted) setState(() => _isProcessing = false);
            }
          },
          child: _isProcessing ? const CircularProgressIndicator() : const Text('Confirm & Print'),
        ),
      ],
    );
  }
}
