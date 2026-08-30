import 'package:flutter/material.dart';
import '../owner_dashboard_screen/owner_dashboard_screen.dart';
import './owner_account_screen.dart';
import './owner_bookings_screen.dart';
import './owner_chat_screen.dart';
import './owner_requests_screen.dart';
import './owner_venues_screen.dart';

class OwnerMainScreen extends StatefulWidget {
  const OwnerMainScreen({super.key});

  @override
  State<OwnerMainScreen> createState() => _OwnerMainScreenState();
}

class _OwnerMainScreenState extends State<OwnerMainScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    OwnerDashboardScreen(
      onNavigateToTab: (i) => setState(() => _currentIndex = i),
    ),
    OwnerVenuesScreen(),
    OwnerBookingsScreen(),
    OwnerRequestsScreen(),
    OwnerChatScreen(),
    OwnerAccountScreen(
      onNavigateToTab: (i) => setState(() => _currentIndex = i),
    ),
  ];

  final List<String> _labels = [
    'Home',
    'Venues',
    'Bookings',
    'Requests',
    'Chat',
    'Account',
  ];
  final List<IconData> _icons = [
    Icons.dashboard_rounded,
    Icons.location_city_rounded,
    Icons.calendar_month_rounded,
    Icons.request_quote_rounded,
    Icons.chat_bubble_rounded,
    Icons.person_rounded,
  ];
  final List<IconData> _iconsOutlined = [
    Icons.dashboard_outlined,
    Icons.location_city_outlined,
    Icons.calendar_month_outlined,
    Icons.request_quote_outlined,
    Icons.chat_bubble_outline_rounded,
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
