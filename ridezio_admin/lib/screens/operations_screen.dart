import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/providers.dart';
import '../models/booking.dart';
import '../services/api_service.dart';

class OperationsScreen extends ConsumerStatefulWidget {
  const OperationsScreen({super.key});

  @override
  ConsumerState<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends ConsumerState<OperationsScreen> with SingleTickerProviderStateMixin {
  final Map<String, String> _filters = const {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider(_filters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Operations', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: "Today's Pickups"),
            Tab(text: "Today's Drop-offs"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(bookingsProvider(_filters).future),
          ),
        ],
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (allBookings) {
          final now = DateTime.now();
          final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

          // Pickups: start_datetime <= today and status == 'confirmed'
          final pickups = allBookings.where((b) {
            if (b.status.toLowerCase() != 'confirmed') return false;
            final start = DateTime.parse(b.startDatetime);
            return start.isBefore(todayEnd);
          }).toList();

          // Dropoffs: end_datetime <= today and status in ['active', 'ongoing']
          final dropoffs = allBookings.where((b) {
            if (!['active', 'ongoing'].contains(b.status.toLowerCase())) return false;
            final end = DateTime.parse(b.endDatetime ?? b.startDatetime);
            return end.isBefore(todayEnd);
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(pickups, isPickup: true),
              _buildList(dropoffs, isPickup: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Booking> list, {required bool isPickup}) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          isPickup ? 'No pickups scheduled for today.' : 'No drop-offs scheduled for today.',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(bookingsProvider(_filters).future),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final booking = list[index];
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
                      Text(booking.bookingReference, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: (isPickup ? Colors.orange : Colors.blue).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                        child: Text(
                          isPickup ? 'CONFIRMED' : 'ACTIVE',
                          style: TextStyle(color: isPickup ? Colors.orange : Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(booking.customerName ?? 'Guest', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.two_wheeler, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(booking.vehicleName ?? 'Unknown Vehicle', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(isPickup ? Icons.flight_takeoff : Icons.flight_land, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM dd, hh:mm a').format(DateTime.parse(isPickup ? booking.startDatetime : (booking.endDatetime ?? booking.startDatetime))),
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => isPickup ? _showHandoverDialog(context, booking) : _showReturnDialog(context, booking),
                      icon: Icon(isPickup ? Icons.key : Icons.check_circle, size: 18),
                      label: Text(isPickup ? 'Handover Vehicle' : 'Process Return'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPickup ? Colors.black : Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showHandoverDialog(BuildContext context, Booking booking) async {
    final helmetController = TextEditingController();
    final notesController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Handover Vehicle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: helmetController,
                    decoration: const InputDecoration(labelText: 'Helmet Number (Optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Pre-ride Notes (Optional)', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setState(() => isSubmitting = true);
                        try {
                          await ref.read(apiServiceProvider).processHandover(booking.id, helmetController.text.trim().isEmpty ? null : helmetController.text.trim(), notesController.text.trim().isEmpty ? null : notesController.text.trim());
                          ref.refresh(bookingsProvider(_filters).future);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle handed over successfully.')));
                          }
                        } catch (e) {
                          setState(() => isSubmitting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child: isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Confirm', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showReturnDialog(BuildContext context, Booking booking) async {
    final damageController = TextEditingController();
    final notesController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Process Return'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: damageController,
                    decoration: const InputDecoration(labelText: 'Damage Charges (₹)', border: OutlineInputBorder(), hintText: '0'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Post-ride Notes (Optional)', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setState(() => isSubmitting = true);
                        try {
                          final dmg = num.tryParse(damageController.text.trim()) ?? 0;
                          await ref.read(apiServiceProvider).processReturn(booking.id, dmg, notesController.text.trim().isEmpty ? null : notesController.text.trim());
                          ref.refresh(bookingsProvider(_filters).future);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle returned successfully.')));
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
