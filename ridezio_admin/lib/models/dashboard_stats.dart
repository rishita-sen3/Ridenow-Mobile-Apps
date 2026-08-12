import 'booking.dart';

class DashboardStats {
  final Map<String, dynamic> kpi;
  final List<Booking> recentBookings;
  final String adminName;

  DashboardStats({
    required this.kpi,
    required this.recentBookings,
    required this.adminName,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      adminName: json['user']['first_name'] ?? 'Admin',
      kpi: json['kpi'] ?? {},
      recentBookings: (json['recent_bookings'] as List<dynamic>?)
              ?.map((e) => Booking.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
