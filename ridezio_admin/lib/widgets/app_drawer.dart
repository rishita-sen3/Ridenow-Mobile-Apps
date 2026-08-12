import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../core/providers.dart';

class AppDrawer extends ConsumerWidget {
  final Function(int)? onSelect;
  const AppDrawer({super.key, this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.white),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo.png', height: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Ridezio',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
          _buildItem(Icons.dashboard, 'Dashboard', onTap: () { onSelect?.call(0); }),
          _buildItem(Icons.calendar_month, 'Calendar', onTap: () { onSelect?.call(1); }),
          _buildItem(Icons.list_alt, 'Bookings', onTap: () { onSelect?.call(2); }),
          _buildItem(Icons.directions_car, 'Vehicles', onTap: () {}),
          _buildItem(Icons.people, 'Customers', onTap: () {}),
          _buildItem(Icons.payment, 'Payments', onTap: () {}),
          _buildItem(Icons.star, 'Reviews', onTap: () {}),
          _buildItem(Icons.bar_chart, 'Reports', onTap: () {}),
          _buildItem(Icons.settings, 'Settings', onTap: () {}),
          const Spacer(),
          const Divider(),
          _buildItem(Icons.logout, 'Logout', onTap: () async {
            await ref.read(apiServiceProvider).logout();
            ref.read(authStateProvider.notifier).setAuth(false);
          }, color: Colors.red),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String title, {required VoidCallback onTap, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black54),
      title: Text(title, style: TextStyle(color: color ?? Colors.black87, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
