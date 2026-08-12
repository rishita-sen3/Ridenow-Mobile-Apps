import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/api_client.dart';

final notificationsProvider = StreamProvider.autoDispose<List<dynamic>>((ref) async* {
  while (true) {
    try {
      final response = await ApiClient.get('/user/notifications');
      yield response as List<dynamic>;
    } catch (e) {
      // Ignore polling errors
    }
    await Future.delayed(const Duration(seconds: 5)); // Real-time polling every 5s
  }
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No new notifications', style: GoogleFonts.inter(fontSize: 18, color: Colors.black54)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final note = notifications[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.notifications, color: Colors.white),
                  ),
                  title: Text(note['title'] ?? 'Notification', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  subtitle: Text(note['message'] ?? '', style: GoogleFonts.inter()),
                  trailing: Text(note['created_at'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
