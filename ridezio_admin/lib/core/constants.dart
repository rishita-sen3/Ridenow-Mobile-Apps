import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF000000); // Or the primary color of the web
  static const Color background = Color(0xFFF3F4F6); // Light gray background
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color cardDark = Color(0xFF1F2937); // Dark revenue card
  
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}

class ApiConstants {
  // Using local tunnel over ADB
  static const String baseUrl = 'https://ridezio.in/api';
  static const String login = '$baseUrl/login';
  static const String register = '$baseUrl/register';
  static const String dashboardStats = '$baseUrl/admin/dashboard-stats';
  static const String bookings = '$baseUrl/admin/bookings';
}
