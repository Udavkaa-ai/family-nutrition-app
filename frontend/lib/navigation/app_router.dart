import 'package:go_router/go_router.dart';

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

  /// Creates a [GoRouter] once. Pass [authProvider] directly as
  /// [refreshListenable] so the router reacts to auth changes without
  /// ever being recreated.
  static GoRouter create(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: login,
      refreshListenable: authProvider,
      redirect: (context, state) {
        // While Firebase is still resolving, stay wherever we are
        if (authProvider.status == AuthStatus.unknown) return null;

        final isAuth = authProvider.isAuthenticated;
        final loc = state.matchedLocation;
        final isOnAuthPage = loc == login || loc == register;

        if (!isAuth && !isOnAuthPage) return login;
        if (isAuth && isOnAuthPage) return home;
        return null;
      },
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
