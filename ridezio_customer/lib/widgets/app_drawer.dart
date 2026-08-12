import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/providers.dart';

import '../screens/shops_screen.dart';
import '../screens/my_bookings_screen.dart';
import '../screens/kyc_screen.dart';
import '../screens/invoices_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/wishlist_screen.dart';
import '../screens/reviews_screen.dart';
import '../screens/locations_screen.dart';
import '../screens/how_it_works_screen.dart';
import '../screens/about_us_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDanger ? Colors.red : Colors.black87),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDanger ? Colors.red : Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authStateProvider);

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20),
            color: const Color(0xFF212529),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', height: 36),
                const SizedBox(width: 12),
                Text(
                  'Ridezio',
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.0,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [

                
                if (isAuthenticated) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('DASHBOARD', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  _buildDrawerItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Overview',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.list_alt_rounded,
                    title: 'My Bookings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.add_circle_outline,
                    title: 'Book a Ride',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopsScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.verified_user_rounded,
                    title: 'KYC Status',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const KycScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.receipt_long_rounded,
                    title: 'Invoices',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoicesScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.favorite_border_rounded,
                    title: 'Wishlist',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.star_border_rounded,
                    title: 'Reviews',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsScreen()));
                    },
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('DISCOVER', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  _buildDrawerItem(
                    icon: Icons.location_on_rounded,
                    title: 'Locations',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationsScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline_rounded,
                    title: 'How It Works',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HowItWorksScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.info_outline_rounded,
                    title: 'About Us',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutUsScreen()));
                    },
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    isDanger: true,
                    onTap: () async {
                      await ref.read(authStateProvider.notifier).logout();
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
