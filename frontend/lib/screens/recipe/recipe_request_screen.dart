import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/recipe_provider.dart';
import 'recipe_list_screen.dart';

class RecipeRequestScreen extends StatefulWidget {
  const RecipeRequestScreen({super.key});

  @override
  State<RecipeRequestScreen> createState() => _RecipeRequestScreenState();
}

class _RecipeRequestScreenState extends State<RecipeRequestScreen> {
  int _cookTime = 30;
  String _mealType = 'dinner';

  static const _mealTypes = [
    ('breakfast', 'Завтрак', Icons.free_breakfast),
    ('lunch', 'Обед', Icons.lunch_dining),
    ('dinner', 'Ужин', Icons.dinner_dining),
    ('snack', 'Перекус', Icons.cookie),
  ];

  static const _cookTimes = [15, 30, 45, 60, 90];

  Future<void> _generate() async {
    final familyId = context.read<FamilyProvider>().familyId;
    if (familyId == null) return;

    await context.read<RecipeProvider>().generateRecipes(
          familyId: familyId,
          cookTime: _cookTime,
          mealType: _mealType,
        );

    if (mounted) {
      final provider = context.read<RecipeProvider>();
      if (provider.status == RecipeStatus.success) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RecipeListScreen()),
        );
      } else if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<RecipeProvider>().isLoading;
    final members = context.watch<FamilyProvider>().members;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Подобрать рецепты'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Family members summary
          if (members.isNotEmpty) ...[
            _SectionTitle('Учитываем предпочтения'),
            Card(
              child: Column(
                children: members.map((m) => ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.green.shade100,
                    child: Text(m.name[0],
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(m.name),
                  subtitle: m.dietaryPreferences.isEmpty
                      ? null
                      : Text(m.dietaryPreferences.join(', '),
                          style: const TextStyle(fontSize: 12)),
                )).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Meal type
          _SectionTitle('Тип приёма пищи'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.5,
            children: _mealTypes.map((type) {
              final selected = _mealType == type.$1;
              return InkWell(
                onTap: () => setState(() => _mealType = type.$1),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected ? Colors.green : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: selected ? Colors.green : Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(type.$3,
                          color: selected ? Colors.white : Colors.grey,
                          size: 20),
                      const SizedBox(width: 8),
                      Text(type.$2,
                          style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Cook time
          _SectionTitle('Время приготовления: $_cookTime мин'),
          Slider(
            value: _cookTime.toDouble(),
            min: 15,
            max: 90,
            divisions: 5,
            activeColor: Colors.green,
            label: '$_cookTime мин',
            onChanged: (v) => setState(() => _cookTime = v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _cookTimes
                .map((t) => Text('$t',
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: _cookTime == t
                            ? FontWeight.bold
                            : FontWeight.normal)))
                .toList(),
          ),
          const SizedBox(height: 40),

          // Generate button
          ElevatedButton.icon(
            onPressed: isLoading ? null : _generate,
            icon: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome),
            label: Text(
                isLoading ? 'Генерируем рецепты...' : 'Подобрать рецепты',
                style: const TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.green, fontWeight: FontWeight.bold)),
      );
}
