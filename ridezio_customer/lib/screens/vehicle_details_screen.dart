import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../core/providers.dart';
import 'checkout_screen.dart';
import 'wishlist_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class VehicleDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> vehicle;
  final int shopId;
  final String shopName;

  const VehicleDetailsScreen({
    super.key,
    required this.vehicle,
    required this.shopId,
    required this.shopName,
  });

  @override
  ConsumerState<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends ConsumerState<VehicleDetailsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _isWishlistLoading = false;
  late bool _isInWishlist;

  List<dynamic> _reviews = [];
  bool _isReviewsLoading = true;
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _isInWishlist = widget.vehicle['is_in_wishlist'] == true;
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      final response = await ApiClient.get('/vehicles/${widget.vehicle['id']}/reviews');
      if (mounted) {
        setState(() {
          _reviews = response;
          _isReviewsLoading = false;
          
          if (_reviews.isNotEmpty) {
            double total = 0;
            for (var review in _reviews) {
              total += double.parse(review['rating'].toString());
            }
            _averageRating = total / _reviews.length;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isReviewsLoading = false);
      }
    }
  }

  Future<void> _selectDateTime(bool isStart) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          if (isStart) {
            _startDate = pickedDate;
            _startTime = pickedTime;
          } else {
            _endDate = pickedDate;
            _endTime = pickedTime;
          }
        });
      }
    }
  }

  Future<void> _toggleWishlist() async {
    setState(() => _isWishlistLoading = true);
    try {
      final response = await ApiClient.post('/user/wishlist/toggle', {'vehicle_id': widget.vehicle['id']});
      setState(() {
        _isInWishlist = response['status'] == 'added';
      });
      ref.refresh(wishlistProvider);
      ref.refresh(vehiclesProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'])));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update wishlist')));
    } finally {
      setState(() => _isWishlistLoading = false);
    }
  }

  void _proceedToCheckout() {
    if (_startDate == null || _startTime == null || _endDate == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select pickup and dropoff dates & times.')));
      return;
    }

    final startDateTime = DateTime(_startDate!.year, _startDate!.month, _startDate!.day, _startTime!.hour, _startTime!.minute);
    final endDateTime = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, _endTime!.hour, _endTime!.minute);

    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dropoff time must be after pickup time.')));
      return;
    }

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CheckoutScreen(
        vehicle: widget.vehicle,
        shopId: widget.shopId,
        shopName: widget.shopName,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
      ),
    ));
  }

  int _calculateDays() {
    if (_startDate == null || _endDate == null) return 1;
    final diff = _endDate!.difference(_startDate!).inDays;
    return diff > 0 ? diff : 1;
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;
    final formatter = NumberFormat('#,##,000');
    final int dailyRate = vehicle['daily_rate'] ?? 0;
    final int hourlyRate = vehicle['hourly_rate'] ?? 0;
    final int securityDeposit = vehicle['security_deposit'] ?? 0;
    final int days = _calculateDays();
    final int totalEst = (dailyRate * days) + securityDeposit;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: 24),
            const SizedBox(width: 8),
            Text('Ridezio', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isWishlistLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_isInWishlist ? Icons.favorite : Icons.favorite_border, color: _isInWishlist ? Colors.red : Colors.black87),
            onPressed: _toggleWishlist,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gallery Image with Location Badge
                Stack(
                  children: [
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        image: vehicle['image_url'] != null
                            ? DecorationImage(image: NetworkImage(vehicle['image_url']), fit: BoxFit.cover)
                            : null,
                      ),
                      child: vehicle['image_url'] == null ? const Icon(Icons.directions_car, size: 80, color: Colors.grey) : null,
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${vehicle['shop']?['city'] ?? 'Location N/A'}, ${vehicle['shop']?['state'] ?? ''}',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (vehicle['distance_km'] != null)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade200, width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.directions_car, color: Colors.blue.shade700, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${double.parse(vehicle['distance_km'].toString()).toStringAsFixed(1)} km away',
                                style: GoogleFonts.inter(fontSize: 13, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '${vehicle['brand']} ${vehicle['model']}',
                              style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (vehicle['type']?.toString() ?? 'Vehicle'),
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.storefront, size: 18, color: Colors.black54),
                          const SizedBox(width: 8),
                          Text(
                            widget.shopName,
                            style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.black54, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            _isReviewsLoading 
                                ? 'Loading reviews...' 
                                : _reviews.isEmpty 
                                    ? 'No reviews yet' 
                                    : '${_averageRating.toStringAsFixed(1)} (${_reviews.length} reviews)',
                            style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        vehicle['description'] ?? 'Experience the thrill of riding the ${vehicle['brand']} ${vehicle['model']}. A perfect choice for your next journey.',
                        style: GoogleFonts.inter(fontSize: 16, height: 1.6, color: Colors.black54),
                      ),
                      const SizedBox(height: 32),
                      const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                      const SizedBox(height: 32),

                      // Specifications
                      Text('Specifications', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.5,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 8,
                        children: [
                          _buildSpecItem(Icons.speed, 'Type', (vehicle['type'] ?? 'N/A').toString()),
                          _buildSpecItem(Icons.local_gas_station, 'Fuel Type', (vehicle['fuel_type'] ?? 'Petrol').toString()),
                          _buildSpecItem(Icons.settings, 'Transmission', (vehicle['transmission'] ?? 'Manual').toString()),
                          _buildSpecItem(Icons.people, 'Seating Capacity', '${vehicle['seating_capacity'] ?? '2'} Seats'),
                          _buildSpecItem(Icons.palette, 'Color', vehicle['color'] ?? 'N/A'),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                      const SizedBox(height: 32),

                      // Location & Hub Details
                      if (vehicle['shop'] != null) ...[
                        Text('Location & Hub Details', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Map Preview (Clickable)
                              InkWell(
                                onTap: _openMap,
                                child: Container(
                                  height: 160,
                                  width: double.infinity,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE5E3DF), // Map-like background color
                                    image: DecorationImage(
                                      image: NetworkImage('https://i.stack.imgur.com/HILmr.png'), // generic map placeholder
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(Colors.black12, BlendMode.darken),
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.location_on, color: Colors.red, size: 48),
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                          ),
                                          child: Text('Tap to view on Google Maps', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(vehicle['shop']?['name'] ?? 'Shop', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 16, color: Colors.black54),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${vehicle['shop']?['address'] ?? ''}, ${vehicle['shop']?['city'] ?? ''}, ${vehicle['shop']?['state'] ?? ''}',
                                            style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Working hours', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 4),
                                              Text('Mon - Sun: 24 Hours', style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Contact', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 4),
                                              Text(vehicle['shop']?['owner']?['phone'] ?? '+91 98765 43210', style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
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
                        const SizedBox(height: 32),
                        const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                        const SizedBox(height: 32),
                      ],

                      // Reviews Section
                      Text('Reviews', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            _isReviewsLoading 
                                ? 'Loading...' 
                                : _reviews.isEmpty 
                                    ? 'No reviews yet' 
                                    : '${_averageRating.toStringAsFixed(1)} (${_reviews.length} reviews)',
                            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      if (_isReviewsLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_reviews.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.rate_review_outlined, size: 48, color: Colors.black26),
                                const SizedBox(height: 16),
                                Text('No reviews yet', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                                const SizedBox(height: 8),
                                Text('Be the first to review this vehicle!', style: GoogleFonts.inter(fontSize: 14, color: Colors.black45)),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reviews.length > 3 ? 3 : _reviews.length, // show top 3 max
                          separatorBuilder: (context, index) => const Divider(height: 32),
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            final customer = review['customer'] ?? {};
                            final rating = double.tryParse(review['rating'].toString()) ?? 0.0;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.grey.shade200,
                                      backgroundImage: customer['profile_image'] != null 
                                          ? NetworkImage(customer['profile_image']) 
                                          : null,
                                      child: customer['profile_image'] == null 
                                          ? const Icon(Icons.person, color: Colors.grey) 
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(customer['name'] ?? 'User', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                                          Text(_formatDateStr(review['created_at']), style: GoogleFonts.inter(color: Colors.black54, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.amber.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 14),
                                          const SizedBox(width: 4),
                                          Text(rating.toStringAsFixed(1), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade900)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (review['comment'] != null && review['comment'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    review['comment'],
                                    style: GoogleFonts.inter(fontSize: 14, color: Colors.black87, height: 1.5),
                                  ),
                                ]
                              ],
                            );
                          },
                        ),
                        
                      const SizedBox(height: 32),
                      const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                      const SizedBox(height: 24),
                      
                      // Pricing Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildPriceColumn('Hourly', hourlyRate, formatter),
                          Container(width: 1, height: 40, color: Colors.grey.shade300),
                          _buildPriceColumn('Daily', dailyRate, formatter),
                          Container(width: 1, height: 40, color: Colors.grey.shade300),
                          _buildPriceColumn('Deposit', securityDeposit, formatter),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                      const SizedBox(height: 24),

                      // Date & Time Pickers
                      Text('Pickup Date & Time', style: GoogleFonts.inter(fontSize: 14, color: Colors.black54)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDateTime(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _startDate == null ? 'dd-mm-yyyy --:--' : '${DateFormat('dd-MM-yyyy').format(_startDate!)} ${_startTime!.format(context)}',
                                style: GoogleFonts.inter(fontSize: 16, color: _startDate == null ? Colors.black54 : Colors.black87),
                              ),
                              const Icon(Icons.calendar_today, size: 20, color: Colors.black87),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Dropoff Date & Time', style: GoogleFonts.inter(fontSize: 14, color: Colors.black54)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDateTime(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _endDate == null ? 'dd-mm-yyyy --:--' : '${DateFormat('dd-MM-yyyy').format(_endDate!)} ${_endTime!.format(context)}',
                                style: GoogleFonts.inter(fontSize: 16, color: _endDate == null ? Colors.black54 : Colors.black87),
                              ),
                              const Icon(Icons.calendar_today, size: 20, color: Colors.black87),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Summary Widget
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, 4), blurRadius: 10),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Summary', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Rental ($days Day${days > 1 ? 's' : ''})', style: GoogleFonts.inter(fontSize: 16, color: Colors.blue.shade700)),
                                Text('₹${formatter.format(dailyRate * days)}', style: GoogleFonts.inter(fontSize: 16, color: Colors.black87)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Hourly Rate', style: GoogleFonts.inter(fontSize: 16, color: Colors.black54)),
                                Text('₹${formatter.format(hourlyRate)}/hr', style: GoogleFonts.inter(fontSize: 16, color: Colors.black87)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Refundable Deposit', style: GoogleFonts.inter(fontSize: 16, color: Colors.black54)),
                                Text('₹${formatter.format(securityDeposit)}', style: GoogleFonts.inter(fontSize: 16, color: Colors.black87)),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Divider(color: Color(0xFFE5E7EB)),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total (Est.)', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text('₹${formatter.format(totalEst)}', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: vehicle['status'] == 'available' ? _proceedToCheckout : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            vehicle['status'] == 'available' ? 'Book Now' : 'Currently Unavailable', 
                            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.black87),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceColumn(String title, dynamic amount, NumberFormat formatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        Text(
          '₹${formatter.format(amount ?? 0)}',
          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Future<void> _openMap() async {
    final shop = widget.vehicle['shop'];
    if (shop == null) return;
    
    final lat = shop['latitude'];
    final lng = shop['longitude'];
    
    String url;
    if (lat != null && lng != null) {
      url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    } else {
      final query = Uri.encodeComponent('${shop['address']} ${shop['city']} ${shop['state']}');
      url = 'https://www.google.com/maps/search/?api=1&query=$query';
    }
    
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open map')));
      }
    }
  }

  String _formatDateStr(dynamic dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString.toString());
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString.toString();
    }
  }
}
