import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier to hold the currently logged-in shop data
/// This is set after successful login and used throughout the app
class CurrentShopNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;

  void setShop(Map<String, dynamic>? shop) {
    state = shop;
  }

  // Alias for update if needed, but setShop works fine
  void updateShop(Map<String, dynamic> shop) {
    state = shop;
  }

  void clearShop() {
    state = null;
  }
  
  // Alias for compatibility
  void clear() => clearShop();
}

final currentShopProvider = NotifierProvider<CurrentShopNotifier, Map<String, dynamic>?>(CurrentShopNotifier.new);

/// Helper getters for common shop properties
extension ShopProviderExtensions on WidgetRef {
  Map<String, dynamic>? get currentShop => watch(currentShopProvider);
  
  String get shopName => currentShop?['shopName'] ?? 'Billingly';
  String get shopOwnerName => currentShop?['ownerName'] ?? '';
  String get shopPhone => currentShop?['phone'] ?? '';
  String get shopEmail => currentShop?['email'] ?? '';
  String get shopAddress => currentShop?['address'] ?? '';
  
  // POS Settings
  double get shopGstRate => (currentShop?['gstRate'] as num?)?.toDouble() ?? 0.0;
  double get shopTaxRate => (currentShop?['taxRate'] as num?)?.toDouble() ?? 0.0;
  double get shopPosFee => (currentShop?['posFee'] as num?)?.toDouble() ?? 0.0;
  double get shopDefaultDiscount => (currentShop?['defaultDiscount'] as num?)?.toDouble() ?? 0.0;
}
