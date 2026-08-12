import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/providers.dart';

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(offersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Exclusive Offers', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: offersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (offers) {
          if (offers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No active offers at the moment.', style: GoogleFonts.inter(fontSize: 18, color: Colors.black54)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(offersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: offers.length,
              itemBuilder: (context, index) {
                final offer = offers[index];
                final code = offer['code'] ?? 'AUTO';
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: Center(
                          child: Text(
                            offer['discount_type'] == 'percentage' 
                                ? '${offer['discount_value']}% OFF'
                                : '₹${offer['discount_value']} OFF',
                            style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.blue.shade900),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer['title'] ?? 'Special Discount',
                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              offer['details'] ?? 'Use this offer to get a discount on your next ride.',
                              style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: code));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Coupon code "$code" copied to clipboard!'),
                                    backgroundColor: Colors.green.shade700,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Code: $code',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.blue.shade800),
                                    ),
                                    Icon(Icons.copy, size: 18, color: Colors.blue.shade700),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Valid till: ${offer['end_date']?.substring(0, 10) ?? 'Limited Time'}',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
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
