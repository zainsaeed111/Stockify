import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';

class CartItem {
  final Medicine medicine;
  final Batch batch;
  final int quantity;

  const CartItem({required this.medicine, required this.batch, this.quantity = 1});

  double get total => batch.salePrice * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      medicine: medicine,
      batch: batch,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartState {
  final List<CartItem> items;
  final double discount;
  final double taxRate;
  final Customer? customer; // Customer for this sale

  CartState({
    this.items = const [],
    this.discount = 0.0,
    this.taxRate = 0.0,
    this.customer,
  });

  double get subTotal => items.fold(0.0, (sum, item) => sum + item.total);
  double get taxAmount => subTotal * (taxRate / 100);
  double get grandTotal => (subTotal + taxAmount) - discount;

  CartState copyWith({
    List<CartItem>? items,
    double? discount,
    double? taxRate,
    Customer? customer,
  }) {
    return CartState(
      items: items ?? this.items,
      discount: discount ?? this.discount,
      taxRate: taxRate ?? this.taxRate,
      customer: customer ?? this.customer,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return CartState();
  }

  void addItem(Medicine medicine, Batch batch) {
    final existingIndex = state.items.indexWhere((i) => i.batch.id == batch.id);
    if (existingIndex >= 0) {
      // Update quantity
      final newItems = List<CartItem>.from(state.items);
      newItems[existingIndex] = newItems[existingIndex].copyWith(quantity: newItems[existingIndex].quantity + 1);
      state = state.copyWith(items: newItems);
    } else {
      // Add new
      state = state.copyWith(items: [...state.items, CartItem(medicine: medicine, batch: batch)]);
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

  void setDiscount(double discount) {
    state = state.copyWith(discount: discount);
  }

  void setCustomer(Customer? customer) {
    state = state.copyWith(customer: customer);
  }

  void clear() {
    state = CartState();
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
