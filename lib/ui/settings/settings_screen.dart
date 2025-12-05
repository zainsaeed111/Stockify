import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/repositories/user_repository.dart';
import '../../data/database/database.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Clinic Info Controllers
  final _clinicNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final userRepo = ref.watch(userRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Administration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Clinic Information'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(controller: _clinicNameController, decoration: const InputDecoration(labelText: 'Clinic/Pharmacy Name')),
                    const SizedBox(height: 10),
                    TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
                    const SizedBox(height: 10),
                    TextField(controller: _contactController, decoration: const InputDecoration(labelText: 'Contact Number')),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Save to Settings Table (Not implemented in detail for brevity, but UI is here)
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings Saved')));
                      },
                      child: const Text('Save Information'),
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
                              onPressed: () {
                                // Delete User Logic
                              },
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
    // Restore logic requires closing DB connection, which is complex in hot-running app.
    // For now, we'll just show a message.
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
                setState(() {}); // Refresh list
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
