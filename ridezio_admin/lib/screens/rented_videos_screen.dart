import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/providers.dart';
import '../core/constants.dart';
import '../models/booking.dart';
import '../services/api_service.dart';

import '../widgets/video_player_widget.dart';

class RentedVideosScreen extends ConsumerStatefulWidget {
  const RentedVideosScreen({super.key});

  @override
  ConsumerState<RentedVideosScreen> createState() => _RentedVideosScreenState();
}

class _RentedVideosScreenState extends ConsumerState<RentedVideosScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider(const {}));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rented Bike Videos', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: 'Pending Upload'),
            Tab(text: 'Uploaded'),
          ],
        ),
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (bookings) {
          final pending = bookings.where((b) => b.returnVideoPath == null && b.status.toLowerCase() != 'cancelled').toList();
          final uploaded = bookings.where((b) => b.returnVideoPath != null && b.status.toLowerCase() != 'cancelled').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(pending, isUploaded: false),
              _buildList(uploaded, isUploaded: true),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Booking> bookings, {required bool isUploaded}) {
    if (bookings.isEmpty) {
      return const Center(child: Text('No bookings found.'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(bookingsProvider(const {}).future),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(booking.customerName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isUploaded ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: (isUploaded ? AppColors.success : AppColors.warning).withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          isUploaded ? 'UPLOADED' : 'PENDING',
                          style: TextStyle(color: isUploaded ? AppColors.success : AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(booking.vehicleName ?? 'Unknown Vehicle', style: TextStyle(color: AppColors.textSecondary)),
                  const Divider(),
                  if (isUploaded && booking.returnVideoPath != null) ...[
                    const SizedBox(height: 8),
                    VideoPlayerWidget(videoUrl: '${ApiConstants.baseUrl.replaceAll('/api', '')}/storage/${booking.returnVideoPath}'),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: OutlinedButton(
                      onPressed: () => _showVideoUploadBottomSheet(context, booking),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isUploaded ? Colors.grey : Colors.blue.shade700, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_camera_back, color: isUploaded ? Colors.grey : Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            isUploaded ? 'Re-upload Video' : 'Upload Return Video',
                            style: TextStyle(color: isUploaded ? Colors.grey : Colors.blue.shade700, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showVideoUploadBottomSheet(BuildContext context, Booking booking) async {
    final ImagePicker picker = ImagePicker();
    
    final XFile? video = await showModalBottomSheet<XFile>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Record Video with Camera'),
              onTap: () async {
                final picked = await picker.pickVideo(source: ImageSource.camera);
                if (context.mounted) Navigator.pop(context, picked);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose Video from Gallery'),
              onTap: () async {
                final picked = await picker.pickVideo(source: ImageSource.gallery);
                if (context.mounted) Navigator.pop(context, picked);
              },
            ),
          ],
        ),
      ),
    );

    if (video == null) return;

    if (!mounted) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Uploading video... Please wait"),
            ],
          ),
        ),
      );
      
      await ref.read(apiServiceProvider).uploadReturnVideo(booking.id, video.path);
      ref.refresh(bookingsProvider(const {}).future);
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video uploaded successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    }
  }
}
