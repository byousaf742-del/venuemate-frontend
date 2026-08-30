import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_venues_screen.dart';
import 'admin_users_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_account_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    AdminDashboardScreen(
      onNavigateToVenues: () => setState(() => _currentIndex = 1),
      onNavigateToUsers: () => setState(() => _currentIndex = 2),
      onNavigateToBookings: () => setState(() => _currentIndex = 3),
    ),
    const AdminVenuesScreen(),
    const AdminUsersScreen(),
    const AdminBookingsScreen(),
    const AdminAccountScreen(),
  ];
  final List<String> _labels = [
    'Dashboard', 'Venues', 'Users', 'Bookings', 'Account',
  ];
  final List<IconData> _icons = [
    Icons.dashboard_rounded,
    Icons.location_city_rounded,
    Icons.people_rounded,
    Icons.calendar_month_rounded,
    Icons.person_rounded,
  ];
  final List<IconData> _iconsOutlined = [
    Icons.dashboard_outlined,
    Icons.location_city_outlined,
    Icons.people_outline_rounded,
    Icons.calendar_month_outlined,
    Icons.person_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        animationDuration: const Duration(milliseconds: 250),
        destinations: List.generate(
          _labels.length,
          (i) => NavigationDestination(
            icon: Icon(_iconsOutlined[i]),
            selectedIcon: Icon(_icons[i]),
            label: _labels[i],
          ),
        ),
      ),
    );
  }
}
