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
  await FirebaseConfig.initialize();
  runApp(const FamilyNutritionApp());
}

class FamilyNutritionApp extends StatelessWidget {
  const FamilyNutritionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => PantryProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => ShoppingListProvider()),
      ],
      child: Builder(
        builder: (context) => MaterialApp.router(
          title: 'Семейное питание',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: AppRouter.router(context),
        ),
      ),
    );
  }
}
