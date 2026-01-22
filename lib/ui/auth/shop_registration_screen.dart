import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/shop_repository.dart';
import 'owner_login_screen.dart';

class ShopRegistrationScreen extends ConsumerStatefulWidget {
  final String email;
  const ShopRegistrationScreen({super.key, required this.email});

  @override
  ConsumerState<ShopRegistrationScreen> createState() => _ShopRegistrationScreenState();
}

class _ShopRegistrationScreenState extends ConsumerState<ShopRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _businessNameController = TextEditingController();
  final _businessDescController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _customTypeController = TextEditingController();
  final _gstRateController = TextEditingController(text: '0');
  final _posFeeController = TextEditingController(text: '0');
  
  // Business Types
  static const List<String> _businessTypes = [
    'Pharmacy',
    'Restaurant',
    'General Store',
    'Departmental Store',
    'Grocery Store',
    'Electronics Store',
    'Clothing Store',
    'Hardware Store',
    'Other',
  ];
  String _selectedBusinessType = 'Pharmacy';
  bool _showCustomType = false;
  
  // State
  DateTime _subscriptionStart = DateTime.now();
  DateTime _subscriptionEnd = DateTime.now().add(const Duration(days: 14));
  bool _isPaid = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ownerEmailController.text = widget.email;
  }

  void _registerShop() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    final securityKey = 'KEY-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase()}-BIZ';
    final shopOwnerEmail = _ownerEmailController.text.trim().toLowerCase();
    final businessType = _showCustomType ? _customTypeController.text.trim() : _selectedBusinessType;

    try {
      final repo = ref.read(shopRepositoryProvider);
      await repo.registerShop(
         shopName: _businessNameController.text.trim().isEmpty 
             ? 'My Business' 
             : _businessNameController.text.trim(),
         ownerName: _ownerNameController.text.trim(),
         email: shopOwnerEmail,
         phone: _phoneController.text.trim(),
         address: _addressController.text.trim(),
         start: _subscriptionStart,
         end: _subscriptionEnd,
         isPaid: _isPaid,
         securityKey: securityKey,
         businessType: businessType,
         businessDesc: _businessDescController.text.trim(),
         website: _websiteController.text.trim(),
         gstRate: double.tryParse(_gstRateController.text) ?? 0,
         posFee: double.tryParse(_posFeeController.text) ?? 0,
      );

      if (!mounted) return;

      _showSuccessDialog(securityKey, shopOwnerEmail);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration Failed: $e'), backgroundColor: AppColors.error)
      );
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String securityKey, String email) {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 28),
            ),
            const SizedBox(width: 12),
            const Text('Registration Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Login Email', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('🔑 Security Key (SAVE THIS!):', 
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      securityKey, 
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppColors.primary),
                    tooltip: 'Copy',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: securityKey));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('✅ Copied!'), backgroundColor: AppColors.success, duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                   Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                   SizedBox(width: 8),
                   Expanded(
                    child: Text(
                      'Use email + security key to login to the business dashboard.',
                      style: TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OwnerLoginScreen()));
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            icon: const Icon(Icons.login),
            label: const Text('Go to Login'),
          )
        ],
      )
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context, 
      initialDate: isStart ? _subscriptionStart : _subscriptionEnd,
      firstDate: DateTime(2020), 
      lastDate: DateTime(2030)
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _subscriptionStart = picked; 
          if (_subscriptionEnd.isBefore(picked)) _subscriptionEnd = picked.add(const Duration(days: 30));
        } else {
          _subscriptionEnd = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Register New Business'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: isWide ? 700 : double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.store, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Create Your Business', 
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('Fill in the details to get started', 
                                style: TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Business Info Section
                        _buildSectionHeader('Business Information', Icons.business),
                        const SizedBox(height: 16),
                        
                        // Business Type
                        DropdownButtonFormField<String>(
                          value: _selectedBusinessType,
                          decoration: InputDecoration(
                            labelText: 'Business Type *',
                            prefixIcon: const Icon(Icons.category),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: _businessTypes.map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          )).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedBusinessType = val!;
                              _showCustomType = val == 'Other';
                            });
                          },
                        ),
                        
                        if (_showCustomType) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _customTypeController,
                            decoration: InputDecoration(
                              labelText: 'Custom Business Type *',
                              hintText: 'e.g., Bakery, Pet Store',
                              prefixIcon: const Icon(Icons.edit),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (val) => _showCustomType && (val == null || val.isEmpty) ? 'Enter your business type' : null,
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: isWide ? 310 : double.infinity,
                              child: _buildTextField(_businessNameController, 'Business Name', Icons.storefront, required: false, hint: 'Optional'),
                            ),
                            SizedBox(
                              width: isWide ? 310 : double.infinity,
                              child: _buildTextField(_ownerNameController, 'Owner Name *', Icons.person),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(_businessDescController, 'Business Description', Icons.description, required: false, hint: 'Optional - Describe your business', maxLines: 2),
                        const SizedBox(height: 16),
                        _buildTextField(_addressController, 'Business Address', Icons.location_on, required: false, hint: 'Optional'),
                        
                        const SizedBox(height: 32),
                        _buildSectionHeader('Contact & Login', Icons.contact_phone),
                        const SizedBox(height: 16),
                        
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: isWide ? 310 : double.infinity,
                              child: _buildTextField(_ownerEmailController, 'Login Email *', Icons.email),
                            ),
                            SizedBox(
                              width: isWide ? 310 : double.infinity,
                              child: _buildTextField(_phoneController, 'Phone Number', Icons.phone, required: false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(_websiteController, 'Website', Icons.language, required: false, hint: 'Optional - e.g., www.mybusiness.com'),
                        
                        const SizedBox(height: 32),
                        _buildSectionHeader('Tax & Fees Settings', Icons.percent),
                        const SizedBox(height: 8),
                        Text('Set default values for invoices (can be changed per sale)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(height: 16),
                        
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: isWide ? 200 : double.infinity,
                              child: TextFormField(
                                controller: _gstRateController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'GST/Tax Rate (%)',
                                  hintText: '0',
                                  prefixIcon: const Icon(Icons.receipt_long),
                                  suffixText: '%',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: isWide ? 200 : double.infinity,
                              child: TextFormField(
                                controller: _posFeeController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'POS Fee',
                                  hintText: '0',
                                  prefixIcon: const Icon(Icons.point_of_sale),
                                  prefixText: 'PKR ',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        _buildSectionHeader('Subscription', Icons.card_membership),
                        const SizedBox(height: 16),
                        
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: isWide ? 200 : double.infinity,
                              child: _buildDatePicker('Start Date', _subscriptionStart, () => _pickDate(true)),
                            ),
                            SizedBox(
                              width: isWide ? 200 : double.infinity,
                              child: _buildDatePicker('End Date', _subscriptionEnd, () => _pickDate(false)),
                            ),
                            SizedBox(
                              width: isWide ? 200 : double.infinity,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _isPaid ? AppColors.success.shade50 : AppColors.warning.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _isPaid ? AppColors.success.shade200 : AppColors.warning.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(_isPaid ? Icons.check_circle : Icons.hourglass_bottom,
                                      color: _isPaid ? AppColors.success : AppColors.warning, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(_isPaid ? 'Paid' : 'Trial', style: TextStyle(fontWeight: FontWeight.bold, color: _isPaid ? AppColors.success.shade700 : AppColors.warning.shade700))),
                                    Switch(
                                      value: _isPaid,
                                      onChanged: (val) => setState(() => _isPaid = val),
                                      activeColor: AppColors.success,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _registerShop,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: _isLoading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.rocket_launch),
                            label: Text(_isLoading ? 'Registering...' : 'Register Business', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
      ],
    );
  }
  
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool required = true, String? hint, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: required ? (val) => val == null || val.isEmpty ? 'Required' : null : null,
    );
  }
  
  Widget _buildDatePicker(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(DateFormat('MMM dd, yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
