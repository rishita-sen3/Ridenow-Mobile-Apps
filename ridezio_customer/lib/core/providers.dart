import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

// Authentication State
class AuthNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setAuth(bool isAuthenticated) {
    state = isAuthenticated;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    state = false;
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, bool>(() {
  return AuthNotifier();
});

// Location State
class LocationState {
  final String state;
  final String city;
  final double? lat;
  final double? lng;

  LocationState({this.state = '', this.city = '', this.lat, this.lng});
}

class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() => LocationState();

  // Reverse geocode: get city name from lat/lng using Nominatim
  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json');
      final resp = await http.get(url, headers: {'User-Agent': 'RidezioApp/1.0'}).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final address = data['address'] ?? {};
        return address['city'] ?? address['town'] ?? address['village'] ?? address['state_district'] ?? '';
      }
    } catch (_) {}
    return '';
  }

  // Forward geocode: get lat/lng from city name using Nominatim
  Future<Map<String, double>?> _geocodeCity(String cityName, String stateName) async {
    try {
      final query = Uri.encodeComponent('$cityName, $stateName, India');
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
      final resp = await http.get(url, headers: {'User-Agent': 'RidezioApp/1.0'}).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data.isNotEmpty) {
          return {
            'lat': double.tryParse(data[0]['lat'].toString()) ?? 0,
            'lng': double.tryParse(data[0]['lon'].toString()) ?? 0,
          };
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    String stateName = prefs.getString('loc_state') ?? '';
    String cityName = prefs.getString('loc_city') ?? '';
    double? lat = prefs.getDouble('loc_lat');
    double? lng = prefs.getDouble('loc_lng');

    // Try to get GPS location
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable them in your device settings.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable them in settings.');
      }
      
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        lat = position.latitude;
        lng = position.longitude;
        await prefs.setDouble('loc_lat', lat);
        await prefs.setDouble('loc_lng', lng);
        // Reverse geocode to get city name
        final detectedCity = await _reverseGeocode(lat, lng);
        if (detectedCity.isNotEmpty) {
          cityName = detectedCity;
          await prefs.setString('loc_city', cityName);
        } else if (cityName.isEmpty) {
          cityName = 'Current Location';
          await prefs.setString('loc_city', cityName);
        }
      }
    } catch (e) {
      // Re-throw so the UI can catch it
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }

    state = LocationState(state: stateName, city: cityName, lat: lat, lng: lng);
  }

  Future<void> setLocation(String stateName, String cityName, double lat, double lng) async {
    double finalLat = lat;
    double finalLng = lng;
    // If lat/lng are 0 (missing from json), geocode the city
    if (lat == 0.0 && lng == 0.0) {
      final coords = await _geocodeCity(cityName, stateName);
      if (coords != null) {
        finalLat = coords['lat']!;
        finalLng = coords['lng']!;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loc_state', stateName);
    await prefs.setString('loc_city', cityName);
    await prefs.setDouble('loc_lat', finalLat);
    await prefs.setDouble('loc_lng', finalLng);
    state = LocationState(state: stateName, city: cityName, lat: finalLat == 0 ? null : finalLat, lng: finalLng == 0 ? null : finalLng);
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(() {
  return LocationNotifier();
});

final authCheckProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  if (token != null) {
    ref.read(authStateProvider.notifier).setAuth(true);
    return true;
  }
  return false;
});

// User Dashboard Data
final dashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await ApiClient.get('/user/dashboard');
});

final exploreProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await ApiClient.get('/explore');
});

// User Profile Data
final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await ApiClient.get('/user/profile');
});

// Bookings
final bookingsProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await ApiClient.get('/user/bookings');
  return response['data'] ?? [];
});

// Public APIs
final shopsProvider = FutureProvider<List<dynamic>>((ref) async {
  return await ApiClient.get('/shops');
});

final shopDetailsProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, shopId) async {
  return await ApiClient.get('/shops/$shopId');
});

final vehiclesProvider = FutureProvider<List<dynamic>>((ref) async {
  final loc = ref.watch(locationProvider);
  String endpoint = '/vehicles';
  if (loc.lat != null && loc.lng != null) {
    endpoint += '?lat=${loc.lat}&lng=${loc.lng}&radius=20';
  }
  final response = await ApiClient.get(endpoint);
  return response['data'] ?? [];
});

final offersProvider = FutureProvider<List<dynamic>>((ref) async {
  return await ApiClient.get('/offers');
});

final locationsProvider = FutureProvider<List<dynamic>>((ref) async {
  return await ApiClient.get('/locations');
});
