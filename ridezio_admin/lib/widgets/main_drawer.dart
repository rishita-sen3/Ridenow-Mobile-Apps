import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../services/api_service.dart';
import '../screens/dashboard_screen.dart';
import '../screens/bookings_screen.dart';
import '../screens/customers/customers_screen.dart';
import '../screens/customers/add_customer_screen.dart';
import '../screens/vehicles/vehicles_screen.dart';
import '../screens/vehicles/add_vehicle_screen.dart';
import '../screens/payment_verification_screen.dart';
import '../screens/rented_videos_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/borrows_screen.dart';
import '../screens/borrow_create_screen.dart';
import '../screens/borrow_payments_screen.dart';
import '../screens/maintenance_screen.dart';
import '../screens/marketing_screen.dart';
import '../screens/payments_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/operations_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/premium_screen.dart';

// Placeholder screen for all the unimplemented items right now
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title Screen (Coming Soon)')),
    );
  }
}

class MainDrawer extends ConsumerStatefulWidget {
  const MainDrawer({super.key});

  @override
  ConsumerState<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends ConsumerState<MainDrawer> {
  // To track which item is selected
  final String _selectedRoute = 'Dashboard';

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1a1c23), // Dark blackish background from web
      child: Column(
        children: [
          // Header with Close Button
          Container(
            padding: const EdgeInsets.only(top: 40, bottom: 16, left: 20, right: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white12, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Scrollable Menu List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                _buildNavItem(
                  icon: Icons.grid_view,
                  title: 'Dashboard',
                  isSelected: _selectedRoute == 'Dashboard',
                  onTap: () => _navigateTo(const DashboardScreen(), 'Dashboard'),
                ),
                
                _buildExpandableItem(
                  icon: Icons.people_outline,
                  title: 'Manage Users',
                  children: [
                    _buildSubNavItem(icon: Icons.people, title: 'All Users', onTap: () => _navigateTo(const CustomersScreen(), 'All Users')),
                    _buildSubNavItem(icon: Icons.person_add_outlined, title: 'Add User', onTap: () => _navigateTo(const AddCustomerScreen(), 'Add User')),
                  ],
                ),

                _buildExpandableItem(
                  icon: Icons.directions_car_outlined,
                  title: 'Manage Vehicle',
                  children: [
                    _buildSubNavItem(icon: Icons.list_alt, title: 'All Vehicles', onTap: () => _navigateTo(const VehiclesScreen(), 'All Vehicles')),
                    _buildSubNavItem(icon: Icons.add_circle_outline, title: 'Add Vehicle', onTap: () => _navigateTo(const AddVehicleScreen(), 'Add Vehicle')),
                    _buildSubNavItem(icon: Icons.edit_outlined, title: 'Edit Vehicle', onTap: () => _navigateTo(const VehiclesScreen(), 'Edit Vehicle')), // Routes to list to select vehicle
                  ],
                ),

                _buildExpandableItem(
                  icon: Icons.calendar_today_outlined,
                  title: 'Bookings',
                  children: [
                    _buildSubNavItem(icon: Icons.list_alt, title: 'All Bookings', onTap: () => _navigateTo(const BookingsScreen(), 'All Bookings')),
                    _buildSubNavItem(icon: Icons.verified_user_outlined, title: 'Payment Verification', onTap: () => _navigateTo(const PaymentVerificationScreen(), 'Payment Verification')),
                    _buildSubNavItem(icon: Icons.videocam_outlined, title: 'Rented Bike Videos', onTap: () => _navigateTo(const RentedVideosScreen(), 'Rented Bike Videos')),
                  ],
                ),

                _buildExpandableItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'Borrowings',
                  children: [
                    _buildSubNavItem(icon: Icons.add_circle_outline, title: 'Add Borrow', onTap: () => _navigateTo(const BorrowCreateScreen(), 'Add Borrow')),
                    _buildSubNavItem(icon: Icons.list_alt, title: 'All Borrows', onTap: () => _navigateTo(const BorrowsScreen(), 'All Borrows')),
                    _buildSubNavItem(icon: Icons.payments_outlined, title: 'Payments', onTap: () => _navigateTo(const BorrowPaymentsScreen(), 'Payments')),
                  ],
                ),

                _buildNavItem(icon: Icons.calendar_month_outlined, title: 'Calendar', isSelected: _selectedRoute == 'Calendar', onTap: () => _navigateTo(const CalendarScreen(), 'Calendar')),
                _buildNavItem(icon: Icons.payment_outlined, title: 'Payments', isSelected: _selectedRoute == 'Payments', onTap: () => _navigateTo(const PaymentsScreen(), 'Payments')),
                _buildNavItem(icon: Icons.bar_chart_outlined, title: 'Reports', isSelected: _selectedRoute == 'Reports', onTap: () => _navigateTo(const ReportsScreen(), 'Reports')),
                _buildNavItem(icon: Icons.settings_applications_outlined, title: 'Operations', isSelected: _selectedRoute == 'Operations', onTap: () => _navigateTo(const OperationsScreen(), 'Operations')),
                _buildNavItem(icon: Icons.build_circle_outlined, title: 'Maintenance', isSelected: _selectedRoute == 'Maintenance', onTap: () => _navigateTo(const MaintenanceScreen(), 'Maintenance')),
                _buildNavItem(icon: Icons.campaign_outlined, title: 'Marketing', isSelected: _selectedRoute == 'Marketing', onTap: () => _navigateTo(const MarketingScreen(), 'Marketing')),
                _buildNavItem(icon: Icons.settings_outlined, title: 'Settings', isSelected: _selectedRoute == 'Settings', onTap: () => _navigateTo(const SettingsScreen(), 'Settings')),
                _buildNavItem(icon: Icons.card_membership, title: 'Subscription', isSelected: _selectedRoute == 'Subscription', onTap: () => _navigateTo(const SubscriptionScreen(), 'Subscription')),
                _buildNavItem(icon: Icons.star_border, title: 'Premium Upgrades', iconColor: Colors.amber, isSelected: _selectedRoute == 'Premium Upgrades', onTap: () => _navigateTo(const PremiumScreen(), 'Premium Upgrades')),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(color: Colors.white12, thickness: 1),
                ),
                
                _buildNavItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  isSelected: false,
                  onTap: () async {
                    await ref.read(apiServiceProvider).logout();
                    ref.read(authStateProvider.notifier).setAuth(false);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? (isSelected ? Colors.white : Colors.white70), size: 22),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableItem({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    // Check if any child is currently selected to keep it expanded
    bool isExpanded = children.any((child) {
      if (child is Padding) {
        final inner = child.child;
        if (inner is InkWell) {
          // This is a naive check. A better robust state management would be used in a full app.
          // Since we rebuild the entire drawer on navigation, it resets.
        }
      }
      return false;
    });

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        leading: Icon(icon, color: Colors.white70, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white70,
        childrenPadding: const EdgeInsets.only(left: 16, bottom: 8),
        children: children,
      ),
    );
  }

  Widget _buildSubNavItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final bool isSelected = _selectedRoute == title;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.white54, size: 18),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(Widget screen, String routeName) {
    // We don't need to setState for _selectedRoute because each screen creates a new Drawer instance anyway.
    // A proper solution would use Riverpod for the selected route, but this works for now.
    
    Navigator.pop(context); // Close drawer
    
    // Always return to root (Dashboard) first to prevent infinite stack growth
    Navigator.popUntil(context, (route) => route.isFirst);
    
    // If they selected something other than Dashboard, push it on top
    if (routeName != 'Dashboard') {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => screen,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }
}
