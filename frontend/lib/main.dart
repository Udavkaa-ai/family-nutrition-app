import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/firebase_config.dart';
import 'navigation/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/family_provider.dart';
import 'providers/pantry_provider.dart';
import 'providers/recipe_provider.dart';
import 'providers/shopping_list_provider.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseConfig.initialize();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  late final AuthProvider authProvider;
  try {
    authProvider = AuthProvider();
  } catch (e) {
    debugPrint('AuthProvider init error: $e');
    authProvider = AuthProvider(authService: null);
  }
  runApp(FamilyNutritionApp(authProvider: authProvider));
}

class FamilyNutritionApp extends StatefulWidget {
  final AuthProvider authProvider;
  const FamilyNutritionApp({super.key, required this.authProvider});

  @override
  State<FamilyNutritionApp> createState() => _FamilyNutritionAppState();
}

class _FamilyNutritionAppState extends State<FamilyNutritionApp> {
  late final router = AppRouter.create(widget.authProvider);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authProvider),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => PantryProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => ShoppingListProvider()),
      ],
      child: MaterialApp.router(
        title: 'Семейное питание',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
}
