import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../screens/booking_success_screen.dart';
import '../core/providers.dart';

class ExtendRideBottomSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> booking;

  const ExtendRideBottomSheet({super.key, required this.booking});

  @override
  ConsumerState<ExtendRideBottomSheet> createState() => _ExtendRideBottomSheetState();
}

class _ExtendRideBottomSheetState extends ConsumerState<ExtendRideBottomSheet> {
  final NumberFormat _currencyFormatter = NumberFormat('#,##,000');

  late DateTime _currentEnd;
  DateTime? _newEnd;

  bool _isExtending = false;
  bool _isLoadingPreview = false;
  Map<String, dynamic>? _previewData;

  // ── Computed helpers ─────────────────────────────────────────────────────

  double get _hourlyRate {
    if (_previewData?['hourly_rate'] != null) {
      return double.tryParse(_previewData!['hourly_rate'].toString()) ?? 0.0;
    }
    return double.tryParse(
          (widget.booking['vehicle']?['hourly_rate'] ??
                  widget.booking['hourly_rate'] ??
                  0)
              .toString(),
        ) ??
        0.0;
  }

  int get _localExtraHours {
    if (_newEnd == null) return 0;
    final mins = _newEnd!.difference(_currentEnd).inMinutes;
    return mins > 0 ? (mins / 60).ceil() : 0;
  }

  int get _extraHours =>
      _previewData?['extra_hours'] as int? ?? _localExtraHours;

  double get _extraCharges {
    if (_previewData?['extra_charges'] != null) {
      return double.tryParse(_previewData!['extra_charges'].toString()) ?? 0.0;
    }
    return (_localExtraHours * _hourlyRate).toDouble();
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Parse current end time safely – no API call here to avoid flicker
    try {
      _currentEnd = widget.booking['end_datetime'] != null
          ? DateTime.parse(widget.booking['end_datetime'].toString())
          : DateTime.now();
    } catch (_) {
      _currentEnd = DateTime.now();
    }
    // Default new end = current + 1 hour (just local, no network)
    _newEnd = _currentEnd.add(const Duration(hours: 1));
  }

  // ── API preview – called ONLY after user picks a date ────────────────────

  Future<void> _fetchPreview() async {
    if (_newEnd == null || _localExtraHours <= 0) return;
    if (!mounted) return;

    setState(() => _isLoadingPreview = true);

    try {
      final res = await ApiClient.get(
        '/user/bookings/${widget.booking['id']}/extend-preview?extra_hours=$_localExtraHours',
      );
      if (!mounted) return;
      if (res['status'] == 'success') {
        setState(() {
          _previewData = res['data'];
          _isLoadingPreview = false;
        });
      } else {
        setState(() => _isLoadingPreview = false);
      }
    } catch (e) {
      debugPrint('Extend Preview Error: $e');
      if (!mounted) return;
      setState(() => _isLoadingPreview = false);
    }
  }

  // ── Date/time picker ─────────────────────────────────────────────────────

  Future<void> _selectDateTime() async {
    final initial = (_newEnd != null && _newEnd!.isAfter(_currentEnd))
        ? _newEnd!
        : _currentEnd.add(const Duration(hours: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _currentEnd,
      lastDate: _currentEnd.add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: Colors.blue.shade600),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: Colors.blue.shade600),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    final selected =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);

