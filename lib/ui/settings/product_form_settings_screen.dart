import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/settings_repository.dart';

class ProductFormSettingsScreen extends ConsumerStatefulWidget {
  const ProductFormSettingsScreen({super.key});

  @override
  ConsumerState<ProductFormSettingsScreen> createState() => _ProductFormSettingsScreenState();
}

class _ProductFormSettingsScreenState extends ConsumerState<ProductFormSettingsScreen> {
  // Configurable Fields
  bool _showManufacturer = true;
  bool _showMinStock = true;
  bool _showBatch = true;
  bool _showExpiry = true;
  bool _showPurchasePrice = true;
  bool _showCategory = true;
  bool _showSubCategory = true;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final repo = ref.read(settingsRepositoryProvider);
    
    // Load individual settings, default to 'true' if not set
    final showMfg = await repo.getSetting('form_show_manufacturer');
    final showMin = await repo.getSetting('form_show_min_stock');
    final showBatch = await repo.getSetting('form_show_batch_number');
    final showExp = await repo.getSetting('form_show_expiry_date');
    final showBuy = await repo.getSetting('form_show_purchase_price');
    final showCat = await repo.getSetting('form_show_category');
    final showSub = await repo.getSetting('form_show_sub_category');

    if (mounted) {
      setState(() {
        _showManufacturer = showMfg != 'false'; // Default true
        _showMinStock = showMin != 'false';
        _showBatch = showBatch != 'false';
        _showExpiry = showExp != 'false';
        _showPurchasePrice = showBuy != 'false';
        _showCategory = showCat != 'false';
        _showSubCategory = showSub != 'false';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.saveSetting(key, value.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Form Settings'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildToggleCard(
                  'Product Details',
                  [
                    _buildSwitch('Category', _showCategory, (v) => setState(() { _showCategory = v; _saveSetting('form_show_category', v); })),
                    _buildSwitch('Sub Category', _showSubCategory, (v) => setState(() { _showSubCategory = v; _saveSetting('form_show_sub_category', v); })),
                    _buildSwitch('Manufacturer / Brand', _showManufacturer, (v) => setState(() { _showManufacturer = v; _saveSetting('form_show_manufacturer', v); })),
                    _buildSwitch('Low Stock Alert', _showMinStock, (v) => setState(() { _showMinStock = v; _saveSetting('form_show_min_stock', v); })),
                  ]
                ),
                const SizedBox(height: 16),
                _buildToggleCard(
                  'Quick Stock & Batch',
                  [
                    _buildSwitch('Batch Number', _showBatch, (v) => setState(() { _showBatch = v; _saveSetting('form_show_batch_number', v); })),
                    _buildSwitch('Expiry Date', _showExpiry, (v) => setState(() { _showExpiry = v; _saveSetting('form_show_expiry_date', v); })),
                    _buildSwitch('Purchase Price', _showPurchasePrice, (v) => setState(() { _showPurchasePrice = v; _saveSetting('form_show_purchase_price', v); })),
                  ]
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: const [
                       Icon(Icons.info, color: Colors.blue),
                       SizedBox(width: 12),
                       Expanded(child: Text('Hidden fields will use default values (e.g. 0 for price, current date for expiry).', style: TextStyle(color: Colors.blue))),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildToggleCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
             const Divider(),
             ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.teal,
      contentPadding: EdgeInsets.zero,
    );
  }
}
