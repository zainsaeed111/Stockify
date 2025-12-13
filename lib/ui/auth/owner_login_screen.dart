import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shop_registration_screen.dart';

/// Super Admin credentials
const String kSuperAdminEmail = 'iamzainofficial4211@gmail.com';
const String kSuperAdminPassword = 'admin@stockify2024';

class OwnerLoginScreen extends ConsumerStatefulWidget {
  const OwnerLoginScreen({super.key});

  @override
  ConsumerState<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends ConsumerState<OwnerLoginScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  void _login() {
    final password = _passwordController.text.trim();
    
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the admin password'))
      );
      return;
    }

    setState(() => _isLoading = true);

    // Verify password
    if (password == kSuperAdminPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Welcome, Super Admin!'),
          backgroundColor: Colors.green,
        )
      );
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => ShopRegistrationScreen(email: kSuperAdminEmail)
      ));
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Invalid password'),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Super Admin')),
      body: Center(
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.all(24),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings, size: 64, color: Colors.teal),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Super Admin',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Register new businesses in Stockify',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                
                // Fixed email display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email, color: Colors.teal),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          kSuperAdminEmail,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.verified, color: Colors.teal),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Admin Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  onSubmitted: (_) => _login(),
                ),
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _login,
                    icon: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.login),
                    label: const Text('LOGIN & REGISTER BUSINESS'),
                  ),
                ),
                
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Only the Super Admin can register new businesses.\nBusiness owners login from the main screen with their security key.',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
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
    );
  }
}
