import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/providers.dart';
import '../core/constants.dart';
import '../models/borrow.dart';
import '../services/api_service.dart';
import 'borrow_create_screen.dart';

class BorrowsScreen extends ConsumerStatefulWidget {
  const BorrowsScreen({super.key});

  @override
  ConsumerState<BorrowsScreen> createState() => _BorrowsScreenState();
}

class _BorrowsScreenState extends ConsumerState<BorrowsScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all';

  // Fetch all borrows once, then filter locally to avoid Riverpod infinite rebuilds
  // due to Dart Map equality issues.
  final Map<String, String> _filters = const {};

  @override
  Widget build(BuildContext context) {
    final borrowsAsync = ref.watch(borrowsProvider(_filters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrows', style: TextStyle(color: Colors.black)),
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
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'returned', child: Text('Returned')),
                      DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
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
                // Client side filtering for status because API only searches text
                final filtered = borrows.where((b) {
                  // Search text filter
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    if (!b.borrowerName.toLowerCase().contains(q) &&
                        !b.borrowId.toLowerCase().contains(q) &&
                        !b.itemName.toLowerCase().contains(q)) {
                      return false;
                    }
                  }

                  // Status filter
                  if (_statusFilter == 'all') return true;
                  if (_statusFilter == 'overdue') {
                     if (b.status.toLowerCase() == 'returned') return false;
                     try {
                       final expected = DateTime.parse(b.expectedReturnDate);
                       return expected.isBefore(DateTime.now());
                     } catch(e) {
                       return false;
                     }
                  }
                  return b.status.toLowerCase() == _statusFilter;
                }).toList();

                if (filtered.isEmpty) return const Center(child: Text('No borrows found.'));

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(borrowsProvider(_filters).future),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final borrow = filtered[index];
                      return _buildBorrowCard(context, borrow);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BorrowCreateScreen()),
          );
          if (result == true) {
            ref.refresh(borrowsProvider(_filters).future);
          }
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBorrowCard(BuildContext context, Borrow borrow) {
    bool isOverdue = false;
    if (borrow.status.toLowerCase() != 'returned') {
      try {
        final expected = DateTime.parse(borrow.expectedReturnDate);
        if (expected.isBefore(DateTime.now())) isOverdue = true;
      } catch (_) {}
    }

    String displayStatus = isOverdue ? 'OVERDUE' : borrow.status.toUpperCase();
    Color statusColor = AppColors.info;
    if (displayStatus == 'RETURNED') statusColor = AppColors.success;
    if (displayStatus == 'OVERDUE') statusColor = AppColors.danger;

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
                Text(borrow.borrowId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    displayStatus,
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
                      Text(borrow.phoneNumber, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Item', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(borrow.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (borrow.amount > 0)
                        Text('₹${borrow.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
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
                    const Text('Borrowed', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(_formatDate(borrow.borrowDate), style: const TextStyle(fontSize: 13)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Return By', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(_formatDate(borrow.expectedReturnDate), style: TextStyle(fontSize: 13, color: isOverdue ? Colors.red : Colors.black, fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ],
            ),
            if (borrow.status.toLowerCase() != 'returned') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _markReturned(context, borrow),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Mark as Returned'),
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

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _markReturned(BuildContext context, Borrow borrow) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Returned?'),
        content: Text('Are you sure you want to mark ${borrow.itemName} as returned?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    
    // Show loading
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    try {
      await ref.read(apiServiceProvider).updateBorrowStatus(borrow.id, 'returned');
      ref.refresh(borrowsProvider(_filters).future);
      if (mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item marked as returned!')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
