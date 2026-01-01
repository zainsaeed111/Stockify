import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../data/providers/current_shop_provider.dart';

class CartItem {
  final Medicine medicine;
  final Batch batch;
  final int quantity;
  final int originalStock; // Stock available when item was added (for warning display)

  const CartItem({
    required this.medicine,
    required this.batch,
    this.quantity = 1,
    this.originalStock = 0,
  });

  double get total => batch.salePrice * quantity;
  
  /// Returns true if quantity exceeds original available stock
  /// Only shows warning if stock was actually tracked (originalStock > 0)
  bool get hasStockWarning => originalStock > 0 && quantity > originalStock;
  
  /// Returns the shortage amount (0 if no shortage or stock not tracked)
  int get shortage => originalStock > 0 ? quantity - originalStock : 0;

  CartItem copyWith({int? quantity, int? originalStock}) {
    return CartItem(
      medicine: medicine,
      batch: batch,
      quantity: quantity ?? this.quantity,
      originalStock: originalStock ?? this.originalStock,
    );
  }
}

class CartState {
  final List<CartItem> items;
  
  // Values
  final double discountValue; 
  final double gstValue;
  final double taxValue; 
  final double posFeeValue;
  
  // Types ('percent' or 'fixed')
  final String discountType;
  final String gstType;
  final String taxType;
  final String posFeeType;

  final Customer? customer;

  CartState({
    this.items = const [],
    this.discountValue = 0.0,
    this.gstValue = 0.0,
    this.taxValue = 0.0,
    this.posFeeValue = 0.0,
    this.discountType = 'percent',
    this.gstType = 'percent',
    this.taxType = 'percent',
    this.posFeeType = 'fixed',
    this.customer,
  });

  double get subTotal => items.fold<double>(0.0, (sum, item) => sum + item.total);
  
  double get discountAmount {
    if (discountType == 'percent') {
      return subTotal * (discountValue / 100);
    }
    return discountValue;
  }
  
  double get taxableAmount => subTotal - discountAmount;

  double get gstAmount {
    if (gstType == 'percent') {
      return taxableAmount * (gstValue / 100);
    }
    return gstValue;
  }

  double get taxAmount {
    if (taxType == 'percent') {
      return taxableAmount * (taxValue / 100);
    }
    return taxValue;
  }
  
  double get posFeeAmount {
    if (posFeeType == 'percent') {
      return taxableAmount * (posFeeValue / 100);
    }
    return posFeeValue;
  }
  
  double get grandTotal => taxableAmount + gstAmount + taxAmount + posFeeAmount;

  // Helpers for external consumers used to old getter names
  // We expose specific amounts now, so 'taxAmount' is Additional Tax Amount.
  // 'posFee' getter for compatibility? BUt we should use posFeeAmount.
  double get posFee => posFeeAmount; 

