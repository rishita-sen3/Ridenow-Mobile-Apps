import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/providers.dart';
import 'vehicle_details_screen.dart';
import '../widgets/wishlist_button.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return Scaffold(
      appBar: AppBar(title: Text('All Vehicles', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
      body: vehiclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading vehicles: $err')),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return const Center(child: Text('No vehicles available right now.'));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(vehiclesProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 340,
              ),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                final shop = vehicle['shop'];
                final bool isAvailable = vehicle['status'] == 'available';
                final int shopId = shop != null ? shop['id'] : 0;
                final String shopName = shop != null ? shop['name'] : 'Unknown Shop';

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      if (shop != null) {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => VehicleDetailsScreen(
                            vehicle: vehicle, 
                            shopId: shopId, 
                            shopName: shopName,
                          )
                        ));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop details not available for this vehicle.')));
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Image Area
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  image: vehicle['image_url'] != null
                                      ? DecorationImage(image: NetworkImage(vehicle['image_url']), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: vehicle['image_url'] == null ? const Icon(Icons.directions_car, color: Colors.grey, size: 40) : null,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: WishlistButton(
                                  vehicleId: vehicle['id'],
                                  initialStatus: vehicle['is_in_wishlist'] == true,
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
                                      const Icon(Icons.location_on, color: Colors.redAccent, size: 11),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${shop?['city'] ?? 'N/A'}',
                                        style: GoogleFonts.inter(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w500),
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
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${vehicle['brand']} ${vehicle['model']}',
                                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.star, size: 10, color: Colors.black),
                                            const SizedBox(width: 2),
                                            Text('5.0', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(isAvailable ? Icons.check_circle : Icons.cancel, size: 12, color: isAvailable ? Colors.green : Colors.red),
                                      const SizedBox(width: 4),
                                      Text(
                                        isAvailable ? 'Available now' : 'Unavailable',
                                        style: GoogleFonts.inter(fontSize: 12, color: isAvailable ? Colors.black87 : Colors.red),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${vehicle['fuel_type'] ?? 'Petrol'} • ${vehicle['transmission'] ?? 'Manual'} • ${vehicle['seating_capacity'] ?? '2'} Seats',
                                    style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (shop != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.shop, size: 12, color: Colors.black54),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            shopName,
                                            style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (vehicle['distance'] != null && vehicle['distance'].toString() != '0')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          '${double.parse(vehicle['distance'].toString()).toStringAsFixed(1)} km away',
                                          style: GoogleFonts.inter(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ]
                                ],
                              ),
                              const Divider(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '₹${vehicle['daily_rate'] ?? vehicle['hourly_rate'] ?? 0}',
                                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      Text('/ day', style: GoogleFonts.inter(fontSize: 10, color: Colors.black54)),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (shop != null) {
                                        Navigator.push(context, MaterialPageRoute(
                                          builder: (_) => VehicleDetailsScreen(
                                            vehicle: vehicle, 
                                            shopId: shopId, 
                                            shopName: shopName,
                                          )
                                        ));
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      minimumSize: Size.zero,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                    child: Text('Book', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
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
              },
            ),
          );
        },
      ),
    );
  }
}
