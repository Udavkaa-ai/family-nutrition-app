import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/recipe.dart';
import '../../providers/recipe_provider.dart';
import 'recipe_detail_screen.dart';

class RecipeListScreen extends StatelessWidget {
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подобранные рецепты'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Consumer<RecipeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.green));
          }
          if (provider.recipes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Нет рецептов',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: provider.recipes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _RecipeCard(recipe: provider.recipes[i]),
          );
        },
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  const _RecipeCard({required this.recipe});

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
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                  const Icon(Icons.timer_outlined,
                      size: 16, color: Colors.grey),
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
