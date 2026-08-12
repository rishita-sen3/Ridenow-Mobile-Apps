import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/dashboard_stats.dart';
import '../models/booking.dart';
import '../models/customer.dart';
import '../models/vehicle.dart';
import '../models/borrow.dart';
import '../models/campaign.dart';
import 'package:shared_preferences/shared_preferences.dart';

final apiClientProvider = Provider((ref) => ApiClient());
final apiServiceProvider = Provider((ref) => ApiService(ref.read(apiClientProvider)));

class ApiService {
  final ApiClient _client;

  ApiService(this._client);

  Future<String?> login(String email, String password) async {
    try {
      final response = await _client.post(ApiConstants.login, body: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['data']['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        return null;
      }
      return 'API Error ${response.statusCode}: ${response.body}';
    } catch (e) {
      return 'Network Error: $e';
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await _client.post(ApiConstants.register, body: {
        'name': name,
        'email': email,
        'password': password,
        'role': 'shop_admin', // Register as shop admin so they can use dashboard
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['data']['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> loginWithGoogle(String idToken, String role) async {
    try {
      final response = await _client.post('${ApiConstants.baseUrl}/auth/google/app', body: {
        'id_token': idToken,
        'role': role,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['data']['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        return null; // success
      }
      return 'API Error ${response.statusCode}: ${response.body}';
    } catch (e) {
      return 'Network Error: $e';
    }
  }
  
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<DashboardStats> getDashboardStats() async {
    final response = await _client.get(ApiConstants.dashboardStats);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return DashboardStats.fromJson(data['data']);
    } else {
      throw Exception('Failed to load dashboard stats');
    }
  }

  Future<List<Customer>> getCustomers([Map<String, String>? filters]) async {
    String url = '${ApiConstants.baseUrl}/admin/customers';
    if (filters != null && filters.isNotEmpty) {
      url += '?${Uri(queryParameters: filters).query}';
    }
    
    final response = await _client.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List customersList = data['data']['data'] ?? [];
      return customersList.map((e) => Customer.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load customers');
    }
  }

  Future<bool> addCustomer(Map<String, dynamic> customerData) async {
    final response = await _client.post('${ApiConstants.baseUrl}/admin/customers', body: customerData);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to add customer');
    }
  }

  Future<bool> updateCustomer(int id, Map<String, dynamic> customerData) async {
    final response = await _client.put('${ApiConstants.baseUrl}/admin/customers/$id', body: customerData);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to update customer');
    }
  }

  Future<bool> deleteCustomer(int id) async {
    final response = await _client.delete('${ApiConstants.baseUrl}/admin/customers/$id');
    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to delete customer');
    }
  }

  Future<List<Booking>> getBookings([Map<String, String>? filters]) async {
    String url = '${ApiConstants.baseUrl}/admin/bookings';
    if (filters != null && filters.isNotEmpty) {
      url += '?${Uri(queryParameters: filters).query}';
    }
    
    final response = await _client.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> bookingsJson = data['data'] ?? [];
      return bookingsJson.map((json) => Booking.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load bookings');
    }
  }

  Future<Booking> extendBooking(int bookingId, String newEndDatetime) async {
    final response = await _client.patch('${ApiConstants.baseUrl}/admin/bookings/$bookingId/extend', body: {
      'end_datetime': newEndDatetime,
    });
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return Booking.fromJson(jsonResponse['booking'] ?? jsonResponse['data']);
    } else {
      throw Exception('Failed to extend booking');
    }
  }

  Future<Booking> recordPayment(int bookingId, num amount, String mode) async {
    final response = await _client.patch('${ApiConstants.baseUrl}/admin/bookings/$bookingId/payment', body: {
      'amount': amount.toString(),
      'payment_mode': mode,
    });
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return Booking.fromJson(jsonResponse['booking'] ?? jsonResponse['data']);
    } else {
      throw Exception('Failed to record payment');
    }
  }

  Future<Map<String, dynamic>> generatePaymentLink(int bookingId) async {
    final response = await _client.post('${ApiConstants.baseUrl}/admin/bookings/$bookingId/payment-link');
    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['status'] == 'success') {
      return data;
    }
    throw Exception(data['message'] ?? 'Failed to generate payment link');
  }

