import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/recipe.dart';
import '../../providers/family_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../services/recipe_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _saveToHistory() async {
    final familyId = context.read<FamilyProvider>().familyId;
    if (familyId == null) return;

    setState(() => _saving = true);
    try {
      await RecipeService().saveRecipe(familyId, widget.recipe.id);
      if (mounted) {
        setState(() { _saving = false; _saved = true; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сохранено в Историю!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          // Meta chips
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

          // Ням-ням! — save to История
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_saving || _saved) ? null : _saveToHistory,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(_saved ? Icons.favorite : Icons.favorite_border),
              label: Text(
                _saving
                    ? 'Сохраняем...'
                    : _saved
                        ? 'В Истории!'
                        : 'Ням-ням!',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _saved ? Colors.grey : Colors.green,
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
              context
                  .read<RecipeProvider>()
                  .deleteRecipe(familyId, widget.recipe.id);
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
  const _MetaChip(
      {required this.icon, required this.label, required this.color});

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
          Text(label,
              style:
                  TextStyle(color: color, fontWeight: FontWeight.bold)),
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
