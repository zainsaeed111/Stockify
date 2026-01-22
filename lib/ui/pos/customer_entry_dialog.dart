import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/database/database.dart';
import '../theme/app_colors.dart';

class CustomerEntryDialog extends ConsumerStatefulWidget {
  final Customer? initialCustomer;

  const CustomerEntryDialog({super.key, this.initialCustomer});

  @override
  ConsumerState<CustomerEntryDialog> createState() => _CustomerEntryDialogState();
}

class _CustomerEntryDialogState extends ConsumerState<CustomerEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  bool _isSearching = false;
  List<Customer> _searchResults = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialCustomer != null) {
      _nameController.text = widget.initialCustomer!.name;
      _phoneController.text = widget.initialCustomer!.phoneNumber ?? '';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _searchCustomers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);
    final repo = ref.read(customerRepositoryProvider);
    final results = await repo.searchCustomers(query);
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(customerRepositoryProvider);
    final customer = await repo.createOrGetCustomer(
      _nameController.text.trim(),
      _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
    );

    if (context.mounted) {
      Navigator.pop(context, customer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.enter): _SubmitIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): _CancelIntent(),
      },
      child: Actions(
        actions: {
          _SubmitIntent: CallbackAction<_SubmitIntent>(onInvoke: (_) => _handleSubmit()),
          _CancelIntent: CallbackAction<_CancelIntent>(onInvoke: (_) => Navigator.pop(context)),
        },
        child: Focus(
          autofocus: true,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Customer Information',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          tooltip: 'Close (Esc)',
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                    TextFormField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name *',
                        prefixIcon: Icon(Icons.person),
                        hintText: 'Enter customer name',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                      onChanged: (value) {
                        if (value.length > 2) {
                          _searchCustomers(value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      focusNode: _phoneFocus,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (Optional)',
                        prefixIcon: Icon(Icons.phone),
                        hintText: 'Enter phone number',
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleSubmit(),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(15),
                      ],
                    ),
                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_searchResults.isNotEmpty && _nameController.text.length > 2)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final customer = _searchResults[index];
                            return ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(customer.name),
                              subtitle: customer.phoneNumber != null
                                  ? Text(customer.phoneNumber!)
                                  : null,
                              onTap: () {
                                _nameController.text = customer.name;
                                _phoneController.text = customer.phoneNumber ?? '';
                                setState(() {
                                  _searchResults = [];
                                });
                                Navigator.pop(context, customer);
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel (Esc)'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: const Text('Add Customer (Enter)'),
                        ),
                      ],
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
}

class _SubmitIntent extends Intent {
  const _SubmitIntent();
}

class _CancelIntent extends Intent {
  const _CancelIntent();
}


