import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../core/constants.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/video_player_widget.dart';
class BookingsScreen extends ConsumerStatefulWidget {
  final Map<String, String> filters;
  const BookingsScreen({super.key, this.filters = const {}});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider(widget.filters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(bookingsProvider(widget.filters).future),
        child: bookingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => ListView(
            children: [Center(child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text('Error: $err'),
            ))],
          ),
          data: (bookings) {
            if (bookings.isEmpty) {
              return ListView(children: const [Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No bookings found.'),
              ))]);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _showBookingDetails(context, booking),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(booking.customerName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              _buildStatusBadge(booking.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(booking.vehicleName ?? 'Unknown Vehicle', style: TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: 12),
                          if (booking.isExtended)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Icon(Icons.more_time, size: 16, color: Colors.blue.shade700),
                                  const SizedBox(width: 4),
                                  Text('Extended by ${booking.extendedHours}h (+₹${booking.extendedAmount.toStringAsFixed(0)})', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('Amount: ₹${booking.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 8),
                              Text(_formatDate(booking.createdAt), style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy h:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor = Colors.white;
    switch (status.toLowerCase()) {
      case 'completed':
        bgColor = AppColors.success;
        break;
      case 'pending':
        bgColor = AppColors.warning;
        break;
      case 'cancelled':
        bgColor = AppColors.danger;
        break;
      case 'active':
        bgColor = AppColors.info;
        break;
      default:
        bgColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bgColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: bgColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<Booking?> _showExtendDialog(BuildContext context, Booking booking) async {
    DateTime now = DateTime.now();
    DateTime initial = DateTime.parse(booking.endDatetime ?? now.toString());
    if (initial.isBefore(now)) {
      initial = now;
    }

    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (selectedDate == null) return null;

    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selectedTime == null) return null;

    final newEndDatetime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (newEndDatetime.isBefore(DateTime.parse(booking.endDatetime ?? DateTime.now().toString()))) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New end time must be in the future')));
      return null;
    }

    final oldEnd = DateTime.parse(booking.endDatetime ?? booking.startDatetime);
    final extraMinutes = newEndDatetime.difference(oldEnd).inMinutes;
    int extraHours = (extraMinutes / 60).ceil();
    if (extraHours <= 0) extraHours = 1;
    
    final num hourlyRate = booking.vehicle?['hourly_rate'] ?? 0;
    final extraAmount = extraHours * hourlyRate;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Extension'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Extend from: ${_formatDate(oldEnd.toString())}'),
            const SizedBox(height: 4),
            Text('Extend to: ${_formatDate(newEndDatetime.toString())}'),
            const SizedBox(height: 12),
            Text('Extra Hours: $extraHours'),
            Text('Hourly Rate: ₹$hourlyRate'),
            const Divider(),
            Text('Additional Charge: ₹${extraAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF212529)),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return null;

    try {
      final updatedBooking = await ref.read(apiServiceProvider).extendBooking(booking.id, newEndDatetime.toIso8601String());
      ref.refresh(bookingsProvider(widget.filters).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking extended successfully!')));
        return updatedBooking;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    return null;
  }

  Future<Booking?> _showPaymentDialog(BuildContext context, Booking booking) async {
    final TextEditingController amountController = TextEditingController(text: (booking.totalAmount - booking.paidAmount).toStringAsFixed(2));
    String selectedMode = 'cash';
    String? errorMessage;
    bool isLoading = false;

    return showDialog<Booking>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Verify Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pending Amount: ₹${(booking.totalAmount - booking.paidAmount).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount Received (₹)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                const Text('Payment Mode'),
                DropdownButtonFormField<String>(
                  initialValue: selectedMode,
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'upi', child: Text('UPI')),
                    DropdownMenuItem(value: 'card', child: Text('Card')),
                  ],
                  onChanged: (val) => setState(() => selectedMode = val!),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: isLoading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  setState(() {
                    errorMessage = null;
                    isLoading = true;
                  });
                  final amount = num.tryParse(amountController.text) ?? 0;
                  if (amount <= 0) {
                    setState(() {
                      errorMessage = 'Enter a valid amount';
                      isLoading = false;
                    });
                    return;
                  }
                  try {
                    final updatedBooking = await ref.read(apiServiceProvider).recordPayment(booking.id, amount, selectedMode);
                    ref.refresh(bookingsProvider(widget.filters).future);
                    if (context.mounted) {
                      Navigator.pop(context, updatedBooking);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded successfully!')));
                    }
                  } catch (e) {
                    setState(() {
                      errorMessage = 'Error: $e';
                      isLoading = false;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF212529)),
                child: isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Record Payment', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<Booking?> _showVideoUploadBottomSheet(BuildContext context, Booking booking) async {
    final ImagePicker picker = ImagePicker();
    
    final XFile? video = await showModalBottomSheet<XFile>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Record Video with Camera'),
              onTap: () async {
                final picked = await picker.pickVideo(source: ImageSource.camera);
                if (context.mounted) Navigator.pop(context, picked);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose Video from Gallery'),
              onTap: () async {
                final picked = await picker.pickVideo(source: ImageSource.gallery);
                if (context.mounted) Navigator.pop(context, picked);
              },
            ),
          ],
        ),
      ),
    );

    if (video == null) return null;

    if (!context.mounted) return null;

    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      final updatedBooking = await ref.read(apiServiceProvider).uploadReturnVideo(booking.id, video.path);
      ref.refresh(bookingsProvider(widget.filters).future);
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video uploaded successfully!')));
        return updatedBooking;
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    return null;
  }

  void _showBookingDetails(BuildContext context, Booking initialBooking) {
    Booking currentBooking = initialBooking;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (currentBooking.vehicle != null && currentBooking.vehicle!['image_url'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(currentBooking.vehicle!['image_url'], height: 200, width: double.infinity, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        height: 200,
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
                        child: const Center(child: Icon(Icons.directions_car, size: 64, color: Colors.grey)),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(currentBooking.vehicleName ?? 'Unknown Vehicle', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ),
                        _buildStatusBadge(currentBooking.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Customer: ${currentBooking.customerName}', style: const TextStyle(fontSize: 16)),
                    if (currentBooking.customer != null && currentBooking.customer!['email'] != null)
                      Text('Email: ${currentBooking.customer!['email']}', style: TextStyle(color: Colors.grey.shade600)),
                    
                    if (currentBooking.isExtended) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
                        child: Row(
                          children: [
                            Icon(Icons.more_time, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Booking Extended', style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                                  Text('Added ${currentBooking.extendedHours} hours (₹${currentBooking.extendedAmount})', style: TextStyle(color: Colors.blue.shade700, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    const Text('Booking Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Start: ${_formatDate(currentBooking.startDatetime)}'),
                    if (currentBooking.endDatetime != null) Text('End: ${_formatDate(currentBooking.endDatetime!)}'),
                    Text('Total Hours: ${currentBooking.totalHours}'),
                    const SizedBox(height: 24),
                    const Text('Pricing Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Rental Amount: ₹${currentBooking.rentalAmount.toStringAsFixed(2)}'),
                    Text('Security Deposit: ₹${currentBooking.securityDeposit.toStringAsFixed(2)}'),
                    const Divider(),
                    Text('Total Amount: ₹${currentBooking.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (currentBooking.returnVideoPath != null) ...[
                      const Divider(),
                      const Text('Return Video', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      VideoPlayerWidget(videoUrl: '${ApiConstants.baseUrl.replaceAll('/api', '')}/storage/${currentBooking.returnVideoPath}'),
                    ],
                    const SizedBox(height: 32),
                    if (currentBooking.status.toLowerCase() != 'cancelled')
                      Column(
                        children: [
                          if (currentBooking.paidAmount < currentBooking.totalAmount) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final updated = await _showPaymentDialog(context, currentBooking);
                                  if (updated != null) {
                                    setModalState(() {
                                      currentBooking = updated;
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Verify Payment', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () async {
                                final updated = await _showVideoUploadBottomSheet(context, currentBooking);
                                if (updated != null) {
                                  setModalState(() {
                                    currentBooking = updated;
                                  });
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.blue.shade700, width: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.video_camera_back, color: Colors.blue.shade700),
                                  const SizedBox(width: 8),
                                  Text(currentBooking.returnVideoPath != null ? 'Update Return Video' : 'Upload Return Video', style: TextStyle(color: Colors.blue.shade700, fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
