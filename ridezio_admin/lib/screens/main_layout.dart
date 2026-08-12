import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'bookings_screen.dart';

import 'calendar_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const CalendarScreen(),
    const BookingsScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Calendar',
    'Bookings',
  ];

  void _onMenuSelect(int index) {
    setState(() {
      _currentIndex = index;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Return the screen directly because DashboardScreen, CalendarScreen, etc.,
    // already have their own Scaffolds, AppBars, and Drawers.
    return _screens[_currentIndex];
  }
}
