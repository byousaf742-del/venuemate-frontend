import 'package:flutter/material.dart';
import '../home_screen/home_screen.dart';
import './account_screen.dart';
import './bookings_screen.dart';
import './chat_screen.dart';
import './requests_screen.dart';
import './venues_screen.dart';
class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    HomeScreen(
      onNavigateToVenues: () => setState(() => _currentIndex = 1),
      onNavigateToTab: (i) => setState(() => _currentIndex = i),
    ),
    CustomerVenuesScreen(),
    CustomerBookingsScreen(),
    CustomerRequestsScreen(),
    CustomerChatScreen(),
    CustomerAccountScreen(
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
    Icons.home_rounded,
    Icons.location_city_rounded,
    Icons.calendar_month_rounded,
    Icons.request_quote_rounded,
    Icons.chat_bubble_rounded,
    Icons.person_rounded,
  ];
  final List<IconData> _iconsOutlined = [
    Icons.home_outlined,
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
