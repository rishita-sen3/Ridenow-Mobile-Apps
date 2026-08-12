import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/providers.dart';
import '../core/constants.dart';
import '../models/booking.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  // Empty filters means fetch all bookings
  final Map<String, String> _filters = const {};

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider(_filters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
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
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(child: Text('No transactions found.'));
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(bookingsProvider(_filters).future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final trx = bookings[index];
                return _buildTransactionCard(context, trx);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, Booking trx) {
    Color statusColor = AppColors.info;
    if (['completed', 'confirmed'].contains(trx.status.toLowerCase())) statusColor = AppColors.success;
    if (['cancelled', 'failed'].contains(trx.status.toLowerCase())) statusColor = AppColors.danger;
    
    final vehicleImageUrl = trx.vehicle != null ? trx.vehicle!['image_url'] ?? trx.vehicle!['image'] : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showTransactionDetails(context, trx, statusColor),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: vehicleImageUrl != null
                            ? Image.network(vehicleImageUrl, width: 40, height: 40, fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(width: 40, height: 40, color: Colors.grey.shade200, child: const Icon(Icons.two_wheeler, color: Colors.grey)))
                            : Container(width: 40, height: 40, color: Colors.grey.shade200, child: const Icon(Icons.two_wheeler, color: Colors.grey)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trx.vehicleName ?? 'Unknown Vehicle', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (trx.vehicle != null) Text(trx.vehicle!['registration_number'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  Text('₹${trx.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.grey.shade200,
                          child: const Icon(Icons.person, size: 16, color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Customer', style: TextStyle(color: Colors.grey, fontSize: 10)),
                              Text(trx.customerName ?? 'Guest', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Date', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        Text(DateFormat('MMM dd, yyyy').format(DateTime.parse(trx.createdAt)), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          trx.status.toUpperCase(),
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (trx.isExtended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                          child: const Text('EXTENDED', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ]
                    ],
                  ),
                  const Text('Tap for details', style: TextStyle(color: Colors.blue, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, Booking trx, Color statusColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Transaction Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildDetailRow('Reference', trx.bookingReference),
              _buildDetailRow('Customer', trx.customerName ?? 'Guest'),
              _buildDetailRow('Vehicle', trx.vehicleName ?? 'N/A'),
              _buildDetailRow('Duration', '${DateFormat('MMM dd, hh:mm a').format(DateTime.parse(trx.startDatetime))} to ${trx.endDatetime != null ? DateFormat('MMM dd, hh:mm a').format(DateTime.parse(trx.endDatetime!)) : 'N/A'}'),
              _buildDetailRow('Date', DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.parse(trx.createdAt))),
              _buildDetailRow('Status', trx.status.toUpperCase(), isStatus: true, color: statusColor),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Rental Amount', style: TextStyle(color: Colors.grey)),
                        Text('₹${trx.rentalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Security Deposit', style: TextStyle(color: Colors.grey)),
                        Text('₹${trx.securityDeposit.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (trx.isExtended) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Extension Charges', style: TextStyle(color: Colors.orange)),
                          Text('+ ₹${trx.extendedAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('', style: TextStyle(color: Colors.grey)),
                          Text('(${trx.extendedHours} Extra Hours)', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('₹${trx.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Close', style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color!.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            )
          else
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
