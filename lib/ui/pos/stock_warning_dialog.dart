import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Result of the stock warning dialog
class StockWarningResult {
  final bool proceed;
  final bool dontShowAgain;
  
  const StockWarningResult({
    required this.proceed,
    required this.dontShowAgain,
  });
}

/// Professional dialog shown when adding items with low or zero stock
class StockWarningDialog extends StatefulWidget {
  final String productName;
  final int availableStock;
  final int requestedQuantity;
  final int alreadyInCart;

  const StockWarningDialog({
    super.key,
    required this.productName,
    required this.availableStock,
    required this.requestedQuantity,
    required this.alreadyInCart,
  });

  int get totalRequested => alreadyInCart + requestedQuantity;
  int get shortage => totalRequested - availableStock;
  bool get isOutOfStock => availableStock <= 0;
  bool get willExceedStock => totalRequested > availableStock;

  static Future<StockWarningResult?> show(
    BuildContext context, {
    required String productName,
    required int availableStock,
    required int requestedQuantity,
    required int alreadyInCart,
  }) async {
    final result = await showDialog<StockWarningResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StockWarningDialog(
        productName: productName,
        availableStock: availableStock,
        requestedQuantity: requestedQuantity,
        alreadyInCart: alreadyInCart,
      ),
    );
    return result;
  }

  @override
  State<StockWarningDialog> createState() => _StockWarningDialogState();
}

class _StockWarningDialogState extends State<StockWarningDialog> {
  bool _dontShowAgain = false;

  int get totalRequested => widget.alreadyInCart + widget.requestedQuantity;
  int get shortage => totalRequested - widget.availableStock;
  bool get isOutOfStock => widget.availableStock <= 0;
  bool get willExceedStock => totalRequested > widget.availableStock;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isOutOfStock ? AppColors.error.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOutOfStock ? Icons.remove_shopping_cart : Icons.warning_amber_rounded,
              color: isOutOfStock ? AppColors.error : AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isOutOfStock ? 'Out of Stock' : 'Low Stock Warning',
            style: TextStyle(
              color: isOutOfStock ? AppColors.error : AppColors.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Name
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medication, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stock Details
            _buildStockRow(
              'Available Stock',
              '${widget.availableStock} units',
              widget.availableStock > 0 ? AppColors.success : AppColors.error,
              Icons.inventory_2,
            ),
            const SizedBox(height: 8),
            if (widget.alreadyInCart > 0) ...[
              _buildStockRow(
                'Already in Cart',
                '${widget.alreadyInCart} units',
                AppColors.secondary,
                Icons.shopping_cart,
              ),
              const SizedBox(height: 8),
            ],
            _buildStockRow(
              'Adding',
              '${widget.requestedQuantity} unit(s)',
              AppColors.primary,
              Icons.add_circle,
            ),
            
            if (willExceedStock) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Shortage: $shortage unit(s) will be oversold',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can still proceed with billing. Stock will be updated after checkout.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.warning.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Don't show again checkbox
            const SizedBox(height: 16),
            InkWell(
              onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _dontShowAgain,
                        onChanged: (v) => setState(() => _dontShowAgain = v ?? false),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Don't show this warning again for this product",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, const StockWarningResult(proceed: false, dontShowAgain: false)),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, StockWarningResult(proceed: true, dontShowAgain: _dontShowAgain)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: const Icon(Icons.add_shopping_cart, size: 18),
          label: const Text('Add Anyway'),
        ),
      ],
    );
  }

  Widget _buildStockRow(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
