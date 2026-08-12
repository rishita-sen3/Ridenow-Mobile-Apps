import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/providers.dart';
import 'shop_details_screen.dart';

class ShopsScreen extends ConsumerWidget {
  const ShopsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(shopsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Select a Shop', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: shopsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (shops) {
          if (shops.isEmpty) {
            return Center(
              child: Text('No shops available.', style: GoogleFonts.inter(fontSize: 16)),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(shopsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: shops.length,
              itemBuilder: (context, index) {
                final shop = shops[index];
                return _buildShopCard(shop, context);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop, BuildContext context) {
    // Generate dummy brands string since API doesn't return it yet, matching the website screenshot
    final String brands = 'Honda, TVS, Royal Enfield${shop['id'] % 2 == 0 ? ', Yamaha' : ''}';
    final bool isBestSeller = (shop['id'] == 1); // Mock Best Seller for shop ID 1

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ShopDetailsScreen(shopId: shop['id'], shopName: shop['name'])
          ));
        },
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Image/Icon Area
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.storefront_outlined, size: 60, color: Colors.black87),
                  ),
                  if (isBestSeller)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 12, color: Colors.black),
                            const SizedBox(width: 4),
                            Text(
                              'BEST SELLER SHOP',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Bottom Info Area
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop['name'] ?? 'Unknown Shop',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          shop['city'] ?? 'Location not specified',
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    brands,
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${shop['vehicles_count'] ?? 0} Vehicles',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ShopDetailsScreen(shopId: shop['id'], shopName: shop['name'])
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text(
                          'View Vehicles',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
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
    );
  }
}
