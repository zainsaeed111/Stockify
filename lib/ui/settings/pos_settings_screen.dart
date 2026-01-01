import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/current_shop_provider.dart';
import '../../data/repositories/shop_repository.dart';

class PosSettingsScreen extends ConsumerStatefulWidget {
  const PosSettingsScreen({super.key});

  @override
  ConsumerState<PosSettingsScreen> createState() => _PosSettingsScreenState();
}

class _PosSettingsScreenState extends ConsumerState<PosSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _gstController;
  late TextEditingController _taxController;
  late TextEditingController _posFeeController;
  late TextEditingController _discountController;
  
  // Types: 'percent' or 'fixed'
  String _gstType = 'percent';
  String _taxType = 'percent';
  String _posFeeType = 'fixed'; // Default to fixed for fees
  String _discountType = 'percent';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current values from provider
    final shop = ref.read(currentShopProvider);
    _gstController = TextEditingController(text: (shop?['gstRate'] ?? 0).toString());
    _taxController = TextEditingController(text: (shop?['taxRate'] ?? 0).toString());
    _posFeeController = TextEditingController(text: (shop?['posFee'] ?? 0).toString());
    _discountController = TextEditingController(text: (shop?['defaultDiscount'] ?? 0).toString());
    
    _gstType = shop?['gstType'] ?? 'percent';
    _taxType = shop?['taxType'] ?? 'percent';
    _posFeeType = shop?['posFeeType'] ?? 'fixed';
    _discountType = shop?['discountType'] ?? 'percent';
  }

  @override
  void dispose() {
    _gstController.dispose();
    _taxController.dispose();
    _posFeeController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final gst = double.tryParse(_gstController.text) ?? 0;
      final tax = double.tryParse(_taxController.text) ?? 0;
      final fee = double.tryParse(_posFeeController.text) ?? 0;
      final discount = double.tryParse(_discountController.text) ?? 0;
      
      final currentMap = ref.read(currentShopProvider);
      final shopEmail = currentMap?['email'] as String?;

      if (shopEmail != null) {
        await ref.read(shopRepositoryProvider).updatePosSettings(
          email: shopEmail,
          gstRate: gst,
          taxRate: tax,
          posFee: fee,
          defaultDiscount: discount,
          gstType: _gstType,
          taxType: _taxType,
          posFeeType: _posFeeType,
          discountType: _discountType,
        );

        // Update local provider so UI reflects changes immediately
        final updatedMap = Map<String, dynamic>.from(currentMap!);
        updatedMap['gstRate'] = gst;
        updatedMap['taxRate'] = tax;
        updatedMap['posFee'] = fee;
        updatedMap['defaultDiscount'] = discount;
        updatedMap['gstType'] = _gstType;
        updatedMap['taxType'] = _taxType;
        updatedMap['posFeeType'] = _posFeeType;
        updatedMap['discountType'] = _discountType;
        
        ref.read(currentShopProvider.notifier).setShop(updatedMap);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('POS Settings updated successfully')),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Shop email not found');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating settings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage POS Settings'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
               _buildCard(
                 title: 'Tax & GST',
                 icon: Icons.account_balance,
                 children: [
                   _buildConfigField(
                     controller: _gstController, 
                     label: 'GST', 
                     type: _gstType,
                     onTypeChanged: (val) => setState(() => _gstType = val),
                   ),
                   const SizedBox(height: 16),
                   _buildConfigField(
                     controller: _taxController, 
                     label: 'Additional Tax', 
                     type: _taxType,
                     onTypeChanged: (val) => setState(() => _taxType = val),
                   ),
                 ],
               ),
               const SizedBox(height: 16),
               
               _buildCard(
                 title: 'Fees & Discounts',
                 icon: Icons.settings_applications,
                 children: [
                   _buildConfigField(
                     controller: _posFeeController, 
                     label: 'POS Fee / Other', 
                     type: _posFeeType,
                     onTypeChanged: (val) => setState(() => _posFeeType = val),
                   ),
                   const SizedBox(height: 16),
                   _buildConfigField(
                     controller: _discountController, 
                     label: 'Default Discount', 
                     type: _discountType,
                     onTypeChanged: (val) => setState(() => _discountType = val),
                   ),
                 ],
               ),
               
               const SizedBox(height: 24),
               SizedBox(
                 width: double.infinity,
                 height: 50,
                 child: ElevatedButton.icon(
                   onPressed: _isSaving ? null : _saveSettings,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.teal,
                     foregroundColor: Colors.white,
                   ),
                   icon: _isSaving 
                       ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                       : const Icon(Icons.save),
                   label: Text(_isSaving ? 'Saving...' : 'Update Settings', style: const TextStyle(fontSize: 16)),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
               children: [
                 Icon(icon, color: Colors.teal),
                 const SizedBox(width: 8),
                 Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildConfigField({
    required TextEditingController controller, 
    required String label, 
    required String type,
    required ValueChanged<String> onTypeChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            // Toggle
            Container(
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleItem('%', type == 'percent', () => onTypeChanged('percent')),
                  Container(width: 1, height: 20, color: Colors.grey.shade400),
                  _buildToggleItem('Fixed', type == 'fixed', () => onTypeChanged('fixed')),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            hintText: 'Enter value',
            suffixText: type == 'percent' ? '%' : 'PKR',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          validator: (val) {
            if (val == null || val.isEmpty) return 'Required';
            if (double.tryParse(val) == null) return 'Invalid number';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildToggleItem(String text, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// Just a quick provider helper for email if not exists globally
final shopEmailProvider = Provider<String?>((ref) => ref.watch(currentShopProvider)?['email']);
