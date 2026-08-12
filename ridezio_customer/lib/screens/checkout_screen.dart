import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> vehicle;
  final int shopId;
  final String shopName;
  final DateTime startDateTime;
  final DateTime endDateTime;

  const CheckoutScreen({
    super.key,
    required this.vehicle,
    required this.shopId,
    required this.shopName,
    required this.startDateTime,
    required this.endDateTime,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isLoading = false;
  
  final TextEditingController _couponController = TextEditingController();
  bool _isApplyingCoupon = false;
  double _discountAmount = 0.0;
  String? _appliedCouponCode;
  String? _couponMessage;
  bool _isCouponValid = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  int get _rentalHours {
    final diff = widget.endDateTime.difference(widget.startDateTime).inHours;
    return diff < 1 ? 1 : diff; // Minimum 1 hour
  }

  double get _rentalAmount {
    final rate = double.tryParse(widget.vehicle['hourly_rate']?.toString() ?? '0') ?? 0.0;
    return _rentalHours * rate;
  }

  double get _securityDeposit => 1000.0;

  double get _totalAmount {
    double total = _rentalAmount - _discountAmount;
    if (total < 0) total = 0;
    return total + _securityDeposit;
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    
    setState(() {
      _isApplyingCoupon = true;
      _couponMessage = null;
    });

    try {
      final response = await ApiClient.post('/user/verify-coupon', {
        'coupon_code': code,
        'amount': _rentalAmount,
      });

      if (response['status'] == 'success') {
        setState(() {
          _isCouponValid = true;
          _appliedCouponCode = code;
          _discountAmount = double.tryParse(response['discount']?.toString() ?? '0') ?? 0.0;
          _couponMessage = response['message'];
        });
      } else {
        setState(() {
          _isCouponValid = false;
          _appliedCouponCode = null;
          _discountAmount = 0.0;
          _couponMessage = response['message'] ?? 'Invalid coupon';
        });
      }
    } catch (e) {
      setState(() {
        _isCouponValid = false;
        _appliedCouponCode = null;
        _discountAmount = 0.0;
        _couponMessage = 'Error verifying coupon';
      });
    } finally {
      setState(() => _isApplyingCoupon = false);
    }
  }

  void _showSuccessDialog(String bookingRef) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Text(
          'Booking Confirmed!\n\nReference: $bookingRef',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context).popUntil((route) => route.isFirst); // Go to Home
            },
            child: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }

  void _showPaymentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Payment Method', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              onTap: () {
                Navigator.pop(ctx);
                _confirmBooking(true);
              },
              leading: const Icon(Icons.qr_code_scanner, color: Colors.blue, size: 30),
              title: Text('Pay Online (QR Code)', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: Text('Pay at shop upon pickup', style: GoogleFonts.inter(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
            const Divider(),
            ListTile(
              onTap: () {
                Navigator.pop(ctx);
                _confirmBooking(false);
              },
              leading: const Icon(Icons.money, color: Colors.green, size: 30),
              title: Text('Pay at Shop', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: Text('Pay when you pickup the vehicle', style: GoogleFonts.inter(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmBooking(bool isOnlinePayment) async {
    setState(() => _isLoading = true);
    try {
      final requestData = {
        'vehicle_id': widget.vehicle['id'],
        'start_datetime': widget.startDateTime.toIso8601String(),
        'end_datetime': widget.endDateTime.toIso8601String(),
      };
      
      if (_isCouponValid && _appliedCouponCode != null) {
        requestData['coupon_code'] = _appliedCouponCode!;
      }

      final response = await ApiClient.post('/bookings', requestData);

      if (response['status'] == 'success') {
        final bookingId = response['data']['id'];
        final bookingRef = response['data']['booking_reference'];

        if (isOnlinePayment) {
          // Step 2: Generate Payment Link
          try {
            final paymentRes = await ApiClient.post('/payment/create', {'booking_id': bookingId});

            if (paymentRes['status'] == 'success' && paymentRes['payment_url'] != null) {
              final paymentUrl = paymentRes['payment_url'];
              
              if (mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => AlertDialog(
                    title: const Icon(Icons.payment, color: Colors.blue, size: 60),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Redirecting to Payment', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text('Please complete your payment in the browser window that opens. Do not press back until payment is done.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14)),
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          // Manual Check Status
                          final statusRes = await ApiClient.post('/payment/status', {'booking_id': bookingId});
                          if (statusRes['status'] == 'completed') {
                            Navigator.of(ctx).pop();
                            _showSuccessDialog(bookingRef);
                          } else {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Payment not completed yet. Please complete it or wait.')));
                          }
                        },
                        child: const Text('I have Paid'),
                      ),
                    ],
                  ),
                );

                // Open URL
                final Uri url = Uri.parse(paymentUrl);
                try {
                  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                    throw Exception('Could not launch $url');
                  }
                } catch (e) {
                  debugPrint(e.toString());
                }
              }
            } else {
              // Fallback if payment generation fails
              if (mounted) _showSuccessDialog(bookingRef);
            }
          } catch (e) {
            // If payment link generation fails for any reason, booking is still confirmed.
            if (mounted) {
              _showSuccessDialog(bookingRef);
            }
          }
        } else {
          // Offline payment, just show success
          if (mounted) _showSuccessDialog(bookingRef);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create booking. Please try again.')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please review your booking details before confirming.',
                      style: GoogleFonts.inter(color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Booking Summary', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSummaryRow('Vehicle', '${widget.vehicle['brand']} ${widget.vehicle['model']}'),
            _buildSummaryRow('Pickup Shop', widget.shopName),
            _buildSummaryRow('Start Date', '${widget.startDateTime.day}/${widget.startDateTime.month}/${widget.startDateTime.year} ${TimeOfDay.fromDateTime(widget.startDateTime).format(context)}'),
            _buildSummaryRow('End Date', '${widget.endDateTime.day}/${widget.endDateTime.month}/${widget.endDateTime.year} ${TimeOfDay.fromDateTime(widget.endDateTime).format(context)}'),
            _buildSummaryRow('Total Hours', '$_rentalHours hrs'),
            const Divider(height: 40),
            Text('Price Breakdown', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPriceRow('Rental Amount (${_rentalHours}h × ₹${widget.vehicle['hourly_rate']})', '₹${_rentalAmount.toStringAsFixed(2)}'),
            
            // Coupon section
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    decoration: InputDecoration(
                      hintText: 'Enter Promo Code',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isApplyingCoupon ? null : _applyCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isApplyingCoupon 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Apply'),
                ),
              ],
            ),
            if (_couponMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _couponMessage!,
                  style: GoogleFonts.inter(fontSize: 12, color: _isCouponValid ? Colors.green.shade700 : Colors.red.shade700),
                ),
              ),
              
            if (_isCouponValid && _discountAmount > 0) ...[
              const SizedBox(height: 12),
              _buildPriceRow('Discount Applied ($_appliedCouponCode)', '-₹${_discountAmount.toStringAsFixed(2)}', color: Colors.green.shade700),
            ],
            
            const SizedBox(height: 12),
            _buildPriceRow('Security Deposit (Refundable)', '₹${_securityDeposit.toStringAsFixed(2)}'),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('₹${_totalAmount.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _showPaymentOptions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF212529),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Confirm & Book Now', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: GoogleFonts.inter(color: Colors.black54)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: color ?? Colors.black87)),
          Text(amount, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
