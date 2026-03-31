import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/pantry_provider.dart';
import '../family/family_setup_screen.dart';
import '../family/family_members_screen.dart';
import '../pantry/pantry_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _listeningFamilyId;

  static const _screens = [
    _FamilyTab(),
    PantryScreen(),
  ];

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

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.family_restroom),
            label: 'Семья',
          ),
          NavigationDestination(
            icon: Icon(Icons.kitchen),
            label: 'Кладовая',
          ),
        ],
      ),
    );
  }
}

// ── Family tab ────────────────────────────────────────────────────────────────

class _FamilyTab extends StatelessWidget {
  const _FamilyTab();

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
      body: FamilyMembersScreen(),
    );
  }

  void _showInviteCode(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Код приглашения'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
          ],
        ),
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
