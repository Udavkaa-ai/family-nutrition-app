import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/pantry_provider.dart';
import '../family/family_setup_screen.dart';
import '../family/family_members_screen.dart';
import '../pantry/pantry_screen.dart';
import '../recipe/recipe_request_screen.dart';
import '../recipe/recipe_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _listeningFamilyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final familyId = context.read<FamilyProvider>().familyId;
    if (familyId != null && familyId != _listeningFamilyId) {
      _listeningFamilyId = familyId;
      context.read<PantryProvider>().startListening(familyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>();

    if (!family.hasFamily) {
      return const FamilySetupScreen();
    }

    final screens = [
      _FamilyTab(),
      const PantryScreen(),
      const RecipeRequestScreen(),
      const RecipeListScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.family_restroom), label: 'Семья'),
          NavigationDestination(icon: Icon(Icons.kitchen), label: 'Кладовая'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Рецепты'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'История'),
        ],
      ),
    );
  }
}

// ── Family tab ────────────────────────────────────────────────────────────────
class _FamilyTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(family.familyName ?? 'Семья'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Код приглашения',
            onPressed: () => _showInviteCode(context, family.inviteCode ?? ''),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: const FamilyMembersScreen(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Добавить'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const _AddMemberPlaceholder(),
        )),
      ),
    );
  }

  void _showInviteCode(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Код приглашения'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Поделитесь с членом семьи:'),
          const SizedBox(height: 16),
          Text(code,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 6)),
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Скопировать'),
            onPressed: () => Clipboard.setData(ClipboardData(text: code)),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}

// Placeholder that routes to MemberPreferencesScreen
class _AddMemberPlaceholder extends StatelessWidget {
  const _AddMemberPlaceholder();

  @override
  Widget build(BuildContext context) {
    // Push immediately and pop self to avoid extra back-stack entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed('/add-member');
    });
    return const SizedBox.shrink();
  }
}
