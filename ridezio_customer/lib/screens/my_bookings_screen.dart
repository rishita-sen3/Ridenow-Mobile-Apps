import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/providers.dart';
import '../core/api_client.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../widgets/cancel_ride_bottom_sheet.dart';
import '../widgets/extend_ride_bottom_sheet.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  final NumberFormat _currencyFormatter = NumberFormat('#,##,000.00');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(bookingsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('My Bookings', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Text('You have no bookings yet.', style: GoogleFonts.inter(fontSize: 16)),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(bookingsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return _buildBookingCard(booking, context);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, BuildContext context) {
    final vehicle = booking['vehicle'];
    final status = booking['status'].toString().toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showBookingDetails(context, booking),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Reference & Status)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${booking['booking_reference'] ?? 'BK-XXXX'}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade600),
                      ),
                      Row(
                        children: [
                          // Extended badge - shown when booking has been extended
                          if (booking['is_extended'] == true || booking['is_extended'] == 1)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.cyan.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.cyan.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.update, size: 10, color: Colors.cyan.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    'EXTENDED',
                                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.cyan.shade700),
                                  ),
                                ],
                              ),
                            ),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(status)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Divider
                Container(height: 1, color: Colors.grey.shade100),

                // Vehicle Details
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          image: vehicle != null && vehicle['image_url'] != null
                              ? DecorationImage(image: NetworkImage(vehicle['image_url']), fit: BoxFit.cover)
                              : null,
                        ),
                        child: vehicle == null || vehicle['image_url'] == null ? const Icon(Icons.directions_car, color: Colors.grey) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle != null ? '${vehicle['brand']} ${vehicle['model']}' : 'Unknown Vehicle',
                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              vehicle?['shop']?['name'] ?? 'Ridezio Partner',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Booking Timings
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text('Pickup:', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                            const Spacer(),
                            Text(_formatDateStr(booking['start_datetime']), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.event_available, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text('Return:', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                            const Spacer(),
                            Text(_formatDateStr(booking['end_datetime']), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Financials & Actions
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Paid', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                          Text('₹${_currencyFormatter.format(double.tryParse(booking['total_amount']?.toString() ?? '0') ?? 0)}', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                      Row(
                        children: [
                          if (status == 'pending' || status == 'confirmed')
                            ElevatedButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => CancelRideBottomSheet(booking: booking),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                foregroundColor: Colors.red.shade700,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          if (status == 'pending' || status == 'confirmed')
                            const SizedBox(width: 8),

                          if (status != 'cancelled')
                            ElevatedButton(
                              onPressed: () async {
                                // Prevent double-tap opening multiple sheets
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.white,
                                  barrierColor: Colors.black54,
                                  useSafeArea: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                  ),
                                  builder: (ctx) => ExtendRideBottomSheet(booking: booking),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade50,
                                foregroundColor: Colors.blue.shade700,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              child: Text('Extend', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            
                          if (status != 'cancelled')
                            const SizedBox(width: 8),

                          if (status == 'active' || status == 'awaiting_return')
                            ElevatedButton(
                              onPressed: () {
                                // Navigate to Contact Shop screen or trigger call/email
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact shop feature coming soon.')));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple.shade50,
                                foregroundColor: Colors.purple.shade700,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              child: Text('Contact Shop', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            
                          if (status == 'completed')
                            booking['review'] != null
                              ? ElevatedButton(
                                  onPressed: null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade50,
                                    foregroundColor: Colors.orange.shade700,
                                    disabledBackgroundColor: Colors.orange.shade50,
                                    disabledForegroundColor: Colors.orange.shade700,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star, size: 14),
                                      const SizedBox(width: 4),
                                      Text('Rated ${booking['review']['rating']}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: () => _showReviewModal(context, booking),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade50,
                                    foregroundColor: Colors.green.shade700,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star_outline, size: 14),
                                      const SizedBox(width: 4),
                                      Text('Leave Review', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                ),
                            if (status == 'completed')
                              const SizedBox(width: 8),
                            if (status == 'completed')
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    final response = await ApiClient.get('/user/invoices/${booking['id']}/download-url');
                                    if (response['url'] != null) {
                                      final Uri url = Uri.parse(response['url']);
                                      if (await url_launcher.canLaunchUrl(url)) {
                                        await url_launcher.launchUrl(url, mode: url_launcher.LaunchMode.externalApplication);
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the invoice file.')));
                                        }
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to download invoice.')));
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade50,
                                  foregroundColor: Colors.blue.shade700,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.download_rounded, size: 14),
                                    const SizedBox(width: 4),
                                    Text('Invoice', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
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
      ),
    );
  }

  // Helper method removed (cancelBooking is now inside BottomSheet)

  void _showSuccessDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                child: Text('OK', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDetails(BuildContext context, Map<String, dynamic> booking) {
    final vehicle = booking['vehicle'];
    final shop = vehicle != null ? vehicle['shop'] : null;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Booking Details #${booking['booking_reference']}',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  Text('Vehicle Information', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailRow('Vehicle:', vehicle != null ? '${vehicle['brand']} ${vehicle['model']}' : 'N/A'),
                        const SizedBox(height: 8),
                        _detailRow('Shop:', shop != null ? shop['name'] : 'N/A'),
                        const SizedBox(height: 8),
                        _detailRow('Registration:', vehicle != null ? (vehicle['registration_number'] ?? 'N/A') : 'N/A'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Schedule', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailRow('Pickup:', _formatDateDetailed(booking['start_datetime'])),
                        const SizedBox(height: 8),
                        _detailRow('Return:', _formatDateDetailed(booking['end_datetime'])),
                        const SizedBox(height: 8),
                        _detailRow('Duration:', '${booking['total_hours']} hours'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Payment Summary', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Rental Amount', style: GoogleFonts.inter(fontSize: 13, color: Colors.black87)),
                            Text('₹${_currencyFormatter.format(double.tryParse(booking['rental_amount']?.toString() ?? '0') ?? 0)}', style: GoogleFonts.inter(fontSize: 13, color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Security Deposit', style: GoogleFonts.inter(fontSize: 13, color: Colors.black87)),
                            Text('₹${_currencyFormatter.format(double.tryParse(booking['security_deposit']?.toString() ?? '0') ?? 0)}', style: GoogleFonts.inter(fontSize: 13, color: Colors.black87)),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Paid', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                            Text('₹${_currencyFormatter.format(double.tryParse(booking['total_amount']?.toString() ?? '0') ?? 0)}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Payment Mode: N/A', style: GoogleFonts.inter(fontSize: 11, color: Colors.black54)),
                            Row(
                              children: [
                                Text('Status: ', style: GoogleFonts.inter(fontSize: 11, color: Colors.black54)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                                  child: Text(booking['status'].toString(), style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close', style: GoogleFonts.inter(color: Colors.black54)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                        child: Text('Need Help?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
        ),
      ],
    );
  }

  void _showReviewModal(BuildContext context, Map<String, dynamic> booking) {
    int rating = 5;
    String comment = '';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Leave a Review', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                    Text('Rating', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: rating,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 5, child: Text('5 - Excellent')),
                            DropdownMenuItem(value: 4, child: Text('4 - Very Good')),
                            DropdownMenuItem(value: 3, child: Text('3 - Average')),
                            DropdownMenuItem(value: 2, child: Text('2 - Poor')),
                            DropdownMenuItem(value: 1, child: Text('1 - Terrible')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => rating = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Comment (Optional)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'How was your experience?',
                        hintStyle: GoogleFonts.inter(color: Colors.black38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      onChanged: (val) => comment = val,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: GoogleFonts.inter(color: Colors.black54)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  setState(() => isLoading = true);
                                  try {
                                    await ApiClient.post('/user/reviews', {
                                      'vehicle_id': booking['vehicle_id'],
                                      'booking_id': booking['id'],
                                      'rating': rating,
                                      'comment': comment,
                                    });
                                    
                                    Navigator.pop(context); // Close modal
                                    _showSuccessDialog(context, 'Review Submitted!', 'Thank you for your feedback! Your review has been saved successfully.');
                                    ref.refresh(bookingsProvider);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit review: $e')));
                                  } finally {
                                    if (mounted) setState(() => isLoading = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                          child: isLoading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text('Submit Review', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDateStr(dynamic dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString.toString();
    }
  }

  String _formatDateDetailed(dynamic dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString.toString());
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return dateString.toString();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.blue;
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.teal;
      case 'awaiting_return':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}
