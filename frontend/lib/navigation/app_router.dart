import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';

class AppRouter {
  AppRouter._();

  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';

  static GoRouter router(BuildContext context) {
    return GoRouter(
      initialLocation: home,
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final isAuth = auth.isAuthenticated;
        final isOnAuthPage =
            state.matchedLocation == login || state.matchedLocation == register;

        // Still resolving auth state
        if (auth.status == AuthStatus.unknown) return null;

        // Not logged in and not on auth page → send to login
        if (!isAuth && !isOnAuthPage) return login;

        // Logged in but on auth page → send home
        if (isAuth && isOnAuthPage) return home;

        return null;
      },
      refreshListenable: _AuthNotifier(context),
      routes: [
        GoRoute(
          path: home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: register,
          builder: (context, state) => const RegisterScreen(),
        ),
      ],
    );
  }
}

/// Bridges AuthProvider.notifyListeners() → GoRouter refresh.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(BuildContext context) {
    context.read<AuthProvider>().addListener(notifyListeners);
  }
}
