import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/database/database.dart';
import '../../utils/sample_data_importer.dart';
import 'cart_provider.dart';
import 'checkout_dialog.dart';
import 'customer_entry_dialog.dart';

// Intent classes for keyboard shortcuts
class _FocusSearchIntent extends Intent { const _FocusSearchIntent(); }
class _CheckoutIntent extends Intent { const _CheckoutIntent(); }
class _ClearSearchIntent extends Intent { const _ClearSearchIntent(); }
class _IncreaseQuantityIntent extends Intent { const _IncreaseQuantityIntent(); }
class _DecreaseQuantityIntent extends Intent { const _DecreaseQuantityIntent(); }
class _RemoveLastItemIntent extends Intent { const _RemoveLastItemIntent(); }
class _NewCustomerIntent extends Intent { const _NewCustomerIntent(); }

// Navigation Intents
class _NavUpIntent extends Intent { const _NavUpIntent(); }
class _NavDownIntent extends Intent { const _NavDownIntent(); }
class _NavLeftIntent extends Intent { const _NavLeftIntent(); }
class _NavRightIntent extends Intent { const _NavRightIntent(); }
class _SelectProductIntent extends Intent { const _SelectProductIntent(); }


class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  String _searchQuery = '';
  final FocusNode _productSearchFocus = FocusNode();
  final FocusNode _customerNameFocus = FocusNode();
  final FocusNode _amountReceivedFocus = FocusNode();
  final ScrollController _productGridController = ScrollController();
  
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _amountReceivedController = TextEditingController();
  
  List<Customer> _customerSearchResults = [];
  bool _isSearchingCustomer = false;
  
  // Selection State
  int _selectedProductIndex = 0;
  int _crossAxisCount = 4; // Default, updated by LayoutBuilder
  
  // Payment State
  String _paymentMode = 'Cash'; // Cash, Card, Online
  double _changeReturn = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load or create walk-in customer
      final customerRepo = ref.read(customerRepositoryProvider);
      final walkInCustomer = await customerRepo.createOrGetCustomer('Walk-in Customer', null);
      if (mounted) {
        ref.read(cartProvider.notifier).setCustomer(walkInCustomer);
        _customerNameController.text = walkInCustomer.name;
        _customerPhoneController.text = walkInCustomer.phoneNumber ?? '';
        
        // Focus on product search
        _productSearchFocus.requestFocus();

        // Check and load sample data if empty
        _checkAndLoadSampleData();
      }
    });
  }

  Future<void> _checkAndLoadSampleData() async {
    final medicineRepo = ref.read(medicineRepositoryProvider);
    final medicines = await medicineRepo.getAllMedicines();
    
    if (medicines.isEmpty) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Initializing database with sample data...'), duration: Duration(seconds: 2)),
      );

      try {
        final database = ref.read(databaseProvider);
        final importer = SampleDataImporter(database);
        await importer.importAllData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Sample data loaded!'), backgroundColor: Colors.green),
          );
          setState(() {}); 
        }
      } catch (e) {
        print('Error auto-loading data: $e');
      }
    }
  }

  @override
  void dispose() {
    _productSearchFocus.dispose();
    _customerNameFocus.dispose();
    _amountReceivedFocus.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _amountReceivedController.dispose();
    _productGridController.dispose();
    super.dispose();
  }

  // --- Keyboard Navigation Logic ---
  void _moveSelection(int delta, int totalItems) {
    if (totalItems == 0) return;
    setState(() {
      int newIndex = _selectedProductIndex + delta;
      if (newIndex < 0) newIndex = 0;
      if (newIndex >= totalItems) newIndex = totalItems - 1;
      _selectedProductIndex = newIndex;
    });
    _scrollToSelected();
  }

  void _scrollToSelected() {
    if (!_productGridController.hasClients) return;
    // Basic auto-scroll logic (approximate row height ~200)
    // A more precise way requires specific item contexts, but this is usually sufficient for grid
    final row = (_selectedProductIndex / _crossAxisCount).floor();
    final offset = row * 150.0; // Approx card height
    // Don't scroll if already visible (this is simplistic, improves UX slightly)
    if (offset < _productGridController.offset || offset > _productGridController.offset + _productGridController.position.viewportDimension) {
        _productGridController.animateTo(
          offset, 
          duration: const Duration(milliseconds: 200), 
          curve: Curves.easeOut
        );
    }
  }

  Future<void> _addProductToIndex(int index, List<Medicine> filteredList) async {
      if (index < 0 || index >= filteredList.length) return;
      final medicine = filteredList[index];
      
      // Auto-add logic
      final medicineRepo = ref.read(medicineRepositoryProvider);
      final cartNotifier = ref.read(cartProvider.notifier);
      final batches = await medicineRepo.getBatchesForMedicine(medicine.id);
      
      final availableBatches = batches.where((b) => b.quantity > 0).toList();
      if (availableBatches.isNotEmpty) {
        availableBatches.sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
        final bestBatch = availableBatches.first;
        
        cartNotifier.addItem(medicine, bestBatch);
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars(); // Prevent stack up
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${medicine.name} added'), 
              backgroundColor: Colors.teal, 
              duration: const Duration(milliseconds: 300),
              behavior: SnackBarBehavior.floating,
              width: 300,
            )
          );
        }
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Out of Stock'), backgroundColor: Colors.red, duration: Duration(seconds: 1)),
          );
        }
      }
  }

  // --- Existing Logic ---

  Future<void> _searchCustomers(String query) async {
    if (query.isEmpty || query.length < 2) {
      setState(() { _customerSearchResults = []; _isSearchingCustomer = false; });
      return;
    }
    setState(() => _isSearchingCustomer = true);
    final repo = ref.read(customerRepositoryProvider);
    final results = await repo.searchCustomers(query);
    setState(() { _customerSearchResults = results; _isSearchingCustomer = false; });
  }

  void _selectCustomer(Customer customer) {
    _customerNameController.text = customer.name;
    _customerPhoneController.text = customer.phoneNumber ?? '';
    ref.read(cartProvider.notifier).setCustomer(customer);
    setState(() => _customerSearchResults = []);
    _productSearchFocus.requestFocus();
  }

  void _calculateChange() {
    final cart = ref.read(cartProvider);
    final received = double.tryParse(_amountReceivedController.text) ?? 0.0;
    setState(() => _changeReturn = received - cart.grandTotal);
  }

  void _handleCheckout() {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }
    showDialog(context: context, builder: (context) => const CheckoutDialog()).then((_) {
      _amountReceivedController.clear();
      setState(() { _changeReturn = 0.0; _paymentMode = 'Cash'; });
      _productSearchFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final medicineRepo = ref.watch(medicineRepositoryProvider);
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    
    // Filter medicines first to know the list for navigation
    return StreamBuilder<List<Medicine>>(
      stream: medicineRepo.watchAllMedicines(),
      builder: (context, snapshot) {
        final allMedicines = snapshot.data ?? [];
        List<Medicine> filteredMedicines = allMedicines;
        if (_searchQuery.isNotEmpty) {
          filteredMedicines = allMedicines.where((m) =>
            m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (m.code?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
          ).toList();
        }

        return Shortcuts(
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const _FocusSearchIntent(),
            LogicalKeySet(LogicalKeyboardKey.f2): const _CheckoutIntent(),
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.enter): const _CheckoutIntent(),
            LogicalKeySet(LogicalKeyboardKey.escape): const _ClearSearchIntent(),
            LogicalKeySet(LogicalKeyboardKey.arrowUp): const _NavUpIntent(),
            LogicalKeySet(LogicalKeyboardKey.arrowDown): const _NavDownIntent(),
            LogicalKeySet(LogicalKeyboardKey.arrowLeft): const _NavLeftIntent(),
            LogicalKeySet(LogicalKeyboardKey.arrowRight): const _NavRightIntent(),
            LogicalKeySet(LogicalKeyboardKey.enter): const _SelectProductIntent(),
            LogicalKeySet(LogicalKeyboardKey.numpadEnter): const _SelectProductIntent(),
            // Cart shortcuts
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowUp): const _IncreaseQuantityIntent(),
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowDown): const _DecreaseQuantityIntent(),
            LogicalKeySet(LogicalKeyboardKey.delete): const _RemoveLastItemIntent(),
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const _NewCustomerIntent(),
          },
          child: Actions(
            actions: {
              _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(onInvoke: (_) { _productSearchFocus.requestFocus(); return null; }),
              _CheckoutIntent: CallbackAction<_CheckoutIntent>(onInvoke: (_) { _handleCheckout(); return null; }),
              _ClearSearchIntent: CallbackAction<_ClearSearchIntent>(onInvoke: (_) { 
                setState(() { _searchQuery = ''; _selectedProductIndex = 0; });
                _productSearchFocus.requestFocus(); return null; 
              }),
              _NavUpIntent: CallbackAction<_NavUpIntent>(onInvoke: (_) { _moveSelection(-_crossAxisCount, filteredMedicines.length); return null; }),
              _NavDownIntent: CallbackAction<_NavDownIntent>(onInvoke: (_) { _moveSelection(_crossAxisCount, filteredMedicines.length); return null; }),
              _NavLeftIntent: CallbackAction<_NavLeftIntent>(onInvoke: (_) { _moveSelection(-1, filteredMedicines.length); return null; }),
              _NavRightIntent: CallbackAction<_NavRightIntent>(onInvoke: (_) { _moveSelection(1, filteredMedicines.length); return null; }),
              _SelectProductIntent: CallbackAction<_SelectProductIntent>(onInvoke: (_) { 
                // Only trigger if we are focused on search/grid, not amount field
                if (!_amountReceivedFocus.hasFocus) {
                   _addProductToIndex(_selectedProductIndex, filteredMedicines);
                }
                return null; 
              }),
               // Cart Actions
              _IncreaseQuantityIntent: CallbackAction<_IncreaseQuantityIntent>(onInvoke: (_) { if (cart.items.isNotEmpty) cartNotifier.updateQuantity(cart.items.last.batch.id, cart.items.last.quantity + 1); return null; }),
              _DecreaseQuantityIntent: CallbackAction<_DecreaseQuantityIntent>(onInvoke: (_) { if (cart.items.isNotEmpty) cartNotifier.updateQuantity(cart.items.last.batch.id, cart.items.last.quantity - 1); return null; }),
              _RemoveLastItemIntent: CallbackAction<_RemoveLastItemIntent>(onInvoke: (_) { if (cart.items.isNotEmpty) cartNotifier.removeItem(cart.items.last.batch.id); return null; }),
              _NewCustomerIntent: CallbackAction<_NewCustomerIntent>(onInvoke: (_) { showDialog(context: context, builder: (_) => const CustomerEntryDialog()).then((c) { if (c != null) _selectCustomer(c as Customer); }); return null; }),
            },
            child: Focus(
              autofocus: true,
              child: Scaffold(
                body: Column(
                  children: [
                    _buildTopBar(),
                    _buildCustomerSection(),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5, // Increased flex for product grid
                            child: Column(
                              children: [
                                _buildSearchSection(),
                                Expanded(child: _buildProductGrid(filteredMedicines, medicineRepo, cartNotifier)),
                              ],
                            ),
                          ),
                          VerticalDivider(width: 1, color: Colors.grey.shade300),
                          Expanded(
                            flex: 3, // Dedicate 3/8ths to Cart
                            child: _buildCartPanel(cart, cartNotifier),
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
    );
  }

  // --- Widgets ---
  
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.teal,
      child: Row(
        children: [
          const Icon(Icons.point_of_sale, color: Colors.white),
          const SizedBox(width: 12),
          const Text('Point of Sale', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          _buildHeaderAction(Icons.add_circle_outline, 'New Sale', () {
            ref.read(cartProvider.notifier).clear();
            _amountReceivedController.clear();
            setState(() { _changeReturn = 0.0; _selectedProductIndex = 0; _searchQuery = ''; });
            _productSearchFocus.requestFocus();
          }),
          const SizedBox(width: 16),
          _buildHeaderAction(Icons.pause_circle_outline, 'Hold', () {}),
          const SizedBox(width: 16),
          _buildHeaderAction(Icons.history, 'Resume', () {}),
          Container(height: 24, width: 1, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 16)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
               const Text('Ali Khan – Cashier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
               StreamBuilder(
                 stream: Stream.periodic(const Duration(seconds: 1)),
                 builder: (_, __) => Text(DateFormat('MMM dd, hh:mm a').format(DateTime.now()), style: const TextStyle(color: Colors.white70, fontSize: 12)),
               ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Row(children: [Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 4), Text(label, style: const TextStyle(color: Colors.white))])),
    );
  }

  Widget _buildCustomerSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade100,
      child: Row(
        children: [
           Expanded(
             child: TextField(
               controller: _customerNameController,
               focusNode: _customerNameFocus,
               decoration: InputDecoration(
                 hintText: 'Walk-in Customer',
                 prefixIcon: const Icon(Icons.person, color: Colors.teal),
                 suffixIcon: const Icon(Icons.arrow_drop_down),
                 filled: true, fillColor: Colors.white,
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                 isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 8),
               ),
               onChanged: (val) {
                 if (val.length > 2) _searchCustomers(val);
               },
             ),
           ),
           const SizedBox(width: 12),
           SizedBox(
             width: 180,
             child: TextField(
               controller: _customerPhoneController,
               decoration: InputDecoration(
                 hintText: 'Phone (Optional)', filled: true, fillColor: Colors.white,
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                 isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
               ),
             ),
           ),
           const SizedBox(width: 12),
           ElevatedButton.icon(
             onPressed: () { 
               showDialog(context: context, builder: (_) => const CustomerEntryDialog()).then((c) { if (c != null) _selectCustomer(c as Customer); });
             },
             icon: const Icon(Icons.add, size: 18), label: const Text('New'),
             style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
           ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: TextField(
        focusNode: _productSearchFocus,
        decoration: InputDecoration(
          hintText: 'Search Product...',
          prefixIcon: const Icon(Icons.search), 
           suffixIcon: _searchQuery.isNotEmpty 
             ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() { _searchQuery = ''; _selectedProductIndex = 0; _productSearchFocus.requestFocus(); }))
             : null,
          filled: true, fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: (val) => setState(() { _searchQuery = val; _selectedProductIndex = 0; }), 
        onSubmitted: (_) { 
             // Handled by Shortcuts
        }, 
      ),
    );
  }

  Widget _buildProductGrid(List<Medicine> medicines, MedicineRepository repo, CartNotifier notifier) {
        if (medicines.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text('No products found', style: TextStyle(color: Colors.grey.shade500))]));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
             final count = (constraints.maxWidth / 160).floor().clamp(2, 6);
             if (_crossAxisCount != count) {
                 WidgetsBinding.instance.addPostFrameCallback((_) => _crossAxisCount = count);
             }

             return GridView.builder(
               controller: _productGridController,
               padding: const EdgeInsets.all(12),
               gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                 crossAxisCount: count,
                 childAspectRatio: 0.85,
                 crossAxisSpacing: 10,
                 mainAxisSpacing: 10,
               ),
               itemCount: medicines.length,
               itemBuilder: (context, index) {
                 final isSelected = index == _selectedProductIndex;
                 return _buildProductCard(medicines[index], repo, notifier, isSelected);
               },
             );
          },
        );
  }

  Widget _buildProductCard(Medicine medicine, MedicineRepository repo, CartNotifier notifier, bool isSelected) {
    return FutureBuilder<List<Batch>>(
      future: repo.getBatchesForMedicine(medicine.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Card(elevation: 0, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
        
        final batches = snapshot.data!;
        final totalStock = batches.fold(0, (sum, b) => sum + b.quantity);
        final hasStock = totalStock > 0;
        final bestBatch = hasStock ? (batches.where((b) => b.quantity > 0).toList()..sort((a,b) => b.expiryDate.compareTo(a.expiryDate))).first : null;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: isSelected 
              ? Border.all(color: Colors.teal, width: 3) 
              : Border.all(color: Colors.grey.shade200),
            boxShadow: isSelected 
              ? [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
              : [const BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: hasStock ? () { notifier.addItem(medicine, bestBatch!); } : null,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Expanded(
                     child: Container(
                       padding: const EdgeInsets.all(10),
                       decoration: BoxDecoration(
                          color: hasStock ? Colors.teal.shade50 : Colors.grey.shade100,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(medicine.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, color: hasStock ? Colors.black87 : Colors.grey, fontSize: 13)),
                           const SizedBox(height: 4),
                           Text(medicine.mainCategory ?? 'Medicine', style: TextStyle(fontSize: 11, color: hasStock ? Colors.teal.shade700 : Colors.grey)),
                           const Spacer(),
                           if (bestBatch != null)
                              Text('PKR ${bestBatch.salePrice.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: hasStock ? Colors.teal : Colors.grey)),
                         ],
                       ),
                     ),
                   ),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                     decoration: const BoxDecoration(
                       borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                     ),
                     child: Row(
                       children: [
                         Expanded(child: Text(hasStock ? 'Stock: $totalStock' : 'Out of Stock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: hasStock ? Colors.green : Colors.red))),
                         if (hasStock)
                           if (isSelected) const Icon(Icons.add_shopping_cart, size: 16, color: Colors.teal)
                       ],
                     ),
                   ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartPanel(CartState cart, CartNotifier notifier) {
    return Container(
      color: Colors.grey.shade50, 
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade200,
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_outlined, size: 20),
                const SizedBox(width: 8),
                const Text('Current Bill', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (cart.items.isNotEmpty)
                  TextButton.icon(onPressed: () { notifier.clear(); _amountReceivedController.clear(); setState(() => _changeReturn = 0.0); }, icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red), label: const Text('Clear', style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
          Expanded(
            child: cart.items.isEmpty 
              ? Center(child: Text('Cart is empty', style: TextStyle(color: Colors.grey.shade400)))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.items.length,
                  separatorBuilder: (_,__) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 90,
                            height: 32,
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4), color: Colors.white),
                            child: Row(
                               children: [
                                 InkWell(onTap: () { if (item.quantity > 1) notifier.updateQuantity(item.batch.id, item.quantity - 1); else notifier.removeItem(item.batch.id); }, child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.remove, size: 14))),
                                 Expanded(child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                                 InkWell(onTap: () => notifier.updateQuantity(item.batch.id, item.quantity + 1), child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.add, size: 14))),
                               ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.medicine.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text('${item.quantity} x ${item.batch.salePrice.toStringAsFixed(0)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('PKR ${(item.quantity * item.batch.salePrice).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              InkWell(onTap: () => notifier.removeItem(item.batch.id), child: const Icon(Icons.delete_outline, size: 16, color: Colors.red)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
          _buildPaymentSection(cart, notifier),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(CartState cart, CartNotifier notifier) {
     return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0,-2))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               _buildSummaryRow('Subtotal', cart.subTotal),
               _buildSummaryRow('Discount', cart.discount),
               const Divider(height: 16),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                   Text('PKR ${cart.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                 ],
               ),
               const SizedBox(height: 8),
               Row(
                 children: [
                   Expanded(child: _buildPaymentModeBtn('Cash', Icons.money)),
                   const SizedBox(width: 8),
                   Expanded(child: _buildPaymentModeBtn('Card', Icons.credit_card)),
                   const SizedBox(width: 8),
                   Expanded(child: _buildPaymentModeBtn('Online', Icons.qr_code)),
                 ],
               ),
               const SizedBox(height: 8),
               Row(
                 children: [
                   Expanded(
                     child: SizedBox(
                       height: 48,
                       child: TextField(
                         controller: _amountReceivedController,
                         focusNode: _amountReceivedFocus,
                         decoration: const InputDecoration(labelText: 'Amount', prefixText: 'PKR ', isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                         keyboardType: TextInputType.number,
                         onChanged: (_) => _calculateChange(),
                         onSubmitted: (_) => _handleCheckout(),
                       ),
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Container(
                       height: 48,
                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                       decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Text('Change', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                           Text('PKR ${_changeReturn.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: _changeReturn < 0 ? Colors.red : Colors.black87, fontSize: 13)),
                         ],
                       ),
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 8),
               SizedBox(
                 width: double.infinity,
                 height: 42,
                 child: ElevatedButton(
                   onPressed: cart.items.isNotEmpty ? _handleCheckout : null,
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, elevation: 1),
                   child: const Text('CHECKOUT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                 ),
               ),
            ],
          ),
        );
  }

  Widget _buildSummaryRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey)), Text('PKR ${value.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w500))]),
    );
  }

  Widget _buildPaymentModeBtn(String mode, IconData icon) {
    final isSelected = _paymentMode == mode;
    return InkWell(
      onTap: () => setState(() => _paymentMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: isSelected ? Colors.teal : Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: isSelected ? Colors.teal : Colors.grey.shade300)),
        child: Column(children: [Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey), const SizedBox(height: 4), Text(mode, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : Colors.grey.shade700))]),
      ),
    );
  }
}
