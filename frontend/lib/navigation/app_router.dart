import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/member_preferences_screen.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String addMember = '/add-member';

  /// Creates a [GoRouter] once — pass [authProvider] directly so the router
  /// never needs to be recreated when auth state changes.
  static GoRouter create(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: splash,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final status = authProvider.status;
        final isAuth = authProvider.isAuthenticated;
        final loc = state.matchedLocation;
        final isOnAuthPage = loc == login || loc == register;

        // Still waiting for Firebase to resolve auth state → show splash
        if (status == AuthStatus.unknown) {
          return loc == splash ? null : splash;
        }
        // Auth resolved
        if (!isAuth && !isOnAuthPage) return login;
        if (isAuth && isOnAuthPage) return home;
        if (loc == splash) return isAuth ? home : login;
        return null;
      },
      routes: [
        GoRoute(path: splash, builder: (_, __) => const _SplashScreen()),
        GoRoute(path: home, builder: (_, __) => const HomeScreen()),
        GoRoute(path: login, builder: (_, __) => const LoginScreen()),
        GoRoute(path: register, builder: (_, __) => const RegisterScreen()),
        GoRoute(
          path: addMember,
          builder: (_, __) => const MemberPreferencesScreen(),
        ),
      ],
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: Colors.green),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}
