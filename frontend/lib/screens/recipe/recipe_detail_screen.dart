import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../config/firebase_config.dart';
import '../../models/recipe.dart';
import '../../providers/family_provider.dart';
import '../../providers/recipe_provider.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _loadingPhoto = false;

  /// Search Pexels for a photo of this dish by name.
  /// Backend translates Russian name → English, returns direct Pexels photo URL.
  Future<void> _findDishPhoto() async {
    setState(() => _loadingPhoto = true);
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final uri = Uri.parse('${FirebaseConfig.backendUrl}/api/photo/search')
          .replace(queryParameters: {'query': widget.recipe.name});
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (!mounted) return;

      if (response.statusCode != 200) {
        final err = (jsonDecode(response.body) as Map<String, dynamic>?)?['error']
            ?? 'Ошибка поиска фото';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = data['url'] as String?;
      if (url == null || url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Фото не найдено для этого блюда')),
        );
        return;
      }

      _showPhotoSheet(url, data['photographer'] as String? ?? '');
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

  void _showPhotoSheet(String photoUrl, String photographer) {
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
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                photoUrl,
                width: double.infinity,
                height: 230,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                        height: 230,
                        child: Center(
                            child: CircularProgressIndicator(color: Colors.green)),
                      ),
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 100,
                  child: Center(child: Text('Не удалось загрузить фото')),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              photographer.isNotEmpty
                  ? 'Фото: $photographer • Pexels'
                  : 'Фото для вдохновения',
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
