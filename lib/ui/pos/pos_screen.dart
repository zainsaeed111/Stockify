import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../data/database/database.dart';
import 'cart_provider.dart';
import 'checkout_dialog.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final medicineRepo = ref.watch(medicineRepositoryProvider);
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('POS - New Sale')),
      body: Row(
        children: [
          // Left Side: Medicine List
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search Medicine...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Medicine>>(
                    stream: medicineRepo.watchAllMedicines(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      
                      var medicines = snapshot.data!;
                      if (_searchQuery.isNotEmpty) {
                        medicines = medicines.where((m) => 
                          m.name.toLowerCase().contains(_searchQuery.toLowerCase())
                        ).toList();
                      }

                      return ListView.builder(
                        itemCount: medicines.length,
                        itemBuilder: (context, index) {
                          final medicine = medicines[index];
                          return ExpansionTile(
                            title: Text(medicine.name),
                            subtitle: Text('Stock: ${medicine.minStock} (Min)'), // Should show actual total stock
                            children: [
                              // Show Batches
                              FutureBuilder<List<Batch>>(
                                future: medicineRepo.getBatchesForMedicine(medicine.id),
                                builder: (context, batchSnapshot) {
                                  if (!batchSnapshot.hasData) return const LinearProgressIndicator();
                                  final batches = batchSnapshot.data!;
                                  return Column(
                                    children: batches.map((batch) => ListTile(
                                      title: Text('Batch: ${batch.batchNumber}'),
                                      subtitle: Text('Exp: ${batch.expiryDate.toString().split(' ')[0]} | Qty: ${batch.quantity}'),
                                      trailing: ElevatedButton(
                                        onPressed: batch.quantity > 0 ? () {
                                          cartNotifier.addItem(medicine, batch);
                                        } : null,
                                        child: Text('PKR ${batch.salePrice}'),
                                      ),
                                    )).toList(),
                                  );
                                },
                              )
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Right Side: Cart
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.teal.withOpacity(0.1),
                  child: const Text('Current Bill', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return ListTile(
                        title: Text(item.medicine.name),
                        subtitle: Text('${item.quantity} x PKR ${item.batch.salePrice}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('PKR ${item.total.toStringAsFixed(2)}'),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => cartNotifier.removeItem(item.batch.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Subtotal:'),
                        Text('PKR ${cart.subTotal.toStringAsFixed(2)}'),
                      ]),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Discount:'),
                        Text('PKR ${cart.discount.toStringAsFixed(2)}'),
                      ]),
                      const Divider(),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('PKR ${cart.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                      ]),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: cart.items.isEmpty ? null : () {
                            showDialog(
                              context: context,
                              builder: (context) => const CheckoutDialog(),
                            );
                          },
                          child: const Text('CHECKOUT'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
