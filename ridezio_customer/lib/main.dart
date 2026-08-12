import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/providers.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const ProviderScope(child: UserApp()));
}

class UserApp extends ConsumerStatefulWidget {
  const UserApp({super.key});

  @override
  ConsumerState<UserApp> createState() => _UserAppState();
}

class _UserAppState extends ConsumerState<UserApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider.notifier).loadLocation();
    });
  }

  Future<void> _checkForUpdates() async {
    try {
      final response = await http.get(Uri.parse('https://ridezio.in/api/app-version'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['latest_version'] as String;
        final downloadUrl = data['download_url'] as String;
        final forceUpdate = data['force_update'] as bool;

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isUpdateAvailable(currentVersion, latestVersion)) {
          _showUpdateDialog(latestVersion, downloadUrl, forceUpdate);
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  bool _isUpdateAvailable(String current, String latest) {
    List<int> currParts = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    List<int> latestParts = latest.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      int curr = i < currParts.length ? currParts[i] : 0;
      int lat = i < latestParts.length ? latestParts[i] : 0;
      if (lat > curr) return true;
      if (lat < curr) return false;
    }
    return false;
  }

  void _showUpdateDialog(String version, String url, bool force) {
    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: !force,
      builder: (context) {
        return PopScope(
          canPop: !force,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.system_update_alt, color: Color(0xFF212529)),
                const SizedBox(width: 8),
                Text('Update Available', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
            content: Text(
              'A new version ($version) of Ridezio is available. Please update for the latest features and improvements.',
              style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 14),
            ),
            actions: [
              if (!force)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Later', style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                ),
              ElevatedButton(
                onPressed: () async {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE2F4C5),
                  foregroundColor: const Color(0xFF212529),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Update Now', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authCheck = ref.watch(authCheckProvider);
    final isAuthenticated = ref.watch(authStateProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Ridezio User',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authCheck.when(
        data: (_) => isAuthenticated ? const MainNavigationScreen() : const LoginScreen(),
        loading: () => Scaffold(
          backgroundColor: const Color(0xFF212529),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Ridezio',
                  style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rent, Ride & Explore',
                  style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
        error: (_, _) => const LoginScreen(),
      ),
    );
  }
}
