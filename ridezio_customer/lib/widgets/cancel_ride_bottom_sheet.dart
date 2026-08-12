import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../screens/booking_success_screen.dart';
import '../core/providers.dart';

class CancelRideBottomSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> booking;
  
  const CancelRideBottomSheet({super.key, required this.booking});

  @override
  ConsumerState<CancelRideBottomSheet> createState() => _CancelRideBottomSheetState();
}

class _CancelRideBottomSheetState extends ConsumerState<CancelRideBottomSheet> {
  final NumberFormat _currencyFormatter = NumberFormat('#,##,000');
  bool _isLoading = true;
  bool _isCancelling = false;
  Map<String, dynamic>? _policyData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPolicy();
  }

  Future<void> _fetchPolicy() async {
    try {
      final response = await ApiClient.get('/user/bookings/${widget.booking['id']}/cancel-preview');
      if (response['status'] == 'success') {
        setState(() {
          _policyData = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load policy.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmCancel() async {
    setState(() => _isCancelling = true);
    try {
      final response = await ApiClient.post('/user/bookings/${widget.booking['id']}/cancel', {});
      if (response['status'] == 'success') {
        Navigator.pop(context);
        ref.refresh(bookingsProvider);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingSuccessScreen(
              title: 'Ride Cancelled',
              message: 'Your ride has been cancelled successfully.',
              details: [
                {'label': 'Cancellation Charges', 'value': '-₹${_currencyFormatter.format(_policyData!['deduction_amount'])}', 'isError': true},
                {'label': 'Refund Amount', 'value': '₹${_currencyFormatter.format(_policyData!['refund_amount'])}', 'isSuccess': true},
                {'label': 'Refund Status', 'value': 'Initiated', 'isStatus': true},
              ],
              footerText: 'You will receive the refund in 2-5 business days.',
            ),
          ),
        );
      } else {
        setState(() => _isCancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Cancellation failed')));
      }
    } catch (e) {
      setState(() => _isCancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cancel Ride', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
          else if (_error != null)
            Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          else if (_policyData != null)
            _buildPolicyDetails(),
        ],
      ),
    );
  }

  Widget _buildPolicyDetails() {
    final rideStart = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(_policyData!['ride_start']));
    final currentTime = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(_policyData!['current_time']));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimeRow('Ride Start Date & Time', rideStart, Icons.calendar_today),
        const SizedBox(height: 12),
        _buildTimeRow('Current Date & Time', currentTime, Icons.access_time),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
          child: Row(
            children: [
              const Icon(Icons.hourglass_bottom, color: Colors.orange),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Remaining Time', style: GoogleFonts.inter(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.w600)),
                  Text(_policyData!['remaining_time_text'], style: GoogleFonts.inter(fontSize: 14, color: Colors.orange.shade900, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildFinancialRow('Security Deposit', '₹${_currencyFormatter.format(_policyData!['security_deposit'])}'),
        const SizedBox(height: 8),
        _buildFinancialRow('Cancellation Charges (${_policyData!['deduction_percentage']}%)', '-₹${_currencyFormatter.format(_policyData!['deduction_amount'])}', isDeduction: true),
        const Divider(height: 24),
        _buildFinancialRow('Refund Amount', '₹${_currencyFormatter.format(_policyData!['refund_amount'])}', isHighlight: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('You will receive ₹${_currencyFormatter.format(_policyData!['refund_amount'])} back.', style: GoogleFonts.inter(fontSize: 12, color: Colors.green.shade800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
          child: Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('₹${_currencyFormatter.format(_policyData!['deduction_amount'])} will be deducted as cancellation charges.', style: GoogleFonts.inter(fontSize: 12, color: Colors.red.shade800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Keep Booking', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isCancelling ? null : _confirmCancel,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isCancelling
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Confirm Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeRow(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(value, style: GoogleFonts.inter(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialRow(String label, String value, {bool isDeduction = false, bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: isHighlight ? 16 : 14, fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500, color: Colors.black87)),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isHighlight ? 18 : 14,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? Colors.green.shade600 : (isDeduction ? Colors.red : Colors.black87),
          ),
        ),
      ],
    );
  }
}