  CartState copyWith({
    List<CartItem>? items,
    double? discountValue,
    double? gstValue,
    double? taxValue,
    double? posFeeValue,
    String? discountType,
    String? gstType,
    String? taxType,
    String? posFeeType,
    Customer? customer,
  }) {
    return CartState(
      items: items ?? this.items,
      discountValue: discountValue ?? this.discountValue,
      gstValue: gstValue ?? this.gstValue,
      taxValue: taxValue ?? this.taxValue,
      posFeeValue: posFeeValue ?? this.posFeeValue,
      discountType: discountType ?? this.discountType,
      gstType: gstType ?? this.gstType,
      taxType: taxType ?? this.taxType,
      posFeeType: posFeeType ?? this.posFeeType,
      customer: customer ?? this.customer,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    // Listen to settings changes to update rates dynamically
    ref.listen(currentShopProvider, (prev, next) {
       if (next != null) {
         state = state.copyWith(
           gstValue: (next['gstRate'] as num?)?.toDouble() ?? 0.0,
           taxValue: (next['taxRate'] as num?)?.toDouble() ?? 0.0,
           posFeeValue: (next['posFee'] as num?)?.toDouble() ?? 0.0,
           discountValue: (next['defaultDiscount'] as num?)?.toDouble() ?? 0.0,
           gstType: next['gstType'] as String? ?? 'percent',
           taxType: next['taxType'] as String? ?? 'percent',
           posFeeType: next['posFeeType'] as String? ?? 'fixed',
           discountType: next['discountType'] as String? ?? 'percent',
         );
       }
    });

    final shop = ref.read(currentShopProvider);
    return CartState(
       gstValue: (shop?['gstRate'] as num?)?.toDouble() ?? 0.0,
       taxValue: (shop?['taxRate'] as num?)?.toDouble() ?? 0.0,
       posFeeValue: (shop?['posFee'] as num?)?.toDouble() ?? 0.0,
       discountValue: (shop?['defaultDiscount'] as num?)?.toDouble() ?? 0.0,
       gstType: shop?['gstType'] as String? ?? 'percent',
       taxType: shop?['taxType'] as String? ?? 'percent',
       posFeeType: shop?['posFeeType'] as String? ?? 'fixed',
       discountType: shop?['discountType'] as String? ?? 'percent',
    );
  }

  void addItem(Medicine medicine, Batch batch, {int totalBatchStock = 0}) {
    final existingIndex = state.items.indexWhere((i) => i.batch.id == batch.id);
    if (existingIndex >= 0) {
      final newItems = List<CartItem>.from(state.items);
      newItems[existingIndex] = newItems[existingIndex].copyWith(
        quantity: newItems[existingIndex].quantity + 1,
      );
      state = state.copyWith(items: newItems);
    } else {
      state = state.copyWith(items: [
        ...state.items,
        CartItem(
          medicine: medicine,
          batch: batch,
          quantity: 1,
          originalStock: totalBatchStock,
        ),
      ]);
    }
  }

  void removeItem(int batchId) {
    state = state.copyWith(items: state.items.where((i) => i.batch.id != batchId).toList());
  }

  void updateQuantity(int batchId, int quantity) {
    if (quantity <= 0) {
      removeItem(batchId);
      return;
    }
    final newItems = state.items.map((item) {
      if (item.batch.id == batchId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    state = state.copyWith(items: newItems);
  }

  /// Sets the discount value and optionally type
  void setDiscount(double value, {String? type}) {
    state = state.copyWith(
      discountValue: value,
      discountType: type ?? state.discountType,
    );
  }

  void setCustomer(Customer? customer) {
    state = state.copyWith(customer: customer);
  }

  void clear() {
    // When clearing, we should reset to default settings
    final shop = ref.read(currentShopProvider);
    state = CartState(
       gstValue: (shop?['gstRate'] as num?)?.toDouble() ?? 0.0,
       taxValue: (shop?['taxRate'] as num?)?.toDouble() ?? 0.0,
       posFeeValue: (shop?['posFee'] as num?)?.toDouble() ?? 0.0,
       discountValue: (shop?['defaultDiscount'] as num?)?.toDouble() ?? 0.0,
       gstType: shop?['gstType'] as String? ?? 'percent',
       taxType: shop?['taxType'] as String? ?? 'percent',
       posFeeType: shop?['posFeeType'] as String? ?? 'fixed',
       discountType: shop?['discountType'] as String? ?? 'percent',
    );
  }

  int getQuantityInCart(int batchId) {
    final item = state.items.where((i) => i.batch.id == batchId).firstOrNull;
    return item?.quantity ?? 0;
  }

  int getMedicineQuantityInCart(int medicineId) {
    return state.items
        .where((i) => i.medicine.id == medicineId)
        .fold<int>(0, (sum, item) => sum + item.quantity);
  }

  bool get hasAnyStockWarnings => state.items.any((i) => i.hasStockWarning);
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
