import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/providers/current_shop_provider.dart';
import '../dashboard/dashboard_screen.dart';
import 'owner_login_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _securityKeyController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    // Remove all whitespace just in case user copied with spaces
    final key = _securityKeyController.text.replaceAll(RegExp(r'\s+'), '');
    
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your security key'))
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(shopRepositoryProvider);
      final businessData = await repo.getShopBySecurityKey(key);

      if (businessData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid Security Key: "$key" not found.'), 
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            )
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      // Store business data in provider for use throughout the app
      ref.read(currentShopProvider.notifier).setShop(businessData);

      // Save key for persistent login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('security_key', key);

      // Success! Login
      if (mounted) {
        final businessName = businessData['shopName'] ?? 'Business';
        final ownerName = businessData['ownerName'] ?? 'Owner';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to $businessName, $ownerName!'),
            backgroundColor: Colors.green,
          )
        );
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => const DashboardScreen()
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login Error: $e'), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          )
        );
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Card(
              elevation: 8,
              margin: const EdgeInsets.all(20),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long, size: 64, color: Color(0xFF6366F1)),
                    const SizedBox(height: 16),
                    const Text('Billingly', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                    const SizedBox(height: 8),
                    const Text('Business Owner Login', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 32),
                    
                    TextField(
                      controller: _securityKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Security Key',
                        prefixIcon: Icon(Icons.vpn_key),
                        hintText: 'Enter your security key',
                      ),
                      obscureText: true,
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('LOGIN'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Enter the security key given during business registration',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Super Admin button (top right)
          Positioned(
            top: 40,
            right: 40,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.admin_panel_settings, color: Color(0xFF6366F1), size: 28),
                    tooltip: 'Super Admin',
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerLoginScreen()));
                    },
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Admin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
