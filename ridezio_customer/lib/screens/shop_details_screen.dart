import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/providers.dart';
import 'vehicle_details_screen.dart';
import '../widgets/wishlist_button.dart';
import 'package:url_launcher/url_launcher.dart';

class ShopDetailsScreen extends ConsumerWidget {
  final int shopId;
  final String shopName;

  const ShopDetailsScreen({super.key, required this.shopId, required this.shopName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopDetailsProvider(shopId));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: shopAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (shop) {
          final List<dynamic> allVehicles = shop['vehicles'] ?? [];
          final bool isVerified = shop['is_approved'] == 1;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    shop['name'],
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, shadows: [
                      const Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))
                    ]),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        shop['image_url'] ?? 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?q=80&w=800',
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade200, width: 2),
                              image: const DecorationImage(
                                image: NetworkImage('https://via.placeholder.com/150'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        shop['name'],
                                        style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (isVerified)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.verified, color: Colors.green, size: 14),
                                            const SizedBox(width: 4),
                                            Text('VERIFIED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.orange, size: 16),
                                    const SizedBox(width: 4),
                                    Text('4.7 (258 Reviews)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Colors.black54),
                                    const SizedBox(width: 4),
                                    Text('${shop['city'] ?? 'Location N/A'}, India', style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildShopStatCard(Icons.directions_car, '${allVehicles.length}+', 'Vehicles'),
                          _buildShopStatCard(Icons.calendar_today, '4+', 'Years'),
                          _buildShopStatCard(Icons.access_time, '9 AM - 9 PM', 'Open'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Your trusted rental partner in ${shop['city'] ?? 'India'}. Best prices, well-maintained vehicles & excellent service.', style: GoogleFonts.inter(fontSize: 14, color: Colors.black87, height: 1.5)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final phone = shop['contact_number'] ?? shop['phone'] ?? '9876543210';
                                final uri = Uri.parse('tel:$phone');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                              icon: const Icon(Icons.phone_outlined, size: 18),
                              label: const Text('Call Shop'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final query = Uri.encodeComponent('${shop['name']}, ${shop['city'] ?? 'India'}');
                                final uri = Uri.parse('https://maps.google.com/?q=$query');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.directions, size: 18),
                              label: const Text('Get Directions'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      if (allVehicles.isNotEmpty) ...[
                        _buildSectionHeader('Best Seller Vehicles', () {}),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 260,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: allVehicles.take(3).length,
                            itemBuilder: (context, index) => _buildHorizontalVehicleCard(context, allVehicles[index]),
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildSectionHeader('All Available Vehicles', () {}),
                      ]
                    ],
                  ),
                ),
              ),
              if (allVehicles.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 280,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildGridVehicleCard(context, allVehicles[index]),
                      childCount: allVehicles.length,
                    ),
                  ),
                ),
              if (allVehicles.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                      child: Text('No vehicles available right now.', style: GoogleFonts.inter(fontSize: 16, color: Colors.black54)),
                    ),
                  ),
                ),
              SliverToBoxAdapter(child: const SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShopStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 24),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        GestureDetector(
          onTap: onViewAll,
          child: Text('View All', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue.shade700)),
        ),
      ],
    );
  }

  Widget _buildHorizontalVehicleCard(BuildContext context, Map<String, dynamic> vehicle) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailsScreen(vehicle: vehicle, shopId: shopId, shopName: shopName))),
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

  Widget _buildGridVehicleCard(BuildContext context, Map<String, dynamic> vehicle) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailsScreen(vehicle: vehicle, shopId: shopId, shopName: shopName))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    image: DecorationImage(
                      image: NetworkImage(vehicle['image_url'] ?? 'https://via.placeholder.com/150'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: WishlistButton(vehicleId: vehicle['id'], initialStatus: vehicle['is_in_wishlist'] ?? false),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      vehicle['type'].toString().toUpperCase(),
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${vehicle['brand']} ${vehicle['model']}',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${vehicle['daily_rate'] ?? (vehicle['hourly_rate'] != null ? vehicle['hourly_rate'] * 24 : 0)} / day',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.green.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