    if (!selected.isAfter(_currentEnd)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New end time must be after current end time.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _newEnd = selected;
      _previewData = null; // reset so local estimate shows instantly
    });

    // Fetch server-accurate price in background
    _fetchPreview();
  }

  // ── Confirm extension ─────────────────────────────────────────────────────

  Future<void> _confirmExtend() async {
    if (_localExtraHours <= 0 || _isExtending) return;

    setState(() => _isExtending = true);

    try {
      final res = await ApiClient.post(
        '/user/bookings/${widget.booking['id']}/extend',
        {
          'booking_id': widget.booking['id'],
          'new_end_datetime':
              DateFormat('yyyy-MM-dd HH:mm:ss').format(_newEnd!),
          'extra_hours': _extraHours,
          'hourly_rate': _hourlyRate,
          'extra_charges': _extraCharges,
        },
      );

      if (!mounted) return;

      if (res['status'] == 'success') {
        Navigator.pop(context);
        ref.refresh(bookingsProvider);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingSuccessScreen(
              title: 'Ride Extended!',
              message: 'Your ride has been extended successfully.',
              details: [
                {
                  'label': 'Extra Hours',
                  'value': '$_extraHours hrs',
                  'isStatus': false,
                },
                {
                  'label': 'Extension Charges',
                  'value': '₹${_currencyFormatter.format(_extraCharges)}',
                  'isError': true,
                },
                {
                  'label': 'New End Time',
                  'value': DateFormat('dd MMM, hh:mm a').format(_newEnd!),
                  'isStatus': false,
                },
                if ((res['data']?['updated_total'] ?? 0) > 0)
                  {
                    'label': 'Updated Total',
                    'value':
                        '₹${_currencyFormatter.format(res['data']['updated_total'])}',
                    'isSuccess': true,
                  },
              ],
              footerText:
                  'Extra charges will be collected at shop upon return.',
            ),
          ),
        );
      } else {
        setState(() => _isExtending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Extension failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Extend Booking Error: $e');
      if (!mounted) return;
      setState(() => _isExtending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to extend ride. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canConfirm = !_isExtending && _localExtraHours > 0;

    return Padding(
      // Lift sheet above keyboard
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Extend Ride',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Current end time
            _label('Current End Date & Time', Colors.grey.shade600),
            const SizedBox(height: 8),
            _infoBox(
              icon: Icons.calendar_today,
              color: Colors.grey,
              text: DateFormat('dd MMM yyyy, hh:mm a').format(_currentEnd),
              bgColor: Colors.grey.shade100,
              borderColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),

            // ── New end time (tap to pick)
            _label('New End Date & Time', Colors.blue.shade700),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDateTime,
              borderRadius: BorderRadius.circular(12),
              child: _infoBox(
                icon: Icons.calendar_month,
                color: Colors.blue.shade700,
                text: _newEnd != null
                    ? DateFormat('dd MMM yyyy, hh:mm a').format(_newEnd!)
                    : 'Tap to select new end time',
                bgColor: Colors.blue.shade50,
                borderColor: Colors.blue.shade200,
                trailing: Icon(Icons.edit, size: 16, color: Colors.blue.shade700),
              ),
            ),
            const SizedBox(height: 20),

            // ── Charges summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _chargeRow(
                    'Hourly Rate',
                    '₹${_currencyFormatter.format(_hourlyRate)}/hr',
                  ),
                  const SizedBox(height: 10),
                  _chargeRow(
                    'Extra Hours',
                    '$_extraHours hrs',
                    valueColor: _extraHours > 0
                        ? Colors.blue.shade700
                        : Colors.black54,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: Colors.grey.shade300),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Extension Charges',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      _isLoadingPreview
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.blue.shade600,
                              ),
                            )
                          : Text(
                              '₹${_currencyFormatter.format(_extraCharges)}',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                    ],
                  ),
                  if (_localExtraHours > 0 &&
                      _previewData == null &&
                      !_isLoadingPreview)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '* Estimated',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.orange.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canConfirm ? _confirmExtend : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: canConfirm ? 2 : 0,
                ),
                child: _isExtending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        canConfirm
                            ? 'Confirm Extension'
                            : 'Select new end time',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: canConfirm ? Colors.white : Colors.grey.shade500,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Small helpers ─────────────────────────────────────────────────────────

  Widget _label(String text, Color color) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _infoBox({
    required IconData icon,
    required Color color,
    required String text,
    required Color bgColor,
    required Color borderColor,
    Widget? trailing,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      );

  Widget _chargeRow(String label, String value, {Color? valueColor}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      );
}
