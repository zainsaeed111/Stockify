import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/database/database.dart';
import '../../utils/sample_data_importer.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import 'cart_provider.dart';
import 'checkout_dialog.dart';
import 'customer_entry_dialog.dart';
import 'stock_warning_dialog.dart';


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
  final int _crossAxisCount = 1; // List view always has 1 "column" effectively for navigation logic

  // Payment State
  String _paymentMode = 'Cash'; // Cash, Card, Online
  double _changeReturn = 0.0;
  
  // Track products where user chose "Don't show warning again"
  final Set<int> _dismissedStockWarnings = {};

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
            const SnackBar(content: Text('✅ Sample data loaded!'), backgroundColor: AppColors.success),
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
    final itemHeight = 72.0; // Approx item height including padding/separator
    final offset = _selectedProductIndex * itemHeight;
    // Keep selected item in middle of viewport if possible
    final viewportHeight = _productGridController.position.viewportDimension;
    double targetOffset = offset - (viewportHeight / 2) + (itemHeight / 2);
    
    if (targetOffset < 0) targetOffset = 0;
    
    if (offset < _productGridController.offset || offset > _productGridController.offset + viewportHeight) {
       _productGridController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut
       );
    } else {
       // Also scroll if it's near the edge or the targetOffset is significantly different? 
       // Simplest for list is just ensuring visibility.
        if (offset < _productGridController.offset) {
          _productGridController.animateTo(offset, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        } else if (offset + itemHeight > _productGridController.offset + viewportHeight) {
          _productGridController.animateTo(offset + itemHeight - viewportHeight, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
    }
  }

  Future<void> _addProductToIndex(int index, List<Medicine> filteredList) async {
      if (index < 0 || index >= filteredList.length) return;
      final medicine = filteredList[index];
      
      final medicineRepo = ref.read(medicineRepositoryProvider);
      final cartNotifier = ref.read(cartProvider.notifier);
      final batches = await medicineRepo.getBatchesForMedicine(medicine.id);
      
      // Calculate total stock across all batches (explicit type to prevent null issues)
      final totalStock = batches.fold<int>(0, (sum, b) => sum + b.quantity);
      final alreadyInCart = cartNotifier.getMedicineQuantityInCart(medicine.id);
      
      // Find best batch (prefer ones with stock, sorted by expiry)
      final sortedBatches = List<Batch>.from(batches)
        ..sort((a, b) {
          // First prefer batches with stock
          if (a.quantity > 0 && b.quantity <= 0) return -1;
          if (b.quantity > 0 && a.quantity <= 0) return 1;
          // Then sort by expiry date (oldest first to sell first - FEFO)
          return a.expiryDate.compareTo(b.expiryDate);
        });
      
      if (sortedBatches.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No batches available for this product'), backgroundColor: AppColors.error),
          );
        }
        return;
      }
      
      final bestBatch = sortedBatches.first;
      final availableStock = totalStock - alreadyInCart;
      
      // Show warning if low stock or out of stock (unless user dismissed for this product)
      final shouldShowWarning = (availableStock <= 0 || availableStock < medicine.minStock) 
          && !_dismissedStockWarnings.contains(medicine.id);
          
      if (shouldShowWarning) {
        if (!mounted) return;
        
        final result = await StockWarningDialog.show(
          context,
          productName: medicine.name,
          availableStock: totalStock,
          requestedQuantity: 1,
          alreadyInCart: alreadyInCart,
        );
        
        if (result == null || !result.proceed) return;
        
        // If user checked "Don't show again", add to dismissed set
        if (result.dontShowAgain) {
          setState(() {
            _dismissedStockWarnings.add(medicine.id);
          });
        }
      }
      
      // Add to cart with stock info
      cartNotifier.addItem(medicine, bestBatch, totalBatchStock: totalStock);
      
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('${medicine.name} added'),
                if (availableStock <= 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('LOW STOCK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ), 
            backgroundColor: availableStock <= 0 ? AppColors.warning.shade700 : AppColors.primary, 
            duration: const Duration(milliseconds: 500),
            behavior: SnackBarBehavior.floating,
            width: 350,
          )
        );
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
    
    // Parse the amount entered on the main screen to pass to the dialog
    double? initialAmount;
    if (_amountReceivedController.text.isNotEmpty) {
      initialAmount = double.tryParse(_amountReceivedController.text.replaceAll('PKR', '').trim());
    }

    showDialog(
      context: context, 
      builder: (context) => CheckoutDialog(
        initialAmount: initialAmount,
        initialPaymentMode: _paymentMode,
      )
    ).then((_) {
      _amountReceivedController.clear();
      // Reset payment mode and change after checkout
      setState(() { 
        _changeReturn = 0.0; 
        _paymentMode = 'Cash'; 
        _customerNameController.clear(); // Clear customer field too as cart is cleared
        _customerPhoneController.clear();
      });
      _productSearchFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final medicineRepo = ref.watch(medicineRepositoryProvider);
    final cart = ref.watch(cartProvider);
    
    // Keep customer name controller in sync with cart state
    // This handles cases where customer is selected via dialog or cleared
    if (cart.customer != null && _customerNameController.text != cart.customer!.name) {
      _customerNameController.text = cart.customer!.name;
      _customerPhoneController.text = cart.customer!.phoneNumber ?? '';
    } else if (cart.customer == null && !_customerNameFocus.hasFocus && _customerNameController.text.isNotEmpty) {
      // Only clear if field doesn't have focus (to allow typing new names)
       _customerNameController.clear();
       _customerPhoneController.clear();
    }
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

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 900;

            return Shortcuts(
              shortcuts: {
                LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const _FocusSearchIntent(),
                LogicalKeySet(LogicalKeyboardKey.f2): const _CheckoutIntent(),
                LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.enter): const _CheckoutIntent(),
                LogicalKeySet(LogicalKeyboardKey.escape): const _ClearSearchIntent(),
                LogicalKeySet(LogicalKeyboardKey.arrowUp): const _NavUpIntent(),
                LogicalKeySet(LogicalKeyboardKey.arrowDown): const _NavDownIntent(),
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
                  _NavUpIntent: CallbackAction<_NavUpIntent>(onInvoke: (_) { _moveSelection(-1, filteredMedicines.length); return null; }),
                  _NavDownIntent: CallbackAction<_NavDownIntent>(onInvoke: (_) { _moveSelection(1, filteredMedicines.length); return null; }),
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
                  child: DefaultTabController(
                    length: 2,
                    child: Scaffold(
                      resizeToAvoidBottomInset: false, // Prevent keyboard pushing up layout weirdly on mobile
                      body: _buildBody(isMobile, filteredMedicines, medicineRepo, cart, cartNotifier),
                    ),
                  ),
                ),
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildBody(bool isMobile, List<Medicine> filteredMedicines, MedicineRepository repo, CartState cart, CartNotifier cartNotifier) {
    if (isMobile) {
      return Column(
        children: [
          _buildTopBar(isMobile),
          Expanded(
            child: Column(
              children: [
                _buildCustomerSection(isMobile),
                // Tabs for Products / Cart
                Container(
                  color: Colors.white,
                  child: TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors.primary,
                    tabs: [
                      const Tab(text: 'Products'),
                      Tab(text: 'Cart (${cart.items.fold(0, (sum, item) => sum + item.quantity)})'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Product Tab
                      Column(
                        children: [
                          _buildSearchSection(isMobile),
                          Expanded(child: _buildProductList(filteredMedicines, repo, cartNotifier)),
                        ],
                      ),
                      // Cart Tab
                      _buildCartPanel(cart, cartNotifier),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Desktop Layout (Existing Split View)
      return Column(
        children: [
          _buildTopBar(isMobile),
          _buildCustomerSection(isMobile),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 5, 
                  child: Column(
                    children: [
                      _buildSearchSection(isMobile),
                      Expanded(child: _buildProductList(filteredMedicines, repo, cartNotifier)),
                    ],
                  ),
                ),
                VerticalDivider(width: 1, color: Colors.grey.shade300),
                Expanded(
                  flex: 3, 
                  child: _buildCartPanel(cart, cartNotifier),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  // --- Widgets ---
  
  Widget _buildTopBar(bool isMobile) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
          const Icon(Icons.point_of_sale, color: Colors.white),
          const SizedBox(width: 12),
          Text(isMobile ? 'POS' : 'Point of Sale', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          
          // Action Buttons
          if (isMobile) ...[
             IconButton(
               icon: const Icon(Icons.add_circle_outline, color: Colors.white),
               tooltip: 'New Sale',
               onPressed: () {
                ref.read(cartProvider.notifier).clear();
                _amountReceivedController.clear();
                setState(() { _changeReturn = 0.0; _selectedProductIndex = 0; _searchQuery = ''; });
                _productSearchFocus.requestFocus();
               },
             ),
             PopupMenuButton<String>(
               icon: const Icon(Icons.more_vert, color: Colors.white),
               onSelected: (val) {
                 // Handle menu actions
               },
               itemBuilder: (context) => [
                 const PopupMenuItem(value: 'hold', child: Row(children: [Icon(Icons.pause_circle_outline, color: Colors.black54), SizedBox(width: 8), Text('Hold Sale')])),
                 const PopupMenuItem(value: 'resume', child: Row(children: [Icon(Icons.history, color: Colors.black54), SizedBox(width: 8), Text('Resume Sale')])),
               ]
             )
          ] else ...[
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
          ]
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 18), const SizedBox(width: 4), Text(label, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onPrimary))])
      ),
    );
  }

  Widget _buildCustomerSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardTheme.color,
      child: isMobile 
        ? Column(
           children: [
             Row(
               children: [
                 Expanded(
                   child: TextField(
                     controller: _customerNameController,
                     focusNode: _customerNameFocus,
                     decoration: InputDecoration(
                       labelText: 'Customer Name',
                       labelStyle: GoogleFonts.inter(),
                       hintText: 'Walk-in Customer',
                       prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                       filled: true, fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                       isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                     ),
                     onChanged: (val) {
                       if (val.length > 2) _searchCustomers(val);
                     },
                   ),
                 ),
                 const SizedBox(width: 8),
                 ElevatedButton(
                   onPressed: () { 
                     showDialog(context: context, builder: (_) => const CustomerEntryDialog()).then((c) { if (c != null) _selectCustomer(c as Customer); });
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Theme.of(context).colorScheme.primary,
                     foregroundColor: Theme.of(context).colorScheme.onPrimary,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     padding: const EdgeInsets.all(12),
                   ),
                   child: const Icon(Icons.add, size: 20),
                 ),
               ],
             ),
             if (_customerSearchResults.isNotEmpty) 
               Container(
                 constraints: const BoxConstraints(maxHeight: 150),
                 child: ListView.builder(
                   shrinkWrap: true,
                   itemCount: _customerSearchResults.length,
                   itemBuilder: (context, index) {
                     final c = _customerSearchResults[index];
                     return ListTile(title: Text(c.name), subtitle: Text(c.phoneNumber ?? ''), onTap: () => _selectCustomer(c), dense: true);
                   },
                 ),
               ),
           ],
        )
        : Row(
          children: [
             Expanded(
               child: TextField(
                 controller: _customerNameController,
                 focusNode: _customerNameFocus,
                 decoration: InputDecoration(
                   labelText: 'Customer Name',
                   labelStyle: GoogleFonts.inter(),
                   hintText: 'Walk-in Customer',
                   prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                   suffixIcon: const Icon(Icons.arrow_drop_down),
                   filled: true, fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                   isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                   labelText: 'Phone',
                   labelStyle: GoogleFonts.inter(),
                   hintText: 'Phone (Optional)',
                   filled: true, fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                   isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                 ),
               ),
             ),
             const SizedBox(width: 12),
             ElevatedButton.icon(
               onPressed: () { 
                 showDialog(context: context, builder: (_) => const CustomerEntryDialog()).then((c) { if (c != null) _selectCustomer(c as Customer); });
               },
               icon: const Icon(Icons.add, size: 18), 
               label: const Text('New'),
               style: ElevatedButton.styleFrom(
                 backgroundColor: Theme.of(context).colorScheme.primary,
                 foregroundColor: Theme.of(context).colorScheme.onPrimary,
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               ),
             ),
          ],
        ),
    );
  }

  Widget _buildSearchSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
      child: TextField(
        focusNode: _productSearchFocus,
        decoration: InputDecoration(
          labelText: 'Search Product',
          labelStyle: GoogleFonts.inter(),
          hintText: 'Search Product...',
          prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
           suffixIcon: _searchQuery.isNotEmpty 
             ? IconButton(icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface), onPressed: () => setState(() { _searchQuery = ''; _selectedProductIndex = 0; _productSearchFocus.requestFocus(); }))
             : null,
          filled: true, 
          fillColor: Theme.of(context).inputDecorationTheme.fillColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (val) => setState(() { _searchQuery = val; _selectedProductIndex = 0; }), 
        onSubmitted: (_) { 
             // Handled by Shortcuts
        }, 
      ),
    );
  }

  Widget _buildProductList(List<Medicine> medicines, MedicineRepository repo, CartNotifier notifier) {
        if (medicines.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text('No products found', style: TextStyle(color: Colors.grey.shade500))]));
        }

        return ListView.separated(
          controller: _productGridController,
          padding: const EdgeInsets.all(12),
          itemCount: medicines.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final isSelected = index == _selectedProductIndex;
            return _buildProductListItem(medicines[index], repo, notifier, isSelected, index, medicines);
          },
        );
  }

  Widget _buildProductListItem(Medicine medicine, MedicineRepository repo, CartNotifier notifier, bool isSelected, int index, List<Medicine> allMedicines) {
    final cart = ref.watch(cartProvider);
    final inCartQty = cart.items
        .where((i) => i.medicine.id == medicine.id)
        .fold<int>(0, (sum, item) => sum + item.quantity);
    
    return FutureBuilder<List<Batch>>(
      future: repo.getBatchesForMedicine(medicine.id),
      builder: (context, snapshot) {
        // Placeholder while loading stock
         if (!snapshot.hasData) {
           return Container(
             height: 72,
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: Colors.grey.shade200),
             ),
             child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
           );
         }
        
        final batches = snapshot.data!;
        final totalStock = batches.fold<int>(0, (sum, b) => sum + b.quantity);
        final availableStock = totalStock - inCartQty; // Real-time available stock
        final isLowStock = availableStock > 0 && availableStock < medicine.minStock;
        final isOutOfStock = availableStock <= 0;
        final hasAnyStock = totalStock > 0;
        
        // Find best batch for pricing display
        final batchesWithStock = batches.where((b) => b.quantity > 0).toList();
        final bestBatch = batchesWithStock.isNotEmpty 
            ? (batchesWithStock..sort((a,b) => a.expiryDate.compareTo(b.expiryDate))).first 
            : (batches.isNotEmpty ? batches.first : null);

        final isPack = bestBatch != null && bestBatch.packSize > 1;
        final packPrice = bestBatch != null ? bestBatch.salePrice * bestBatch.packSize : 0.0;
        final unitPrice = bestBatch?.salePrice ?? 0.0;

        // Determine stock badge color and text
        Color badgeColor;
        Color badgeBgColor;
        String badgeText;
        IconData? badgeIcon;
        
        if (isOutOfStock) {
          badgeColor = AppColors.error.shade700;
          badgeBgColor = AppColors.error.shade50;
          badgeText = 'Out of Stock';
          badgeIcon = Icons.cancel;
        } else if (isLowStock) {
          badgeColor = AppColors.warning.shade800;
          badgeBgColor = AppColors.warning.shade50;
          badgeText = '$availableStock Left';
          badgeIcon = Icons.warning_amber_rounded;
        } else {
          badgeColor = AppColors.success;
          badgeBgColor = const Color(0xFFF0FDF4);
          badgeText = '$availableStock In Stock';
          badgeIcon = Icons.check_circle_outline;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: isSelected 
              ? Border.all(color: AppColors.primary, width: 2) 
              : Border.all(color: Colors.grey.shade200),
            boxShadow: [
               BoxShadow(
                 color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.black.withOpacity(0.04), 
                 blurRadius: isSelected ? 8 : 2, 
                 offset: const Offset(0, 2)
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              // Always allow tap - warning dialog will handle low/zero stock
              onTap: batches.isNotEmpty ? () => _addProductToIndex(index, allMedicines) : null,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Icon / Image Placeholder
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: hasAnyStock ? AppColors.primary.shade50 : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        image: (medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty)
                            ? DecorationImage(
                                image: medicine.imageUrl!.startsWith('http') 
                                    ? NetworkImage(medicine.imageUrl!) 
                                    : FileImage(File(medicine.imageUrl!)) as ImageProvider,
                                fit: BoxFit.cover
                              )
                            : null,
                      ),
                      child: (medicine.imageUrl == null || medicine.imageUrl!.isEmpty)
                          ? Icon(
                              Icons.medication_liquid, 
                              color: hasAnyStock ? AppColors.primary : Colors.grey,
                              size: 24,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    
                    // Product Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicine.name, 
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 15,
                              color: hasAnyStock ? Colors.black87 : Colors.grey,
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          if (medicine.subtitle != null && medicine.subtitle!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                medicine.subtitle!,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                               Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                 decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
                                 child: Text(medicine.mainCategory ?? 'General', style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                               ),
                               const SizedBox(width: 8),
                               Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                 decoration: BoxDecoration(color: badgeBgColor, borderRadius: BorderRadius.circular(4)),
                                 child: Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                      if (badgeIcon != null) ...[Icon(badgeIcon, size: 10, color: badgeColor), const SizedBox(width: 3)],
                                      Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                   ],
                                 ),
                               ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Pricing & Cart Indicator
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (bestBatch != null) ...[
                          if (isPack) ...[
                             Text('PKR ${packPrice.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary.shade800)),
                             Text('Unit: ${unitPrice.toStringAsFixed(0)} (${bestBatch.packSize}/pk)', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ] else ...[
                             Text('PKR ${unitPrice.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary.shade800)),
                             Text('Per Unit', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ]
                        ] else 
                          const Text('N/A', style: TextStyle(color: Colors.grey)),
                          
                        if (inCartQty > 0) ...[
                           const SizedBox(height: 4),
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                             decoration: BoxDecoration(
                               color: AppColors.primary,
                               borderRadius: BorderRadius.circular(12),
                             ),
                             child: Text(
                               '$inCartQty in Cart', 
                               style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                             ),
                           ),
                        ],
                      ],
                    ),
                  ],
                ),
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
                  TextButton.icon(onPressed: () { notifier.clear(); _amountReceivedController.clear(); setState(() => _changeReturn = 0.0); }, icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error), label: const Text('Clear', style: TextStyle(color: AppColors.error))),
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
                    final hasWarning = item.hasStockWarning;
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: hasWarning ? BoxDecoration(
                        color: AppColors.warning.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.warning.shade200),
                      ) : null,
                      child: Padding(
                        padding: hasWarning ? const EdgeInsets.all(6) : EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 90,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: hasWarning ? AppColors.warning.shade300 : Colors.grey.shade300), 
                                    borderRadius: BorderRadius.circular(4), 
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                     children: [
                                       InkWell(onTap: () { if (item.quantity > 1) notifier.updateQuantity(item.batch.id, item.quantity - 1); else notifier.removeItem(item.batch.id); }, child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.remove, size: 14))),
                                       Expanded(child: Text('${item.quantity}', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: hasWarning ? AppColors.warning.shade700 : Colors.black87))),
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
                                    InkWell(onTap: () => notifier.removeItem(item.batch.id), child: const Icon(Icons.delete_outline, size: 16, color: AppColors.error)),
                                  ],
                                ),
                              ],
                            ),
                            // Stock warning indicator
                            if (hasWarning) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.warning.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Stock: ${item.originalStock} | Shortage: ${item.shortage}',
                                    style: TextStyle(fontSize: 10, color: AppColors.warning.shade700, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
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
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0,-2))],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
               // Totals Section - Compact
               Row(
                 children: [
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         _buildSummaryRow('Subtotal', cart.subTotal),
                         InkWell(
                           onTap: () => _showDiscountDialog(notifier, cart.discountValue, cart.discountType),
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               Row(children: [
                                 const Text('Discount', style: TextStyle(color: Colors.grey)),
                                 const SizedBox(width: 4),
                                 Icon(Icons.edit, size: 12, color: AppColors.primary.withOpacity(0.5)),
                               ]),
                               Text('${cart.discountType == 'percent' ? '(${cart.discountValue.toStringAsFixed(0)}%) ' : ''}-${cart.discountAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.error)),
                             ],
                           ),
                         ),
                         if (cart.taxAmount > 0)
                           _buildSummaryRow('Tax/GST', cart.taxAmount),
                         if (cart.posFeeAmount > 0)
                           _buildSummaryRow('POS Fee', cart.posFeeAmount),
                       ],
                     ),
                   ),
                   const SizedBox(width: 16),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.end,
                     children: [
                       const Text('Total', style: TextStyle(fontSize: 12, color: Colors.grey)),
                       Text('PKR ${cart.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                     ],
                   ),
                 ],
               ),
               const Divider(height: 12),
               
               // Payment Modes
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
               
               // Amount & Change
               Row(
                 children: [
                   Expanded(
                     flex: 3,
                     child: SizedBox(
                       height: 40,
                       child: TextField(
                         controller: _amountReceivedController,
                         focusNode: _amountReceivedFocus,
                         decoration: const InputDecoration(labelText: 'Amount Received', prefixText: 'PKR ', isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                         keyboardType: TextInputType.number,
                         onChanged: (_) => _calculateChange(),
                         onSubmitted: (_) => _handleCheckout(),
                         style: const TextStyle(fontWeight: FontWeight.bold),
                       ),
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     flex: 2,
                     child: Container(
                       height: 40,
                       padding: const EdgeInsets.symmetric(horizontal: 8),
                       decoration: BoxDecoration(color: _changeReturn < 0 ? AppColors.error.shade50 : AppColors.success.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: _changeReturn < 0 ? AppColors.error.shade200 : AppColors.success.shade200)),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.center,
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Text('Change', style: TextStyle(fontSize: 9, color: _changeReturn < 0 ? AppColors.error : AppColors.success.shade700)),
                           Text('${_changeReturn.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: _changeReturn < 0 ? AppColors.error : AppColors.success.shade800, fontSize: 13)),
                         ],
                       ),
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 8),
               
               // Checkout Button
               SizedBox(
                 width: double.infinity,
                 height: 44,
                 child: ElevatedButton(
                   onPressed: cart.items.isNotEmpty ? _handleCheckout : null,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppColors.primary, 
                     foregroundColor: Colors.white, 
                     elevation: 2,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                   ),
                   child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                       Icon(Icons.print, size: 18),
                       SizedBox(width: 8),
                       Text('CHECKOUT & PRINT', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                   ),
                 ),
               ),
              ],
            ),
          ),
        ),
      );
  }

  void _showDiscountDialog(CartNotifier notifier, double currentValue, String currentType) {
    final controller = TextEditingController(text: currentValue.toString());
    String selectedType = currentType; // 'percent' or 'fixed'

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Set Discount'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => selectedType = 'percent'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selectedType == 'percent' ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Percentage (%)', style: TextStyle(color: selectedType == 'percent' ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => selectedType = 'fixed'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selectedType == 'fixed' ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Fixed Amount', style: TextStyle(color: selectedType == 'fixed' ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Value', 
                    suffixText: selectedType == 'percent' ? '%' : 'PKR',
                    border: const OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final val = double.tryParse(controller.text) ?? 0;
                  notifier.setDiscount(val, type: selectedType);
                  Navigator.pop(context);
                },
                child: const Text('Set'),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis)), 
          Text('PKR ${value.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w500))
        ]
      ),
    );
  }

  Widget _buildPaymentModeBtn(String mode, IconData icon) {
    final isSelected = _paymentMode == mode;
    return InkWell(
      onTap: () => setState(() => _paymentMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: isSelected ? AppColors.primary : Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300)),
        child: Column(children: [Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey), const SizedBox(height: 4), Text(mode, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : Colors.grey.shade700))]),
      ),
    );
  }
}
