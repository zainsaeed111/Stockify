import 'package:flutter/material.dart';
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
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  // State
  DateTime _subscriptionStart = DateTime.now();
  DateTime _subscriptionEnd = DateTime.now().add(const Duration(days: 14)); // 14 day trial default
  bool _isPaid = false;
  bool _isLoading = false;

  void _registerShop() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    // Generate Key
    final securityKey = 'KEY-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase()}-SHOP';
    final shopOwnerEmail = _ownerEmailController.text.trim().toLowerCase();

    try {
      final repo = ref.read(shopRepositoryProvider);
      await repo.registerShop(
         shopName: _shopNameController.text.trim(),
         ownerName: _ownerNameController.text.trim(),
         email: shopOwnerEmail,
         phone: _phoneController.text.trim(),
         address: _addressController.text.trim(),
         start: _subscriptionStart,
         end: _subscriptionEnd,
         isPaid: _isPaid,
         securityKey: securityKey,
      );

      if (!mounted) return;

      showDialog(
        context: context, 
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Registration Successful')]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Business has been registered successfully!'),
              const SizedBox(height: 16),
              Text('Email: $shopOwnerEmail', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Security Key (SAVE THIS!):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        securityKey, 
                        style: const TextStyle(fontFamily: 'Courier', fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.teal),
                      tooltip: 'Copy to Clipboard',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: securityKey));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Security Key copied to clipboard!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
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
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The business owner will use this email and security key to login.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(onPressed: () {
              Navigator.pop(ctx); // Close dialog
              // Go back to login screen instead of dashboard
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OwnerLoginScreen()));
            }, child: const Text('Done - Go to Login'))
          ],
        )
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration Failed: $e'), backgroundColor: Colors.red));
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
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
          // Auto adjust end if it becomes before start
          if (_subscriptionEnd.isBefore(picked)) _subscriptionEnd = picked.add(const Duration(days: 30));
        } else {
          _subscriptionEnd = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register New Business')),
      body: Center(
        child: Container(
          width: 600,
          margin: const EdgeInsets.all(24),
          child: Card(
             child: Padding(
               padding: const EdgeInsets.all(32),
               child: Form(
                 key: _formKey,
                 child: ListView(
                   shrinkWrap: true,
                   children: [
                     const Text('Business Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                     const Divider(),
                     const SizedBox(height: 16),
                     
                     Row(
                       children: [
                         Expanded(child: _buildTextField(_shopNameController, 'Business Name', Icons.business)),
                         const SizedBox(width: 16),
                         Expanded(child: _buildTextField(_ownerNameController, 'Owner Name', Icons.person)),
                       ],
                     ),
                     const SizedBox(height: 16),
                     _buildTextField(_ownerEmailController, 'Business Owner Email (for login)', Icons.email),
                     const SizedBox(height: 16),
                     Row(
                       children: [
                         Expanded(child: _buildTextField(_phoneController, 'Phone Number', Icons.phone)),
                         const SizedBox(width: 16),
                         Expanded(child: _buildTextField(_addressController, 'Address (Optional)', Icons.location_on, required: false)),
                       ],
                     ),
                     
                     const SizedBox(height: 32),
                     const Text('Subscription & Billing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                     const Divider(),
                     const SizedBox(height: 16),
                     
                     Row(
                       children: [
                         Expanded(
                           child: InkWell(
                             onTap: () => _pickDate(true),
                             child: InputDecorator(
                               decoration: const InputDecoration(labelText: 'Start Date', prefixIcon: Icon(Icons.date_range)),
                               child: Text(DateFormat('yyyy-MM-dd').format(_subscriptionStart)),
                             ),
                           ),
                         ),
                         const SizedBox(width: 16),
                         Expanded(
                            child: InkWell(
                             onTap: () => _pickDate(false),
                             child: InputDecorator(
                               decoration: const InputDecoration(labelText: 'End Date', prefixIcon: Icon(Icons.event_busy)),
                               child: Text(DateFormat('yyyy-MM-dd').format(_subscriptionEnd)),
                             ),
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 16),
                     SwitchListTile(
                       title: const Text('Payment Status'),
                       subtitle: Text(_isPaid ? 'Paid' : 'Unpaid / Trial'),
                       value: _isPaid,
                       onChanged: (val) => setState(() => _isPaid = val),
                       secondary: Icon(_isPaid ? Icons.check_circle : Icons.pending, color: _isPaid ? Colors.green : Colors.orange),
                     ),
                     
                     const SizedBox(height: 40),
                     SizedBox(
                       height: 50,
                       child: ElevatedButton(
                         onPressed: _isLoading ? null : _registerShop,
                         child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('REGISTER BUSINESS'),
                       ),
                     ),
                   ],
                 ),
               ),
             ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool required = true}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: required ? (val) => val == null || val.isEmpty ? 'Required' : null : null,
    );
  }
}
