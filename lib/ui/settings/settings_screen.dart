import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/providers/current_shop_provider.dart';
import '../../data/database/database.dart';

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
      ref.read(currentShopProvider.notifier).state = updatedData;

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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (businessData != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Icon(Icons.business, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    businessData['shopName'] ?? 'Business',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    businessData['email'] ?? '',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.verified, color: Colors.teal),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(child: Text('No business data loaded. Please login again.')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: _businessNameController,
                      decoration: const InputDecoration(
                        labelText: 'Business Name',
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ownerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Owner Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isUpdating ? null : _updateBusinessInfo,
                        icon: _isUpdating 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save),
                        label: const Text('Save Business Information'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            _buildSectionHeader('Data Management'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Backup Database'),
                subtitle: const Text('Save a copy of your data'),
                trailing: ElevatedButton(
                  onPressed: _backupDatabase,
                  child: const Text('Backup'),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Restore Database'),
                subtitle: const Text('Restore from a backup file'),
                trailing: ElevatedButton(
                  onPressed: _restoreDatabase,
                  child: const Text('Restore'),
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
                            title: Text(user.username),
                            subtitle: Text(user.role),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {},
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add User'),
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
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
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
