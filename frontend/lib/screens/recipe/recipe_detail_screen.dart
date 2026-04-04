import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/recipe.dart';
import '../../models/spoonacular_recipe.dart';
import '../../providers/family_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../services/spoonacular_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _loadingPhoto = false;

  /// Search Spoonacular for a photo of this dish.
  /// The backend auto-translates Cyrillic names to English before querying.
  Future<void> _findDishPhoto() async {
    setState(() => _loadingPhoto = true);
    try {
      final results = await SpoonacularService()
          .searchRecipes(widget.recipe.name, number: 3);
      final withPhoto = results.where((r) => r.image.isNotEmpty).toList();

      if (!mounted) return;
      if (withPhoto.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Похожее блюдо не найдено в базе фотографий')),
        );
        return;
      }
      _showPhotoSheet(withPhoto.first);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingPhoto = false);
    }
  }

  void _showPhotoSheet(SpoonacularRecipe r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Вот как это выглядит',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              r.title,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                r.image,
                width: double.infinity,
                height: 230,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                        height: 230,
                        child: Center(child: CircularProgressIndicator(color: Colors.green)),
                      ),
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 100,
                  child: Center(child: Text('Не удалось загрузить фото')),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Фото для вдохновения — рецепт на русском уже выше',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final difficultyColor = switch (widget.recipe.difficulty) {
      'easy' => Colors.green,
      'hard' => Colors.red,
      _ => Colors.orange,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.name, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Meta
          Row(
            children: [
              _MetaChip(
                icon: Icons.timer_outlined,
                label: '${widget.recipe.timeMinutes} мин',
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              _MetaChip(
                icon: Icons.signal_cellular_alt,
                label: widget.recipe.difficultyLabel,
                color: difficultyColor,
              ),
            ],
          ),
          if (widget.recipe.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(widget.recipe.description,
                style: TextStyle(color: Colors.grey[700], fontSize: 15)),
          ],
          const SizedBox(height: 24),

          // Ingredients
          const _SectionHeader('Ингредиенты'),
          const SizedBox(height: 8),
          ...widget.recipe.ingredients.map((ing) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.fiber_manual_record,
                        size: 8, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(ing.name)),
                    Text(
                      ing.quantity == ing.quantity.truncateToDouble()
                          ? '${ing.quantity.toInt()} ${ing.unit}'
                          : '${ing.quantity} ${ing.unit}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),

          // Instructions
          const _SectionHeader('Приготовление'),
          const SizedBox(height: 8),
          ...widget.recipe.instructions.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.green,
                      child: Text('${e.key + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(e.value,
                            style: const TextStyle(fontSize: 15))),
                  ],
                ),
              )),
          const SizedBox(height: 24),

          // "Ням-ням!" button — find a photo of this dish on Spoonacular
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadingPhoto ? null : _findDishPhoto,
              icon: _loadingPhoto
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('🍽️', style: TextStyle(fontSize: 18)),
              label: Text(
                _loadingPhoto ? 'Ищем фото...' : 'Ням-ням!',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить рецепт?'),
        content: Text('«${widget.recipe.name}» будет удалён.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final familyId = context.read<FamilyProvider>().familyId!;
              context.read<RecipeProvider>().deleteRecipe(familyId, widget.recipe.id);
              Navigator.of(context)
                ..pop()
                ..pop();
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold, color: Colors.green),
      );
}
