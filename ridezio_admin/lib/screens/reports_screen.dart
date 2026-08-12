import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../core/providers.dart';
import '../services/api_service.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final Map<String, String> _filters = const {};
  bool _isDownloading = false;
  String? _downloadingMonth;

  Future<void> _downloadAndOpenReport(String month) async {
    setState(() {
      _isDownloading = true;
      _downloadingMonth = month;
    });

    try {
      final bytes = await ref.read(apiServiceProvider).downloadReport(month);
      
      String path;
      if (Platform.isAndroid) {
        // Use the public Downloads folder on Android
        path = '/storage/emulated/0/Download/Ridezio_Report_${month.replaceAll(' ', '_')}.pdf';
      } else {
        final dir = await getApplicationDocumentsDirectory();
        path = '${dir.path}/Ridezio_Report_${month.replaceAll(' ', '_')}.pdf';
      }
      
      final file = File(path);
      await file.writeAsBytes(bytes);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded successfully to Downloads folder!')));
      }
      
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file: ${result.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading report: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadingMonth = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider(_filters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(bookingsProvider(_filters).future),
          ),
        ],
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (allBookings) {
          final validStatuses = ['active', 'completed', 'confirmed'];
          final bookings = allBookings.where((b) => validStatuses.contains(b.status.toLowerCase())).toList();

          double totalRevenue = 0;
          for (var b in bookings) {
            totalRevenue += b.rentalAmount;
          }
          final totalBookings = bookings.length;
          final avgBookingValue = totalBookings > 0 ? totalRevenue / totalBookings : 0.0;

          final Map<String, Map<String, dynamic>> monthlyData = {};
          for (var b in bookings) {
            final month = DateFormat('MMM yyyy').format(DateTime.parse(b.createdAt));
            if (!monthlyData.containsKey(month)) {
              monthlyData[month] = {'revenue': 0.0, 'count': 0};
            }
            monthlyData[month]!['revenue'] = (monthlyData[month]!['revenue'] as double) + b.rentalAmount;
            monthlyData[month]!['count'] = (monthlyData[month]!['count'] as int) + 1;
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(bookingsProvider(_filters).future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCards(totalRevenue, totalBookings, avgBookingValue),
                const SizedBox(height: 24),
                const Text('Monthly Revenue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (monthlyData.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No data available', style: TextStyle(color: Colors.grey))),
                  )
                else
                  ...monthlyData.entries.map((e) => _buildMonthCard(e.key, e.value['revenue'], e.value['count'])),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(double totalRevenue, int totalBookings, double avgBookingValue) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Revenue', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              Text('₹${NumberFormat('#,##0.00').format(totalRevenue)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.confirmation_number, color: Colors.blue),
                    const SizedBox(height: 12),
                    Text(totalBookings.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Text('Total Bookings', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.analytics, color: Colors.green),
                    const SizedBox(height: 12),
                    Text('₹${NumberFormat('#,##0').format(avgBookingValue)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Text('Avg. Value', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthCard(String month, double revenue, int count) {
    final isThisMonthDownloading = _isDownloading && _downloadingMonth == month;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(month, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('$count Bookings', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            Row(
              children: [
                Text('₹${NumberFormat('#,##0.00').format(revenue)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                const SizedBox(width: 8),
                isThisMonthDownloading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                        icon: const Icon(Icons.download, color: Colors.blue),
                        tooltip: 'Export PDF',
                        onPressed: _isDownloading ? null : () => _downloadAndOpenReport(month),
                      )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
