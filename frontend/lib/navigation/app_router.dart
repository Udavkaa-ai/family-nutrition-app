import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/member_preferences_screen.dart';

class AppRouter {
  AppRouter._();

  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String addMember = '/add-member';

  static GoRouter router(BuildContext context) {
    return GoRouter(
      initialLocation: home,
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final isAuth = auth.isAuthenticated;
        final isOnAuthPage =
            state.matchedLocation == login || state.matchedLocation == register;

        if (auth.status == AuthStatus.unknown) return null;
        if (!isAuth && !isOnAuthPage) return login;
        if (isAuth && isOnAuthPage) return home;

        return null;
      },
      refreshListenable: _AuthNotifier(context),
      routes: [
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

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(BuildContext context) {
    context.read<AuthProvider>().addListener(notifyListeners);
  }
}
