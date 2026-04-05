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
      final detailed = await RecipeService().saveRecipe(familyId, widget.recipe.id);
      if (!mounted) return;
      setState(() { _saving = false; _saved = true; });
      // Show detailed recipe in a full-screen sheet
      _showDetailedRecipe(detailed);
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

  void _showDetailedRecipe(Map<String, dynamic> detailed) {
    final steps = List<String>.from(detailed['detailedInstructions'] ?? []);
    final prepNotes = detailed['prepNotes'] as String? ?? '';
    final tips = List<String>.from(detailed['cookingTips'] ?? []);

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _DetailedRecipeScreen(
        recipeName: widget.recipe.name,
        steps: steps,
        prepNotes: prepNotes,
        tips: tips,
      ),
    ));
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

// ── Detailed step-by-step recipe screen ───────────────────────────────────────

class _DetailedRecipeScreen extends StatelessWidget {
  final String recipeName;
  final List<String> steps;
  final String prepNotes;
  final List<String> tips;

  const _DetailedRecipeScreen({
    required this.recipeName,
    required this.steps,
    required this.prepNotes,
    required this.tips,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipeName, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Saved confirmation banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.favorite, color: Colors.green, size: 18),
                SizedBox(width: 8),
                Text('Рецепт сохранён в Историю',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Preparation notes
          if (prepNotes.isNotEmpty) ...[
            _Header('Подготовка'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(prepNotes,
                  style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 24),
          ],

          // Detailed steps
          _Header('Пошаговый рецепт'),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((e) => _StepCard(
                number: e.key + 1,
                text: e.value,
              )),

          // Cooking tips
          if (tips.isNotEmpty) ...[
            const SizedBox(height: 8),
            _Header('Советы шефа'),
            const SizedBox(height: 8),
            ...tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(tip,
                              style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header(this.title);

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
      );
}

class _StepCard extends StatelessWidget {
  final int number;
  final String text;
  const _StepCard({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.green,
            child: Text('$number',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(text, style: const TextStyle(fontSize: 14, height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}
