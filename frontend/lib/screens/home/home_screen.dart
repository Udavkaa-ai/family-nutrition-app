import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../family/family_setup_screen.dart';
import '../profile/member_preferences_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final family = context.watch<FamilyProvider>();

    // No family yet — show setup screen
    if (!family.hasFamily) {
      return const FamilySetupScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(family.familyName ?? 'Семейное питание'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          // Show invite code
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Код приглашения',
            onPressed: () => _showInviteCode(context, family.inviteCode ?? ''),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: family.members.isEmpty
          ? _EmptyMembersPlaceholder()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: family.members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final member = family.members[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Text(
                        member.name[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(member.name),
                    subtitle: member.dietaryPreferences.isEmpty
                        ? const Text('Без ограничений')
                        : Text(member.dietaryPreferences.join(', ')),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MemberPreferencesScreen(
                              existingMember: member),
                        ),
                      ),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            MemberPreferencesScreen(existingMember: member),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Добавить участника'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: context.read<FamilyProvider>(),
              child: const MemberPreferencesScreen(),
            ),
          ),
        ),
      ),
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
            const Text('Поделитесь кодом с членом семьи:'),
            const SizedBox(height: 16),
            Text(
              code,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 6),
            ),
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

class _EmptyMembersPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Пока нет участников',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Добавьте членов семьи\nчтобы получать персональные рекомендации',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
