import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/providers.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../widgets/main_drawer.dart';
import '../widgets/stat_card.dart';
import 'customers/customers_screen.dart';
import 'bookings_screen.dart';
import 'vehicles/vehicles_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF6F6F6),
      drawer: const MainDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: 34),
            const SizedBox(width: 8),
            Text(
              'Ridezio',
              style: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -1.5),
            ),
          ],
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildVehicleIcon(Icons.directions_car, 'Car'),
                _buildVehicleIcon(Icons.two_wheeler, 'Scooter'),
                _buildVehicleIcon(Icons.pedal_bike, 'Bike'),
                _buildVehicleIcon(Icons.electric_scooter, 'EV'),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardStatsProvider.future),
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => ListView(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text('Error: $err'),
                ),
              )
            ],
          ),
          data: (stats) {
            return ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                _buildHeader(stats.adminName, ref),
                const SizedBox(height: 32),
                
                Text(
                  'Real-Time Statistics',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                ),
                const SizedBox(height: 16),
                _buildStatCards(stats.kpi),
                const SizedBox(height: 32),
                
                Text(
                  'Detailed Analytics',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                ),
                const SizedBox(height: 16),
                _buildDetailedAnalytics(stats.kpi),
                const SizedBox(height: 32),

                _buildRecentBookings(stats.recentBookings, ref),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String name, WidgetRef ref) {
    final now = DateTime.now();
    final dateFormatted = DateFormat('EEEE, MMMM d, yyyy — h:mm a').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dashboard',
              style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: const Color(0xFF212529)),
            ),
            ElevatedButton(
              onPressed: () async {
                await ref.read(apiServiceProvider).logout();
                ref.read(authStateProvider.notifier).setAuth(false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF212529),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Log out', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Welcome back, $name. Here\'s what\'s happening.',
          style: GoogleFonts.inter(color: const Color(0xFF6c757d), fontSize: 14),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 2,
                offset: const Offset(0, 1),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.black87),
              const SizedBox(width: 8),
              Text(
                dateFormatted,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards(Map<String, dynamic> kpi) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        // 1 column on small screens (<400), 2 on medium (400-800), 4 on wide (>800)
        final double itemWidth = width > 800 
            ? (width - 48) / 4  // 4 columns, 3 gaps of 16
            : (width > 400 ? (width - 16) / 2 : width); // 2 columns or 1 column
        
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: itemWidth,
              child: StatCard(
                title: 'Total Bookings',
                totalValue: kpi['total_bookings'].toString(),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen())),
                subItems: [
                  StatSubItem(label: 'Pending', value: kpi['pending_bookings'].toString(), dotColor: Colors.amber, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen(filters: {'status': 'pending'})))),
                  StatSubItem(label: 'Active', value: kpi['active_bookings'].toString(), dotColor: Colors.green, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen(filters: {'status': 'active'})))),
                  StatSubItem(label: 'Completed', value: kpi['completed_bookings'].toString(), dotColor: Colors.black, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen(filters: {'status': 'completed'})))),
                ],
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: StatCard(
                title: 'Total Users',
                totalValue: kpi['total_users'].toString(),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersScreen())),
                subItems: [
                  StatSubItem(label: 'Active', value: kpi['active_users'].toString(), dotColor: Colors.green, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersScreen(filters: {'is_active': 'true'})))),
                  StatSubItem(label: 'New Today', value: kpi['new_users_today'].toString(), dotColor: Colors.transparent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersScreen(filters: {'date': 'today'})))),
                  StatSubItem(label: 'This Month', value: kpi['new_users_month'].toString(), dotColor: Colors.transparent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersScreen(filters: {'date': 'month'})))),
                ],
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: StatCard(
                title: 'Total Vehicles',
                totalValue: kpi['total_vehicles'].toString(),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehiclesScreen())),
                subItems: [
                  StatSubItem(label: 'Available', value: kpi['available_vehicles'].toString(), dotColor: Colors.green, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehiclesScreen(filters: {'status': 'available'})))),
                  StatSubItem(label: 'Booked', value: kpi['booked_vehicles'].toString(), dotColor: Colors.black, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehiclesScreen(filters: {'status': 'booked'})))),
                  StatSubItem(label: 'Maintenance', value: kpi['maintenance_vehicles'].toString(), dotColor: Colors.red, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehiclesScreen(filters: {'status': 'maintenance'})))),
                ],
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: StatCard(
                title: 'Total Revenue',
                totalValue: '₹${_formatNum(kpi['total_revenue'])}',
                isDark: true,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen())),
                subItems: [
                  StatSubItem(label: 'Today', value: '₹${_formatNum(kpi['revenue_today'])}', dotColor: Colors.transparent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen(filters: {'date': 'today'})))),
                  StatSubItem(label: 'This Month', value: '₹${_formatNum(kpi['revenue_month'])}', dotColor: Colors.transparent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen(filters: {'date': 'month'})))),
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildDetailedAnalytics(Map<String, dynamic> kpi) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        // Calculate dynamic width to fit 4 on desktop, 2 on mobile
        final double itemWidth = width > 800 
            ? (width - 48) / 4  // 4 columns, 3 gaps of 16
            : (width - 16) / 2; // 2 columns, 1 gap of 16
            
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(width: itemWidth, child: _buildSimpleCard('Gross Revenue', '₹${_formatNum(kpi['total_revenue'])}', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen())))),
            SizedBox(width: itemWidth, child: _buildSimpleCard('Net Revenue', '₹${_formatNum(kpi['net_revenue'])}', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen())))),
            SizedBox(width: itemWidth, child: _buildSimpleCard('Pending Payments', kpi['pending_payments'].toString(), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen(filters: {'payment_status': 'pending'}))))),
            SizedBox(width: itemWidth, child: _buildSimpleCard('Overdue Payments', kpi['overdue_payments'].toString())),
            SizedBox(width: itemWidth, child: _buildSimpleCard('Cancelled Bookings', kpi['cancelled_bookings'].toString(), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen(filters: {'status': 'cancelled'}))))),
            SizedBox(width: itemWidth, child: _buildSimpleCard('Average Rating', '★ ${kpi['avg_rating']}')),
            SizedBox(width: itemWidth, child: _buildSimpleCard('Booking Success Rate', '${kpi['booking_success_rate']}%')),
            SizedBox(width: itemWidth, child: _buildSimpleCard('Revenue Growth (MoM)', '${kpi['revenue_growth']}%')),
          ],
        );
      }
    );
  }

  Widget _buildSimpleCard(String title, String value, {VoidCallback? onTap}) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6c757d),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF212529),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentBookings(List<Booking> bookings, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Bookings',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                    color: const Color(0xFF212529),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F1F1)),
          
          if (bookings.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'No recent bookings found.',
                style: GoogleFonts.inter(color: const Color(0xFF6c757d)),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6c757d),
                  letterSpacing: 0.5,
                ),
                dataTextStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF212529),
                ),
                dividerThickness: 1,
                columns: const [
                  DataColumn(label: Text('CUSTOMER NAME')),
                  DataColumn(label: Text('BIKE NAME')),
                  DataColumn(label: Text('PRICE')),
                  DataColumn(label: Text('DATE & TIME')),
                  DataColumn(label: Text('STATUS')),
                ],
                rows: bookings.map((booking) {
                  return DataRow(
                    cells: [
                      DataCell(Text(booking.customerName ?? 'Guest', style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(booking.vehicleName ?? 'Unknown')),
                      DataCell(Text('₹${_formatNum(booking.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(
                        Text(
                          _formatDateTime(booking.startDatetime),
                          style: const TextStyle(color: Color(0xFF6c757d), fontSize: 13),
                        ),
                      ),
                      DataCell(_buildStatusBadge(booking.status)),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData? icon;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = const Color(0xFFf8f9fa);
        textColor = const Color(0xFF212529);
        icon = Icons.circle;
        break;
      case 'confirmed':
        bgColor = const Color(0xFFf8f9fa);
        textColor = const Color(0xFF212529);
        icon = Icons.circle;
        break;
      case 'active':
        bgColor = const Color(0xFF212529);
        textColor = Colors.white;
        break;
      default:
        bgColor = const Color(0xFFf8f9fa);
        textColor = const Color(0xFF6c757d);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: status.toLowerCase() != 'active' ? Colors.black12 : Colors.transparent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 8, color: status.toLowerCase() == 'pending' ? Colors.amber : Colors.blue),
            const SizedBox(width: 6),
          ],
          Text(
            status[0].toUpperCase() + status.substring(1).toLowerCase(),
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNum(dynamic number) {
    if (number == null) return '0';
    try {
      final formatter = NumberFormat('#,##0');
      if (number is num) return formatter.format(number);
      return formatter.format(double.parse(number.toString()));
    } catch (e) {
      return number.toString();
    }
  }

  String _formatDateTime(String dtString) {
    if (dtString.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dtString).toLocal();
      return DateFormat('MMM d, yyyy • h:mm a').format(dt);
    } catch (e) {
      return dtString;
    }
  }

  Widget _buildVehicleIcon(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Icon(icon, size: 22, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }
}
