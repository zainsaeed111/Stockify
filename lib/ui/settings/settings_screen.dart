import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/providers/current_shop_provider.dart';
import '../../data/database/database.dart';
import '../theme/app_theme.dart';
import 'category_management_screen.dart';
import 'pos_settings_screen.dart';
import 'product_form_settings_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Business Info Controllers
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isUpdating = false;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    // Load data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBusinessData());
  }

  void _loadBusinessData() {
    final businessData = ref.read(currentShopProvider);
    if (businessData != null && !_dataLoaded) {
      setState(() {
        _businessNameController.text = businessData['shopName'] ?? '';
        _ownerNameController.text = businessData['ownerName'] ?? '';
        _addressController.text = businessData['address'] ?? '';
        _phoneController.text = businessData['phone'] ?? '';
        _dataLoaded = true;
      });
    }
  }

  Future<void> _updateBusinessInfo() async {
    final businessData = ref.read(currentShopProvider);
    if (businessData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No business data available'), backgroundColor: Colors.red)
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final repo = ref.read(shopRepositoryProvider);
      await repo.updateShopInfo(
        email: businessData['email'] ?? '',
        shopName: _businessNameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      // Update the local provider
      final updatedData = Map<String, dynamic>.from(businessData);
      updatedData['shopName'] = _businessNameController.text.trim();
      updatedData['ownerName'] = _ownerNameController.text.trim();
      updatedData['phone'] = _phoneController.text.trim();
      updatedData['address'] = _addressController.text.trim();
      ref.read(currentShopProvider.notifier).setShop(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business information updated!'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRepo = ref.watch(userRepositoryProvider);
    final businessData = ref.watch(currentShopProvider);

    // Reload data if provider changed
    if (businessData != null && !_dataLoaded) {
      _loadBusinessData();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Administration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business Information Section
            _buildSectionHeader('Business Information'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    if (businessData != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Icon(Icons.business, color: Theme.of(context).colorScheme.onPrimary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    businessData['shopName'] ?? 'Business',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
                                  ),
                                  Text(
                                    businessData['email'] ?? '',
                                    style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.verified, color: Theme.of(context).colorScheme.primary),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
                            const SizedBox(width: 8),
                            Expanded(child: Text('No business data loaded. Please login again.', style: GoogleFonts.inter())),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    TextField(
                      controller: _businessNameController,
                      decoration: InputDecoration(
                        labelText: 'Business Name',
                        labelStyle: GoogleFonts.inter(),
                        prefixIcon: Icon(Icons.business, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _ownerNameController,
                      decoration: InputDecoration(
                        labelText: 'Owner Name',
                        labelStyle: GoogleFonts.inter(),
                        prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: GoogleFonts.inter(),
                        prefixIcon: Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        labelStyle: GoogleFonts.inter(),
                        prefixIcon: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isUpdating ? null : _updateBusinessInfo,
                        icon: _isUpdating 
                          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary)))
                          : Icon(Icons.save, color: Theme.of(context).colorScheme.onPrimary),
                        label: Text('Save Business Information', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Inventory Settings Section
            _buildSectionHeader('Inventory Settings'),
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.category, color: Theme.of(context).colorScheme.primary),
                ),
                title: Text('Manage Categories', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: Text('Add custom categories & subcategories', style: GoogleFonts.inter()),
                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.point_of_sale, color: Theme.of(context).colorScheme.secondary),
                ),
                title: Text('Manage POS', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: Text('Configure Defaults (Tax, GST, Fees, Discount)', style: GoogleFonts.inter()),
                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PosSettingsScreen()),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary?.withOpacity(0.1) ?? Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.input, color: Theme.of(context).colorScheme.tertiary ?? Theme.of(context).colorScheme.primary),
                ),
                title: Text('Product Entry Form', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: Text('Customize fields (Hide/Show)', style: GoogleFonts.inter()),
                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProductFormSettingsScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            
            _buildSectionHeader('Data Management'),
            Card(
              child: ListTile(
                leading: Icon(Icons.backup, color: Theme.of(context).colorScheme.primary),
                title: Text('Backup Database', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: Text('Save a copy of your data', style: GoogleFonts.inter()),
                trailing: ElevatedButton(
                  onPressed: _backupDatabase,
                  child: Text('Backup', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.restore, color: Theme.of(context).colorScheme.primary),
                title: Text('Restore Database', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: Text('Restore from a backup file', style: GoogleFonts.inter()),
                trailing: ElevatedButton(
                  onPressed: _restoreDatabase,
                  child: Text('Restore', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                ),
              ),
            ),
            const SizedBox(height: 30),

            _buildSectionHeader('User Management'),
            FutureBuilder<List<User>>(
              future: userRepo.getAllUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final users = snapshot.data!;
                return Card(
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return ListTile(
                            leading: CircleAvatar(child: Text(user.username[0].toUpperCase())),
                            title: Text(user.username, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                            subtitle: Text(user.role, style: GoogleFonts.inter()),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                              onPressed: () {},
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
                          label: Text('Add User', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          onPressed: () => _showAddUserDialog(context, userRepo),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Text(title, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
    );
  }

  Future<void> _backupDatabase() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dbFolder.path, 'pharmacy_db.sqlite');
      final dbFile = File(dbPath);

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup',
        fileName: 'pharmacy_backup_${DateTime.now().millisecondsSinceEpoch}.sqlite',
      );

      if (outputFile != null) {
        await dbFile.copy(outputFile);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup Successful!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup Failed: $e')));
    }
  }

  Future<void> _restoreDatabase() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore requires app restart. Feature pending.')));
  }

  void _showAddUserDialog(BuildContext context, UserRepository userRepo) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    String role = 'Cashier';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            DropdownButtonFormField<String>(
              value: role,
              items: ['Admin', 'Manager', 'Cashier'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => role = v!,
              decoration: const InputDecoration(labelText: 'Role'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (usernameController.text.isNotEmpty && passwordController.text.isNotEmpty) {
                await userRepo.registerUser(usernameController.text, passwordController.text, role);
                if (context.mounted) Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
