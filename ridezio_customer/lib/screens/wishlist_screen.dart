import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/api_client.dart';
import 'vehicle_details_screen.dart';

final wishlistProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return await ApiClient.get('/user/wishlist');
});

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Wishlist', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: wishlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (wishlist) {
          if (wishlist.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Your wishlist is empty', style: GoogleFonts.inter(fontSize: 18, color: Colors.black54)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(wishlistProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 240,
              ),
              itemCount: wishlist.length,
              itemBuilder: (context, index) {
                final item = wishlist[index];
                final vehicle = item['vehicle'];
                if (vehicle == null) return const SizedBox();
                final shop = vehicle['shop'];

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => VehicleDetailsScreen(
                          vehicle: vehicle, 
                          shopId: shop['id'], 
                          shopName: shop['name'],
                        )
                      ));
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              image: vehicle['image_url'] != null
                                  ? DecorationImage(image: NetworkImage(vehicle['image_url']), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: vehicle['image_url'] == null ? const Icon(Icons.directions_car, color: Colors.grey, size: 40) : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${vehicle['brand']} ${vehicle['model']}',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${vehicle['hourly_rate']}/hr',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
