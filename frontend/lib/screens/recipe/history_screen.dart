import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/recipe.dart';
import '../../providers/family_provider.dart';
import '../../services/recipe_service.dart';
import 'recipe_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Recipe> _recipes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final familyId = context.read<FamilyProvider>().familyId;
    if (familyId == null) {
      setState(() { _loading = false; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final recipes = await RecipeService().getSavedRecipes(familyId);
      if (mounted) setState(() { _recipes = recipes; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    if (_recipes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('История пуста',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Нажмите «Ням-ням!» на любом понравившемся рецепте — он появится здесь',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: Colors.green,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _recipes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) => _RecipeCard(
          recipe: _recipes[i],
          onDeleted: _load,
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onDeleted;
  const _RecipeCard({required this.recipe, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final difficultyColor = switch (recipe.difficulty) {
      'easy' => Colors.green,
      'hard' => Colors.red,
      _ => Colors.orange,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
          );
          // Refresh in case recipe was deleted from detail screen
          onDeleted();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(recipe.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: difficultyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: difficultyColor),
                    ),
                    child: Text(recipe.difficultyLabel,
                        style: TextStyle(
                            color: difficultyColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (recipe.description.isNotEmpty)
                Text(recipe.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${recipe.timeMinutes} мин',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(width: 16),
                  const Icon(Icons.restaurant_outlined,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${recipe.ingredients.length} ингр.',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
