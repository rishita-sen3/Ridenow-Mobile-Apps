import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/api_client.dart';

final reviewsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return await ApiClient.get('/user/reviews');
});

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Reviews', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: reviewsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (reviews) {
          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('You haven\'t written any reviews yet.', style: GoogleFonts.inter(fontSize: 18, color: Colors.black54)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(reviewsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                final vehicle = review['vehicle'];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              vehicle != null ? '${vehicle['brand']} ${vehicle['model']}' : 'Unknown Vehicle',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < (review['rating'] ?? 0) ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                );
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          review['comment'] ?? 'No comment provided.',
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Posted on: ${review['created_at']?.substring(0, 10) ?? ''}',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
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
