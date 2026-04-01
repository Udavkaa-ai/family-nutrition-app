import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/family_member.dart';
import '../../providers/family_provider.dart';

class MemberPreferencesScreen extends StatefulWidget {
  final FamilyMember? existingMember; // null = adding new member

  const MemberPreferencesScreen({super.key, this.existingMember});

  @override
  State<MemberPreferencesScreen> createState() => _MemberPreferencesScreenState();
}

class _MemberPreferencesScreenState extends State<MemberPreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dislikedController = TextEditingController();

  String _cookingLevel = 'medium';
  final Set<String> _dietary = {};
  final Set<String> _cuisines = {};
  final List<String> _disliked = [];

  static const _dietaryOptions = [
    'Вегетарианец', 'Веган', 'Без глютена', 'Без лактозы',
    'Без орехов', 'Халяль', 'Кошерное', 'Низкокалорийное',
  ];

  static const _cuisineOptions = [
    'Русская', 'Итальянская', 'Азиатская', 'Мексиканская',
    'Средиземноморская', 'Американская', 'Японская', 'Индийская',
  ];

  static const _cookingLevels = [
    ('easy', 'Простые блюда'),
    ('medium', 'Средняя сложность'),
    ('hard', 'Сложные рецепты'),
  ];

  bool get _isEditing => widget.existingMember != null;

  @override
  void initState() {
    super.initState();
    final m = widget.existingMember;
    if (m != null) {
      _nameController.text = m.name;
      _cookingLevel = m.cookingLevel;
      _dietary.addAll(m.dietaryPreferences);
      _cuisines.addAll(m.preferredCuisines);
      _disliked.addAll(m.dislikedIngredients);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dislikedController.dispose();
    super.dispose();
  }

  void _addDisliked() {
    final v = _dislikedController.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _disliked.add(v);
      _dislikedController.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final family = context.read<FamilyProvider>();
    final familyId = family.familyId;
    if (familyId == null) return;

    bool success;
    if (_isEditing) {
      success = await family.updateMember(widget.existingMember!.id!, {
        'name': _nameController.text.trim(),
        'dietaryPreferences': _dietary.toList(),
        'preferredCuisines': _cuisines.toList(),
        'dislikedIngredients': _disliked,
        'cookingLevel': _cookingLevel,
      });
    } else {
      success = await family.addMember(FamilyMember(
        familyId: familyId,
        name: _nameController.text.trim(),
        dietaryPreferences: _dietary.toList(),
        preferredCuisines: _cuisines.toList(),
        dislikedIngredients: _disliked,
        cookingLevel: _cookingLevel,
      ));
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(family.errorMessage ?? 'Ошибка сохранения'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактировать участника' : 'Новый участник'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Имя участника',
                prefixIcon: Icon(Icons.person_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Введите имя' : null,
            ),
            const SizedBox(height: 24),

            // Cooking level
            _SectionTitle('Уровень сложности рецептов'),
            ..._cookingLevels.map((level) => RadioListTile<String>(
                  title: Text(level.$2),
                  value: level.$1,
                  groupValue: _cookingLevel,
                  activeColor: Colors.green,
                  onChanged: (v) => setState(() => _cookingLevel = v!),
                )),
            const SizedBox(height: 16),

            // Dietary preferences
            _SectionTitle('Диетические предпочтения'),
            Wrap(
              spacing: 8,
              children: _dietaryOptions.map((opt) {
                final selected = _dietary.contains(opt);
                return FilterChip(
                  label: Text(opt),
                  selected: selected,
                  selectedColor: Colors.green.shade100,
                  checkmarkColor: Colors.green,
                  onSelected: (v) => setState(
                      () => v ? _dietary.add(opt) : _dietary.remove(opt)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Preferred cuisines
            _SectionTitle('Любимые кухни'),
            Wrap(
              spacing: 8,
              children: _cuisineOptions.map((opt) {
                final selected = _cuisines.contains(opt);
                return FilterChip(
                  label: Text(opt),
                  selected: selected,
                  selectedColor: Colors.green.shade100,
                  checkmarkColor: Colors.green,
                  onSelected: (v) => setState(
                      () => v ? _cuisines.add(opt) : _cuisines.remove(opt)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Disliked ingredients
            _SectionTitle('Нелюбимые ингредиенты'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dislikedController,
                    decoration: const InputDecoration(
                      hintText: 'Например: лук, кинза...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addDisliked(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green, size: 32),
                  onPressed: _addDisliked,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _disliked.map((item) {
                return Chip(
                  label: Text(item),
                  onDeleted: () => setState(() => _disliked.remove(item)),
                  deleteIconColor: Colors.red,
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
      ),
    );
  }
}
