import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/dashboard_stats.dart';
import '../models/booking.dart';
import '../models/customer.dart';
import '../models/vehicle.dart';
import '../models/borrow.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStateNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setAuth(bool val) => state = val;
}

final authStateProvider = NotifierProvider<AuthStateNotifier, bool>(AuthStateNotifier.new);

final authCheckProvider = FutureProvider<bool>((ref) async {
  // Add a 3-second delay to show the beautiful Splash Screen
  await Future.delayed(const Duration(seconds: 3));
  
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      ref.read(authStateProvider.notifier).setAuth(true);
      return true;
    }
  } catch (e) {
    debugPrint('Auth Check Error: $e');
  }
  return false;
});

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getDashboardStats();
});

final customersProvider = FutureProvider.family<List<Customer>, Map<String, String>>((ref, filters) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getCustomers(filters);
});

final bookingsProvider = FutureProvider.family<List<Booking>, Map<String, String>>((ref, filters) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getBookings(filters);
});

final vehiclesProvider = FutureProvider.family<List<Vehicle>, Map<String, String>>((ref, filters) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getVehicles(filters);
});

final borrowsProvider = FutureProvider.family<List<Borrow>, Map<String, String>>((ref, filters) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getBorrows(filters);
});
