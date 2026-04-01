import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/family_provider.dart';
import '../profile/member_preferences_screen.dart';

class FamilyMembersScreen extends StatelessWidget {
  const FamilyMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyProvider>();

    if (family.members.isEmpty) {
      return const _EmptyMembers();
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: family.members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, i) {
        final member = family.members[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12),
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
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  MemberPreferencesScreen(existingMember: member),
            )),
          ),
        );
      },
    );
  }
}

class _EmptyMembers extends StatelessWidget {
  const _EmptyMembers();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Нет участников',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text(
            'Добавьте членов семьи\nдля персональных рекомендаций',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('Добавить участника'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const MemberPreferencesScreen(),
            )),
          ),
        ],
      ),
    );
  }
}
