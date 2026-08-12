import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../core/constants.dart';
import '../models/borrow.dart';
import '../services/api_service.dart';

class BorrowPaymentsScreen extends ConsumerStatefulWidget {
  const BorrowPaymentsScreen({super.key});

  @override
  ConsumerState<BorrowPaymentsScreen> createState() => _BorrowPaymentsScreenState();
}

class _BorrowPaymentsScreenState extends ConsumerState<BorrowPaymentsScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all';

  // Fetch all borrows once, then filter locally
  final Map<String, String> _filters = const {};

  @override
  Widget build(BuildContext context) {
    // We reuse borrowsProvider, but filter for amount > 0 locally
    // Or we could create a new provider that calls the /admin/borrows/payments endpoint.
    // For now we'll just fetch all borrows and filter.
    final borrowsAsync = ref.watch(borrowsProvider(_filters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrow Payments', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(borrowsProvider(_filters).future),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search borrower/item...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _statusFilter,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'paid', child: Text('Paid')),
                      DropdownMenuItem(value: 'refunded', child: Text('Refunded')),
                    ],
                    onChanged: (val) => setState(() => _statusFilter = val!),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: borrowsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (borrows) {
                // Filter where amount > 0
                var filtered = borrows.where((b) => b.amount > 0).toList();
                
                // Search text filter
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  filtered = filtered.where((b) {
                    return b.borrowerName.toLowerCase().contains(q) ||
                           b.borrowId.toLowerCase().contains(q) ||
                           b.itemName.toLowerCase().contains(q) ||
                           (b.paymentId != null && b.paymentId!.toLowerCase().contains(q));
                  }).toList();
                }

                // Filter by payment status
                filtered = filtered.where((b) {
                  if (_statusFilter == 'all') return true;
                  return b.paymentStatus.toLowerCase() == _statusFilter;
                }).toList();

                if (filtered.isEmpty) return const Center(child: Text('No payment records found.'));

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(borrowsProvider(_filters).future),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final borrow = filtered[index];
                      return _buildPaymentCard(context, borrow);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, Borrow borrow) {
    Color statusColor = AppColors.info;
    if (borrow.paymentStatus == 'paid') statusColor = AppColors.success;
    if (borrow.paymentStatus == 'pending') statusColor = Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(borrow.paymentId ?? borrow.borrowId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    borrow.paymentStatus.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Borrower', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(borrow.borrowerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Item', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(borrow.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Amount', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('₹${borrow.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Method', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text((borrow.paymentMethod ?? 'N/A').toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            if (borrow.paymentStatus == 'pending') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showPaymentDialog(context, borrow),
                  icon: const Icon(Icons.payments, size: 18),
                  label: const Text('Collect Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showPaymentDialog(BuildContext context, Borrow borrow) async {
    String selectedMode = 'cash';
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Collect Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount to Collect: ₹${borrow.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Payment Mode'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedMode,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'upi', child: Text('UPI / GPay')),
                    DropdownMenuItem(value: 'card', child: Text('Card / POS')),
                    DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                  ],
                  onChanged: (val) => setState(() => selectedMode = val!),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setState(() => isSubmitting = true);
                        try {
                          await ref.read(apiServiceProvider).recordBorrowPayment(borrow.id, borrow.amount, selectedMode);
                          ref.refresh(borrowsProvider(_filters).future);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded!')));
                          }
                        } catch (e) {
                          setState(() => isSubmitting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Confirm', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}