  Future<Map<String, dynamic>> checkPaymentStatus(int bookingId) async {
    final response = await _client.post('${ApiConstants.baseUrl}/admin/bookings/$bookingId/check-payment');
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data;
    }
    throw Exception(data['message'] ?? 'Failed to check payment status');
  }

  Future<Booking> uploadReturnVideo(int bookingId, String videoPath) async {
    final response = await _client.multipartRequest(
      '${ApiConstants.baseUrl}/admin/bookings/$bookingId/video',
      method: 'POST',
      fileField: 'return_video',
      filePath: videoPath,
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return Booking.fromJson(jsonResponse['booking'] ?? jsonResponse['data']);
    } else {
      throw Exception('Failed to upload video: ${response.body}');
    }
  }

  Future<List<Vehicle>> getVehicles([Map<String, String>? filters]) async {
    String url = '${ApiConstants.baseUrl}/admin/vehicles';
    if (filters != null && filters.isNotEmpty) {
      url += '?${Uri(queryParameters: filters).query}';
    }
    
    final response = await _client.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> vehiclesJson = data['data'] ?? [];
      return vehiclesJson.map((json) => Vehicle.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load vehicles');
    }
  }

  Future<bool> addVehicle(Map<String, dynamic> vehicleData, {String? imagePath}) async {
    final Map<String, String> stringFields = {};
    vehicleData.forEach((key, value) {
      if (value != null) {
        stringFields[key] = value.toString();
      }
    });

    final response = await _client.multipartRequest(
      '${ApiConstants.baseUrl}/admin/vehicles',
      method: 'POST',
      fields: stringFields,
      fileField: 'bike_image',
      filePath: imagePath,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to add vehicle');
    }
  }

  Future<bool> updateVehicle(int id, Map<String, dynamic> vehicleData, {String? imagePath}) async {
    final Map<String, String> stringFields = {};
    vehicleData.forEach((key, value) {
      if (value != null) {
        stringFields[key] = value.toString();
      }
    });

    // Laravel uses POST with _method=PUT to parse multipart/form-data correctly
    stringFields['_method'] = 'PUT';

    final response = await _client.multipartRequest(
      '${ApiConstants.baseUrl}/admin/vehicles/$id',
      method: 'POST',
      fields: stringFields,
      fileField: 'bike_image',
      filePath: imagePath,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to update vehicle');
    }
  }

  Future<bool> deleteVehicle(int id) async {
    final response = await _client.delete('${ApiConstants.baseUrl}/admin/vehicles/$id');
    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to delete vehicle');
    }
  }

  // Operations: Handover
  Future<Booking> processHandover(int bookingId, String? helmetNumber, String? preRideNotes) async {
    final response = await _client.post('${ApiConstants.baseUrl}/admin/operations/handover/$bookingId', body: {
      'helmet_number': ?helmetNumber,
      'pre_ride_notes': ?preRideNotes,
    });
    
    final data = jsonDecode(response.body);
    if (data['status'] == 'success') {
      return Booking.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to process handover');
  }

  // Operations: Return
  Future<Booking> processReturn(int bookingId, num damageCharges, String? postRideNotes) async {
    final response = await _client.post('${ApiConstants.baseUrl}/admin/operations/return/$bookingId', body: {
      'damage_charges': damageCharges.toString(),
      'post_ride_notes': ?postRideNotes,
    });
    
    final data = jsonDecode(response.body);
    if (data['status'] == 'success') {
      return Booking.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to process return');
  }

  Future<List<Borrow>> getBorrows(Map<String, String> queryParams) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/admin/borrows').replace(queryParameters: queryParams);
    final response = await _client.get(uri.toString());
    final data = jsonDecode(response.body);
    if (data['status'] == 'success') {
      final List items = data['data']['data'] ?? data['data'] ?? [];
      return items.map((e) => Borrow.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to load borrows');
  }

  Future<Borrow> createBorrow(Map<String, dynamic> borrowData) async {
    final response = await _client.post('${ApiConstants.baseUrl}/admin/borrows', body: borrowData);
    final data = jsonDecode(response.body);
    if (data['status'] == 'success') {
      return Borrow.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to create borrow record');
  }

  Future<Borrow> updateBorrowStatus(int borrowId, String status) async {
    final response = await _client.patch('${ApiConstants.baseUrl}/admin/borrows/$borrowId/status', body: {
      'status': status,
    });
    final data = jsonDecode(response.body);
    if (data['status'] == 'success') {
      return Borrow.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to update borrow status');
  }

  Future<Borrow> recordBorrowPayment(int borrowId, num amount, String mode) async {
    final response = await _client.patch('${ApiConstants.baseUrl}/admin/borrows/$borrowId/payment', body: {
      'amount': amount.toString(),
      'payment_method': mode,
    });
    final data = jsonDecode(response.body);
    if (data['message'] == 'Payment recorded successfully' || data['status'] == 'success') {
      return Borrow.fromJson(data['data'] ?? data['borrow']);
    }
    throw Exception(data['message'] ?? 'Failed to record borrow payment');
  }

  Future<List<int>> downloadReport(String month) async {
    final response = await _client.get('${ApiConstants.baseUrl}/admin/reports/export/$month');
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception('Failed to download report');
  }

  Future<List<Campaign>> getCampaigns() async {
    final response = await _client.get('${ApiConstants.baseUrl}/admin/campaigns');
    final data = jsonDecode(response.body);
    if (data['status'] == 'success') {
      final List items = data['data'] ?? [];
      return items.map((e) => Campaign.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to load campaigns');
  }

  Future<Campaign> createCampaign(Map<String, dynamic> campaignData) async {
    final response = await _client.post('${ApiConstants.baseUrl}/admin/campaigns', body: campaignData);
    final data = jsonDecode(response.body);
    if (data['status'] == 'success') {
      return Campaign.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to create campaign');
  }

  Future<void> deleteCampaign(int id) async {
    final response = await _client.delete('${ApiConstants.baseUrl}/admin/campaigns/$id');
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete campaign');
    }
  }

  // Settings
  Future<Map<String, dynamic>> getSettings() async {
    final response = await _client.get('${ApiConstants.baseUrl}/admin/settings');
    final data = jsonDecode(response.body);
    if (data['status'] == 'success') return data['data'];
    throw Exception(data['message'] ?? 'Failed to fetch settings');
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> data) async {
    final response = await _client.put('${ApiConstants.baseUrl}/admin/settings', body: data);
    final jsonResponse = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return jsonResponse;
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to update settings');
    }
  }

  Future<Map<String, dynamic>> getBookingPolicy() async {
    final response = await _client.get('${ApiConstants.baseUrl}/admin/booking-policies');
    final jsonResponse = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return jsonResponse['data'] ?? {};
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to load booking policy');
    }
  }

  Future<Map<String, dynamic>> updateBookingPolicy(Map<String, dynamic> data) async {
    final response = await _client.post('${ApiConstants.baseUrl}/admin/booking-policies', body: data);
    final jsonResponse = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return jsonResponse['data'] ?? {};
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to update booking policy');
    }
  }

  // Subscriptions
  Future<Map<String, dynamic>> getSubscriptionDetails() async {
    final response = await _client.get('${ApiConstants.baseUrl}/admin/subscriptions');
    final data = jsonDecode(response.body);
    if (data['status'] == 'success') return data['data'];
    throw Exception(data['message'] ?? 'Failed to fetch subscriptions');
  }

  Future<Map<String, dynamic>> purchaseSubscription(int planId, String duration) async {
    final response = await _client.post('${ApiConstants.baseUrl}/admin/subscriptions/purchase', body: {
      'plan_id': planId,
      'duration': duration,
    });
    final data = jsonDecode(response.body);
    if (data['status'] == 'success') return data['data'];
    throw Exception(data['message'] ?? 'Failed to initiate purchase');
  }

  Future<void> verifySubscription(String orderId) async {
    final response = await _client.post('${ApiConstants.baseUrl}/admin/subscriptions/verify', body: {'order_id': orderId});
    final data = jsonDecode(response.body);
    if (data['status'] == 'error') throw Exception(data['message']);
    if (data['status'] == 'pending') throw Exception('Payment is still pending');
  }

  // Premium Addons
  Future<Map<String, dynamic>> getPremiumAddons() async {
    final response = await _client.get('${ApiConstants.baseUrl}/admin/premium-addons');
    final data = jsonDecode(response.body);
    if (data['status'] == 'success') return data['data'];
    throw Exception(data['message'] ?? 'Failed to fetch premium addons');
  }

  Future<Map<String, dynamic>> purchasePremiumAddon(int addonId) async {
    final response = await _client.post('${ApiConstants.baseUrl}/admin/premium-addons/purchase', body: {'addon_id': addonId});
    final data = jsonDecode(response.body);
    if (data['status'] == 'success') return data['data'];
    throw Exception(data['message'] ?? 'Failed to initiate purchase');
  }

  Future<void> verifyPremiumAddon(String orderId) async {
    final response = await _client.post('${ApiConstants.baseUrl}/admin/premium-addons/verify', body: {'order_id': orderId});
    final data = jsonDecode(response.body);
    if (data['status'] == 'error') throw Exception(data['message']);
    if (data['status'] == 'pending') throw Exception('Payment is still pending');
  }
}
