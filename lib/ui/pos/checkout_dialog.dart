import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/repositories/sale_repository.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../data/providers/current_shop_provider.dart';
import '../../data/database/database.dart';
import 'package:printing/printing.dart';
import '../sales/sale_pdf_generator.dart';
import '../sales/receipt_preview_screen.dart';
import 'cart_provider.dart';

class CheckoutDialog extends ConsumerStatefulWidget {
  final double? initialAmount;
  final String? initialPaymentMode;

  const CheckoutDialog({super.key, this.initialAmount, this.initialPaymentMode});

  @override
  ConsumerState<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends ConsumerState<CheckoutDialog> {
  bool _isProcessing = false;
  late String _paymentMode; // Cash, Card, Online
  final TextEditingController _amountReceivedController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();
  double _change = 0.0;

  @override
  void initState() {
    super.initState();
    final cart = ref.read(cartProvider);
    _paymentMode = widget.initialPaymentMode ?? 'Cash';
    
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _amountReceivedController.text = widget.initialAmount!.toStringAsFixed(2);
    } else {
      _amountReceivedController.text = cart.grandTotal.toStringAsFixed(2);
    }
    
    _calculateChange(); // Calculate immediately based on initial values
    
    _amountReceivedController.addListener(_calculateChange);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountReceivedController.removeListener(_calculateChange);
    _amountReceivedController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _calculateChange() {
    final cart = ref.read(cartProvider);
    final amountReceived = double.tryParse(_amountReceivedController.text) ?? 0.0;
    setState(() {
      _change = amountReceived - cart.grandTotal;
    });
  }

  Future<void> _handleConfirm() async {
    if (_isProcessing) return;
    
    final cart = ref.read(cartProvider);
    
    // Validate amount for cash payment
    if (_paymentMode == 'Cash') {
      final amountReceived = double.tryParse(_amountReceivedController.text) ?? 0.0;
      if (amountReceived < cart.grandTotal) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Amount received is less than total'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    
    setState(() => _isProcessing = true);
    
    try {
      final saleRepo = ref.read(saleRepositoryProvider);
      final medicineRepo = ref.read(medicineRepositoryProvider);
      final shopData = ref.read(currentShopProvider);
      
      // Customer is optional - proceed without validation
      
      // Create Sale
      final saleId = await saleRepo.createSale(
        SalesCompanion(
          invoiceNumber: drift.Value('INV-${DateTime.now().millisecondsSinceEpoch}'),
          date: drift.Value(DateTime.now()),
          customerId: cart.customer != null ? drift.Value(cart.customer!.id) : const drift.Value.absent(),
          subTotal: drift.Value(cart.subTotal),
          discount: drift.Value(cart.discountAmount), // Use discountAmount
          tax: drift.Value(cart.taxAmount), // Save Tax
          posFee: drift.Value(cart.posFee), // Save POS Fee
          grandTotal: drift.Value(cart.grandTotal),
          paymentMethod: drift.Value(_paymentMode), // Save payment method
        ),
        cart.items.map((item) => SaleItemsCompanion(
          batchId: drift.Value(item.batch.id),
          quantity: drift.Value(item.quantity),
          price: drift.Value(item.batch.salePrice),
          total: drift.Value(item.total),
        )).toList(),
      );
      
      // DEDUCT STOCK for each item sold
      for (final item in cart.items) {
        await medicineRepo.updateStock(item.batch.id, -item.quantity);
      }
      
      // Calculate payment info
      final amountReceived = _paymentMode == 'Cash' 
          ? (double.tryParse(_amountReceivedController.text) ?? cart.grandTotal)
          : cart.grandTotal;
      final changeGiven = amountReceived - cart.grandTotal;
      
      // Generate PDF with shop data
      final pdfBytes = await SalePdfGenerator.generateSalePdf(
        sale: Sale(
          id: saleId,
          invoiceNumber: 'INV-$saleId',
          date: DateTime.now(),
          customerId: cart.customer?.id,
          subTotal: cart.subTotal,
          discount: cart.discountAmount,
          tax: cart.taxAmount,
          posFee: cart.posFee,
          grandTotal: cart.grandTotal,
          paymentMethod: _paymentMode,
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
        customer: cart.customer,
        shopData: shopData,
        amountReceived: amountReceived,
        changeGiven: changeGiven > 0 ? changeGiven : null,
        discountType: cart.discountType,
        discountValue: cart.discountValue,
      );

      // Clear Cart
      ref.read(cartProvider.notifier).clear();
      
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        // Show PDF Preview Screen
        Navigator.push(
          context, 
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => ReceiptPreviewScreen(
              title: 'Receipt Preview',
              buildPdf: (_) => Future.value(pdfBytes), // Use generated bytes
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildPaymentModeButton(String mode, IconData icon) {
    final isSelected = _paymentMode == mode;
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _paymentMode = mode;
          if (mode != 'Cash') {
            final cart = ref.read(cartProvider);
            _amountReceivedController.text = cart.grandTotal.toStringAsFixed(2);
          }
        });
      },
      icon: Icon(icon, size: 18),
      label: Text(mode),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Colors.teal : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.teal,
        side: BorderSide(color: Colors.teal, width: isSelected ? 2 : 1),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.enter): _ConfirmIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): _CancelIntent(),
      },
      child: Actions(
        actions: {
          _ConfirmIntent: CallbackAction<_ConfirmIntent>(onInvoke: (_) => _handleConfirm()),
          _CancelIntent: CallbackAction<_CancelIntent>(onInvoke: (_) => Navigator.pop(context)),
        },
        child: Focus(
          autofocus: true,
          child: AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.payment, color: Colors.teal),
                const SizedBox(width: 8),
                const Text('Complete Sale'),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Info
                    if (cart.customer != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, size: 20, color: Colors.teal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cart.customer!.name,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  if (cart.customer!.phoneNumber != null)
                                    Text(
                                      cart.customer!.phoneNumber!,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Total Amount
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'PKR ${cart.grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Payment Mode
                    const Text(
                      'Payment Mode:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPaymentModeButton('Cash', Icons.money),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPaymentModeButton('Card', Icons.credit_card),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPaymentModeButton('Online', Icons.phone_android),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Amount Received (Only for Cash)
                    if (_paymentMode == 'Cash') ...[
                      const Text(
                        'Amount Received:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountReceivedController,
                        focusNode: _amountFocus,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          prefixText: 'PKR ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onSubmitted: (_) => _handleConfirm(),
                      ),
                      const SizedBox(height: 16),
                      
                      // Change Display
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _change >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _change >= 0 ? Colors.green : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _change >= 0 ? 'Change:' : 'Underpaid:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _change >= 0 ? Colors.green.shade900 : Colors.red.shade900,
                              ),
                            ),
                            Text(
                              'PKR ${_change.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _change >= 0 ? Colors.green.shade900 : Colors.red.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Exact amount will be charged via $_paymentMode',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel (Esc)'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _isProcessing ? null : _handleConfirm,
                icon: _isProcessing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle),
                label: Text(_isProcessing ? 'Processing...' : 'Complete Sale (Enter)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Intent classes for keyboard shortcuts
class _ConfirmIntent extends Intent {
  const _ConfirmIntent();
}

class _CancelIntent extends Intent {
  const _CancelIntent();
}
