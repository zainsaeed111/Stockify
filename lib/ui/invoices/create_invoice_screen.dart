import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/repositories/patient_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/database/database.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  Patient? _selectedPatient;
  final List<InvoiceItemsCompanion> _items = [];
  double _total = 0.0;

  // Temporary simple service addition
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _serviceCostController = TextEditingController();

  void _calculateTotal() {
    _total = _items.fold(0.0, (sum, item) => sum + (item.cost.value * item.quantity.value));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final patientRepo = ref.watch(patientRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Invoice'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Patient Selector
            FutureBuilder<List<Patient>>(
              future: patientRepo.getAllPatients(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                return DropdownButtonFormField<Patient>(
                  decoration: const InputDecoration(labelText: 'Select Patient'),
                  value: _selectedPatient,
                  items: snapshot.data!.map((p) {
                    return DropdownMenuItem(value: p, child: Text(p.name));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedPatient = value),
                );
              },
            ),
            const SizedBox(height: 20),
            
            // Add Item Section
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _serviceNameController,
                    decoration: const InputDecoration(labelText: 'Service Name'),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _serviceCostController,
                    decoration: const InputDecoration(labelText: 'Cost'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () {
                    if (_serviceNameController.text.isNotEmpty && _serviceCostController.text.isNotEmpty) {
                      final cost = double.tryParse(_serviceCostController.text) ?? 0.0;
                      // For simplicity, we are creating a new service entry implicitly or just storing it
                      // Ideally we select from existing services. 
                      // Here we will assume we create a service on the fly or just link it.
                      // To keep it simple and robust, let's just add to the list.
                      // We need a valid serviceId. So we should probably insert the service first or have a "Custom Service" placeholder.
                      // Let's insert the service immediately for now to get an ID.
                      
                      final serviceRepo = ref.read(invoiceRepositoryProvider);
                      serviceRepo.addService(ServicesCompanion(
                        name: drift.Value(_serviceNameController.text),
                        cost: drift.Value(cost),
                      )).then((id) {
                         setState(() {
                          _items.add(InvoiceItemsCompanion(
                            serviceId: drift.Value(id),
                            cost: drift.Value(cost),
                            quantity: const drift.Value(1),
                          ));
                          _calculateTotal();
                          _serviceNameController.clear();
                          _serviceCostController.clear();
                        });
                      });
                    }
                  },
                ),
              ],
            ),
            const Divider(),
            
            // Items List
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  // We need to fetch service name, but for now just show cost. 
                  // In a real app we would have the service object.
                  return ListTile(
                    title: Text('Service ID: ${item.serviceId.value}'), // Placeholder for name
                    trailing: Text('\$${item.cost.value.toStringAsFixed(2)}'),
                    leading: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        setState(() {
                          _items.removeAt(index);
                          _calculateTotal();
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            
            const Divider(),
            Text('Total: \$${_total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedPatient == null || _items.isEmpty ? null : () async {
                  final invoiceRepo = ref.read(invoiceRepositoryProvider);
                  final invoice = InvoicesCompanion(
                    patientId: drift.Value(_selectedPatient!.id),
                    date: drift.Value(DateTime.now()),
                    totalAmount: drift.Value(_total),
                    status: const drift.Value('Pending'),
                  );
                  
                  await invoiceRepo.createInvoice(invoice, _items);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Create Invoice'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
