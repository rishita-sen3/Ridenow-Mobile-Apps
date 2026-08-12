import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/providers.dart';
import '../widgets/app_drawer.dart';
import 'vehicle_details_screen.dart';
import 'shop_details_screen.dart';
import 'search_screen.dart';
import 'shops_screen.dart';
import 'my_bookings_screen.dart';
import '../widgets/booking_details_modal.dart';
import '../widgets/location_selector_bottom_sheet.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer(int pageCount) {
    _timer?.cancel();
    if (pageCount <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < pageCount - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final exploreAsync = ref.watch(exploreProvider);
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(exploreProvider);
            ref.invalidate(dashboardProvider);
          },
          child: CustomScrollView(
            slivers: [
              // Custom App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu, color: Colors.black87),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Image.asset('assets/images/logo.png', height: 24),
                                  const SizedBox(width: 8),
                                  Text('Ridezio', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -1.0)),
                                ],
                              ),
                              dashboardAsync.maybeWhen(
                              data: (data) => Text('Welcome Back, ${data['user']?['first_name'] ?? 'User'} 👋', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                              orElse: () => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Show Location Bottom Sheet
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const LocationSelectorBottomSheet(),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.red.shade600, size: 16),
                              const SizedBox(width: 4),
                              Consumer(
                                builder: (context, ref, child) {
                                  final loc = ref.watch(locationProvider);
                                  String locText = 'Select City';
                                  if (loc.city.isNotEmpty) {
                                    locText = loc.city;
                                  } else if (loc.lat != null) {
                                    locText = 'Current Location';
                                  }
                                  
                                  return Text(
                                    locText,
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey.shade500),
                          const SizedBox(width: 12),
                          Text('Search vehicles, locations...', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14)),
                          const Spacer(),
                          Icon(Icons.tune, color: Colors.blue.shade700, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              exploreAsync.when(
                loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
                data: (exploreData) {
                  final banners = exploreData['banners'] as List<dynamic>? ?? [];
                  final categories = exploreData['categories'] as List<dynamic>? ?? [];
                  final bestSellers = exploreData['best_sellers'] as List<dynamic>? ?? [];
                  final topShops = exploreData['top_shops'] as List<dynamic>? ?? [];
                  final recommended = exploreData['recommended'] as List<dynamic>? ?? [];

                  if (banners.isNotEmpty && _timer == null) {
                    _startTimer(banners.length);
                  }

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 16),
                      // Quick Categories
                      _buildSectionHeader('Quick Categories', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                      }),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            return _buildCategoryItem(cat);
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      // Hero Banners
                      if (banners.isNotEmpty) ...[
                        SizedBox(
                          height: 160,
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) => setState(() => _currentPage = index),
                            itemCount: banners.length,
                            itemBuilder: (context, index) {
                              final banner = banners[index];
                              return _buildHeroBanner(banner);
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(banners.length, (index) => _buildDot(index)),
                        ),
                      ],

                      const SizedBox(height: 24),
                      // Active Booking
                      dashboardAsync.maybeWhen(
                        data: (data) {
                          final recentBookings = data['recent_bookings'] as List<dynamic>? ?? [];
                          final activeBooking = recentBookings.firstWhere((b) => b['status'] == 'active' || b['status'] == 'confirmed', orElse: () => null);
                          if (activeBooking != null) {
                            return _buildActiveBookingCard(activeBooking);
                          }
                          return const SizedBox.shrink();
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 24),
                      // Best Sellers
                      if (bestSellers.isNotEmpty) ...[
                        _buildSectionHeader('Best Seller: ${bestSellers.first['shop']?['name'] ?? 'Top Picks'} ⭐', () {
                          if (bestSellers.first['shop'] != null) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ShopDetailsScreen(shopId: bestSellers.first['shop']['id'], shopName: bestSellers.first['shop']['name'])));
                          }
                        }),
                        const SizedBox(height: 12),
                      SizedBox(
                        height: 260,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: bestSellers.length,
                          itemBuilder: (context, index) => _buildVehicleCard(bestSellers[index]),
                        ),
                      ),
                      ],

                      const SizedBox(height: 24),
                      // Top Rental Shops
                      _buildSectionHeader('Top Rental Shops', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopsScreen()));
                      }),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 190,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: topShops.length,
                          itemBuilder: (context, index) => _buildShopCard(topShops[index]),
                        ),
                      ),

                      const SizedBox(height: 24),
                      // Recommended For You
                      _buildSectionHeader('Recommended For You', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                      }),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 260,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: recommended.length,
                          itemBuilder: (context, index) => _buildVehicleCard(recommended[index]),
                        ),
                      ),

                      const SizedBox(height: 24),
                      // Recent Bookings
                      dashboardAsync.maybeWhen(
                        data: (data) {
                          final recentBookings = data['recent_bookings'] as List<dynamic>? ?? [];
                          if (recentBookings.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader('Recent Bookings', () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
                              }),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  children: recentBookings.take(3).map((b) => _buildRecentBookingCard(b)).toList(),
                                ),
                              ),
                            ],
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 40),
                    ]),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.blue.shade700 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          GestureDetector(
            onTap: onViewAll,
            child: Text('View All', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue.shade700)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    IconData getIcon(String name) {
      switch (name) {
        case 'bikes': return Icons.two_wheeler;
        case 'cars': return Icons.directions_car;
        case 'scooters': return Icons.moped;
        case 'evs': return Icons.electric_car;
        case 'suvs': return Icons.airport_shuttle;
        case 'luxury': return Icons.diamond;
        default: return Icons.category;
      }
    }

    String getFilter(String catId) {
      switch (catId) {
        case 'bikes': return 'Bike';
        case 'scooters': return 'Scooter';
        case 'cars': return 'Car';
        default: return 'All';
      }
    }

    return GestureDetector(
      onTap: () {
        final filter = getFilter(category['id']);
        Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen(initialFilter: filter)));
      },
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(getIcon(category['id']), color: Colors.blue.shade700, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              category['name'],
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(Map<String, dynamic> banner) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(banner['title'] ?? 'Special Offer', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(banner['subtitle'] ?? '', style: GoogleFonts.inter(fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 24),
                if (banner['link_url'] != null && banner['link_url'].toString().isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Promo Code', style: GoogleFonts.inter(fontSize: 12, color: Colors.blue.shade700)),
                            const SizedBox(height: 4),
                            Text(banner['link_url'], style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          color: Colors.blue.shade700,
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: banner['link_url']));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coupon copied!')));
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text('Got it', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(banner['image_url']),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                banner['title'],
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                banner['subtitle'],
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailsScreen(vehicle: vehicle, shopId: vehicle['shop_id'] ?? 1, shopName: vehicle['shop']?['name'] ?? 'Shop'))),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    image: DecorationImage(
                      image: NetworkImage(vehicle['image_url'] ?? 'https://via.placeholder.com/150'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Colors.redAccent, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          '${vehicle['shop']?['city'] ?? vehicle['city'] ?? 'Location N/A'}',
                          style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                if (vehicle['distance_km'] != null)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade200, width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions_car, color: Colors.blue.shade700, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            '${double.parse(vehicle['distance_km'].toString()).toStringAsFixed(1)} km away',
                            style: GoogleFonts.inter(fontSize: 10, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicle['brand']} ${vehicle['model']}',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 14),
                      const SizedBox(width: 4),
                      Text('4.8', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(' (${vehicle['bookings_count'] ?? 0})', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${vehicle['daily_rate'] ?? (vehicle['hourly_rate'] != null ? vehicle['hourly_rate'] * 24 : 0)}/day',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                        child: Icon(Icons.arrow_forward_ios, size: 12, color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopDetailsScreen(shopId: shop['id'], shopName: shop['name']))),
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                image: DecorationImage(
                  image: NetworkImage(shop['image_url'] ?? 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?q=80&w=400'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(shop['name'], style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 14),
                          const SizedBox(width: 4),
                          Text('4.9', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(shop['city'] ?? 'Location N/A', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                      const Spacer(),
                      Text('${shop['vehicles_count'] ?? 0} Vehicles', style: GoogleFonts.inter(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBookingCard(Map<String, dynamic> booking) {
    final vehicle = booking['vehicle'] ?? {};
    final shop = vehicle['shop'] ?? {};
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade100, width: 2),
          boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(shop['name'] ?? 'Shop', style: GoogleFonts.inter(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 13)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                  child: Text(booking['status'].toString().toUpperCase(), style: GoogleFonts.inter(color: Colors.blue.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    image: vehicle['image_url'] != null ? DecorationImage(image: NetworkImage(vehicle['image_url']), fit: BoxFit.cover) : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${vehicle['brand']} ${vehicle['model']}', style: GoogleFonts.inter(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Booking ID: ${booking['booking_reference']}', style: GoogleFonts.inter(color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeWidget('Pickup', booking['start_datetime'], shop['city'] ?? 'Location'),
                const Icon(Icons.arrow_forward, color: Colors.black26, size: 20),
                _buildTimeWidget('Drop', booking['end_datetime'], shop['city'] ?? 'Location', alignRight: true),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => BookingDetailsModal.show(context, booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('View Details', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeWidget(String label, String? time, String location, {bool alignRight = false}) {
    final t = time != null ? DateFormat('dd MMM, hh:mm a').format(DateTime.parse(time)) : 'N/A';
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!alignRight) ...[
              Icon(label == 'Pickup' ? Icons.flight_takeoff : Icons.flight_land, size: 14, color: Colors.blue.shade700),
              const SizedBox(width: 4),
            ],
            Text(label, style: GoogleFonts.inter(color: Colors.black54, fontSize: 12)),
            if (alignRight) ...[
              const SizedBox(width: 4),
              Icon(label == 'Pickup' ? Icons.flight_takeoff : Icons.flight_land, size: 14, color: Colors.blue.shade700),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(t, style: GoogleFonts.inter(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(location, style: GoogleFonts.inter(color: Colors.black54, fontSize: 12)),
      ],
    );
  }

  Widget _buildRecentBookingCard(Map<String, dynamic> booking) {
    final vehicle = booking['vehicle'] ?? {};
    final shop = vehicle['shop'] ?? {};
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => BookingDetailsModal.show(context, booking),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100,
                    image: vehicle['image_url'] != null ? DecorationImage(image: NetworkImage(vehicle['image_url']), fit: BoxFit.cover) : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${vehicle['brand']} ${vehicle['model']}',
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: booking['status'] == 'completed' ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              booking['status'].toString().toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: booking['status'] == 'completed' ? Colors.green.shade700 : Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(shop['name'] ?? 'Unknown Shop', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 12, color: Colors.blue.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      booking['start_datetime'] != null ? DateFormat('dd MMM, hh:mm a').format(DateTime.parse(booking['start_datetime'])) : 'N/A',
                                      style: GoogleFonts.inter(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${booking['total_amount']}',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green.shade700),
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
}
