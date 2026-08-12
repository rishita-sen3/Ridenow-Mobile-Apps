import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/api_client.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

final invoicesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return await ApiClient.get('/user/invoices');
});

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Invoices', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (invoices) {
          if (invoices.isEmpty) {
            return Center(
              child: Text('No invoices found.', style: GoogleFonts.inter(fontSize: 16)),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(invoicesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                return _buildInvoiceCard(context, invoice);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Map<String, dynamic> invoice) {
    final vehicle = invoice['vehicle'];
    final dateStr = invoice['updated_at'] ?? invoice['created_at'];
    final date = DateTime.tryParse(dateStr.toString()) ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                  invoice['booking_reference'] ?? 'INV-000',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade800),
                ),
                Text(
                  '₹${invoice['total_amount']}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade700),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              vehicle != null ? '${vehicle['brand']} ${vehicle['model']}' : 'Vehicle Rental',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date: ${date.day}/${date.month}/${date.year}',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PAID',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final response = await ApiClient.get('/user/invoices/${invoice['id']}/download-url');
                      if (response['url'] != null) {
                        final Uri url = Uri.parse(response['url']);
                        if (await url_launcher.canLaunchUrl(url)) {
                          await url_launcher.launchUrl(url, mode: url_launcher.LaunchMode.externalApplication);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the invoice file.')));
                          }
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to download invoice.')));
                      }
                    }
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text('Download', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade700,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
