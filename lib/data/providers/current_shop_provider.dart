import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to hold the currently logged-in shop data
/// This is set after successful login and used throughout the app
final currentShopProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

/// Helper getters for common shop properties
extension ShopProviderExtensions on WidgetRef {
  Map<String, dynamic>? get currentShop => watch(currentShopProvider);
  
  String get shopName => currentShop?['shopName'] ?? 'Stockify Pharmacy';
  String get shopOwnerName => currentShop?['ownerName'] ?? '';
  String get shopPhone => currentShop?['phone'] ?? '';
  String get shopEmail => currentShop?['email'] ?? '';
  String get shopAddress => currentShop?['address'] ?? '';
}
