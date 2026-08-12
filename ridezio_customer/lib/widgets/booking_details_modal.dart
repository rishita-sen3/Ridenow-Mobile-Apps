import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'cancel_ride_bottom_sheet.dart' as cancel_sheet;
import 'extend_ride_bottom_sheet.dart' as extend_sheet;

class BookingDetailsModal {
  static final _currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '');

  static String _formatDateDetailed(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  static Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  static void show(BuildContext context, Map<String, dynamic> booking) {
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
                            Text('₹${_currencyFormatter.format(booking['rental_amount'] ?? 0)}', style: GoogleFonts.inter(fontSize: 13, color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Security Deposit', style: GoogleFonts.inter(fontSize: 13, color: Colors.black87)),
                            Text('₹${_currencyFormatter.format(booking['security_deposit'] ?? 0)}', style: GoogleFonts.inter(fontSize: 13, color: Colors.black87)),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Paid', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                            Text('₹${_currencyFormatter.format(booking['total_amount'] ?? 0)}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
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
                       if (booking['status'] == 'pending' || booking['status'] == 'confirmed' || booking['status'] == 'active') ...[
                         ElevatedButton(
                           onPressed: () {
                             Navigator.pop(context);
                             showModalBottomSheet(
                               context: context,
                               isScrollControlled: true,
                               backgroundColor: Colors.transparent,
                               builder: (context) => cancel_sheet.CancelRideBottomSheet(booking: booking),
                             );
                           },
                           style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red.shade700, elevation: 0),
                           child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                         ),
                         const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              // Close this modal first, then wait for animation to finish
                              Navigator.of(context, rootNavigator: true).pop();
                              await Future.delayed(const Duration(milliseconds: 350));
                              if (!context.mounted) return;
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
                                barrierColor: Colors.black54,
                                useSafeArea: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                ),
                                builder: (ctx) => extend_sheet.ExtendRideBottomSheet(booking: booking),
                              );
                            },
                           style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50, foregroundColor: Colors.blue.shade700, elevation: 0),
                           child: Text('Extend', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                         ),
                       ],
                       const Spacer(),
                       ElevatedButton(
                         onPressed: () {},
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                         child: Text('Help', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
}
