import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../services/api_service.dart';
import '../../models/customer.dart';
import '../../widgets/main_drawer.dart';
import 'add_customer_screen.dart';
import 'edit_customer_screen.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  final Map<String, String> filters;
  const CustomersScreen({super.key, this.filters = const {}});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider(widget.filters));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF6F6F6),
      drawer: const MainDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'Manage Users',
          style: GoogleFonts.inter(
            color: const Color(0xFF212529),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(customersProvider(widget.filters).future),
        child: customersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('Error: $err'),
              )
            ],
          ),
          data: (customers) {
            final filteredCustomers = _searchQuery.isEmpty
                ? customers
                : customers.where((c) {
                    final q = _searchQuery.toLowerCase();
                    return c.firstName.toLowerCase().contains(q) ||
                        (c.lastName?.toLowerCase().contains(q) ?? false) ||
                        c.email.toLowerCase().contains(q) ||
                        (c.phone?.toLowerCase().contains(q) ?? false);
                  }).toList();

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildCustomersTable(filteredCustomers),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'All Customers',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF212529),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
            );
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Customer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF212529),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomersTable(List<Customer> customers) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          const Divider(height: 1),
          if (customers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'No customers found.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6c757d),
                ),
                dataTextStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF212529),
                ),
                columns: const [
                  DataColumn(label: Text('NAME')),
                  DataColumn(label: Text('EMAIL')),
                  DataColumn(label: Text('PHONE')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('JOINED')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: customers.map((customer) {
                  return DataRow(
                    cells: [
                      DataCell(Text('${customer.firstName} ${customer.lastName ?? ''}'.trim(), style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(customer.email)),
                      DataCell(Text(customer.phone ?? 'N/A')),
                      DataCell(_buildStatusBadge(customer.isActive)),
                      DataCell(Text(_formatDate(customer.createdAt))),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => EditCustomerScreen(customer: customer)),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Customer'),
                                    content: Text('Are you sure you want to delete ${customer.firstName}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          try {
                                            await ref.read(apiServiceProvider).deleteCustomer(customer.id);
                                            ref.refresh(customersProvider(widget.filters).future);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Customer deleted successfully')),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error: $e')),
                                            );
                                          }
                                        },
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: GoogleFonts.inter(
          color: isActive ? Colors.green : Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(String dtString) {
    if (dtString.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dtString).toLocal();
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (e) {
      return dtString;
    }
  }
}
