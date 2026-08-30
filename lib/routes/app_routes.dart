import 'package:flutter/material.dart';

import '../presentation/home_screen/home_screen.dart';
import '../presentation/owner_dashboard_screen/owner_dashboard_screen.dart';
import '../presentation/sign_up_login_screen/sign_up_login_screen.dart';
import '../presentation/customer/customer_main_screen.dart';
import '../presentation/owner/owner_main_screen.dart';
import '../presentation/admin/admin_main_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splash = '/splash';
  static const String homeScreen = '/home-screen';
  static const String signUpLoginScreen = '/sign-up-login-screen';
  static const String ownerDashboardScreen = '/owner-dashboard-screen';
  static const String customerMainScreen = '/customer-main-screen';
  static const String ownerMainScreen = '/owner-main-screen';
  static const String adminMainScreen = '/admin-main-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SignUpLoginScreen(),
    homeScreen: (context) => const HomeScreen(),
    signUpLoginScreen: (context) => const SignUpLoginScreen(),
    ownerDashboardScreen: (context) => const OwnerDashboardScreen(),
    ownerMainScreen: (context) => const OwnerMainScreen(),
    customerMainScreen: (context) => const CustomerMainScreen(),
    adminMainScreen: (context) => const AdminMainScreen(),
  };

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    final builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(builder: builder, settings: settings);
    }
    return null;
  }
}
