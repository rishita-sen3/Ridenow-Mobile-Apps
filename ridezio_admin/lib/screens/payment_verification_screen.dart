import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/providers.dart';
import '../core/constants.dart';
import '../models/booking.dart';
import '../services/api_service.dart';

class PaymentVerificationScreen extends ConsumerStatefulWidget {
  const PaymentVerificationScreen({super.key});

  @override
  ConsumerState<PaymentVerificationScreen> createState() => _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState extends ConsumerState<PaymentVerificationScreen> with SingleTickerProviderStateMixin {
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
    final bookingsAsync = ref.watch(bookingsProvider(const {}));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Verification', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (bookings) {
          final pending = bookings.where((b) => b.paidAmount < b.totalAmount && b.status.toLowerCase() != 'cancelled').toList();
          final completed = bookings.where((b) => b.paidAmount >= b.totalAmount && b.status.toLowerCase() != 'cancelled').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(pending, isPending: true),
              _buildList(completed, isPending: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Booking> bookings, {required bool isPending}) {
    if (bookings.isEmpty) {
      return const Center(child: Text('No bookings found.'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(bookingsProvider(const {}).future),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(booking.customerName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isPending ? AppColors.warning : AppColors.success).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: (isPending ? AppColors.warning : AppColors.success).withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          isPending ? 'PENDING' : 'COMPLETED',
                          style: TextStyle(color: isPending ? AppColors.warning : AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(booking.vehicleName ?? 'Unknown Vehicle', style: TextStyle(color: AppColors.textSecondary)),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Amount:', style: TextStyle(color: AppColors.textSecondary)),
                      Text('₹${booking.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (!isPending) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Paid Amount:', style: TextStyle(color: AppColors.textSecondary)),
                        Text('₹${booking.paidAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Payment Mode:', style: TextStyle(color: AppColors.textSecondary)),
                        Text(booking.paymentStatus.toUpperCase() ?? 'COMPLETED'),
                      ],
                    ),
                  ],
                  if (isPending) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pending Amount:', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        Text('₹${(booking.totalAmount - booking.paidAmount).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showPaymentDialog(context, booking),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Verify Payment', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showPaymentDialog(BuildContext context, Booking booking) async {
    final TextEditingController amountController = TextEditingController(text: (booking.totalAmount - booking.paidAmount).toStringAsFixed(2));
    String selectedMode = 'cash';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Verify Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter amount paid by customer:'),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Payment Mode:'),
                DropdownButton<String>(
                  value: selectedMode,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'upi', child: Text('UPI')),
                    DropdownMenuItem(value: 'card', child: Text('Card / POS')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => selectedMode = val);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, false);
                      _generateAndShowQRCode(context, booking, amountController.text);
                    },
                    icon: const Icon(Icons.qr_code, color: Colors.white),
                    label: const Text('Generate Payment QR', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                child: const Text('Save Manual', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );

    if (confirm != true) return;

    final amount = double.tryParse(amountController.text) ?? 0;
    if (amount <= 0) return;

    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      await ref.read(apiServiceProvider).recordPayment(booking.id, amount, selectedMode);
      ref.refresh(bookingsProvider(const {}).future);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment verified successfully!')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _generateAndShowQRCode(BuildContext context, Booking booking, String amountStr) async {
    final amount = double.tryParse(amountStr) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amount must be greater than 0')));
      return;
    }

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    try {
      final res = await ref.read(apiServiceProvider).generatePaymentLink(booking.id);
      if (mounted) Navigator.pop(context); // close loader

      if (res['status'] == 'success') {
        final paymentUrl = res['payment_url'];
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Scan to Pay ₹$amount', textAlign: TextAlign.center),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: QrImageView(
                        data: paymentUrl,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Ask the customer to scan this QR with any UPI app.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(paymentUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link directly.')));
                        }
                      },
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Open Payment Link'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                          final verifyRes = await ref.read(apiServiceProvider).checkPaymentStatus(booking.id);
                          if (context.mounted) Navigator.pop(context); // close loader
                          
                          if (verifyRes['status'] == 'completed') {
                            if (context.mounted) {
                              Navigator.pop(context); // close QR dialog
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment completed successfully!'), backgroundColor: Colors.green));
                              ref.refresh(bookingsProvider(const {}).future);
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment not completed yet. Please wait.')));
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context); // close loader if failed
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text('Check Payment Status', style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                ],
              );
            }
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to generate QR')));
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          duration: const Duration(seconds: 4),
        ));
      }
    }
  }
}
