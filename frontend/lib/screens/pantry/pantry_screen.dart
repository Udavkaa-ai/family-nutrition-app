import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pantry_item.dart';
import '../../providers/pantry_provider.dart';
import '../../providers/family_provider.dart';

class PantryScreen extends StatelessWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pantry = context.watch<PantryProvider>();
    final familyId = context.watch<FamilyProvider>().familyId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Кладовая'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: pantry.items.isEmpty
          ? const _EmptyPantry()
          : ListView.separated(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: pantry.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final item = pantry.items[i];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.kitchen, color: Colors.green, size: 20),
                  ),
                  title: Text(item.name),
                  subtitle: Text(item.displayQuantity),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () =>
                            _showItemDialog(context, familyId!, item: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 20, color: Colors.red),
                        onPressed: () =>
                            _confirmDelete(context, familyId!, item),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: familyId == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
              onPressed: () => _showItemDialog(context, familyId),
            ),
    );
  }

  void _showItemDialog(BuildContext context, String familyId,
      {PantryItem? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<PantryProvider>(),
        child: _ItemForm(familyId: familyId, item: item),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String familyId, PantryItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить продукт?'),
        content: Text('«${item.name}» будет удалён из кладовой.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<PantryProvider>().deleteItem(familyId, item.id);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Bottom-sheet form ──────────────────────────────────────────────────────────

class _ItemForm extends StatefulWidget {
  final String familyId;
  final PantryItem? item;

  const _ItemForm({required this.familyId, this.item});

  @override
  State<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<_ItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();

  static const _unitSuggestions = ['г', 'кг', 'мл', 'л', 'шт', 'уп', 'ст.л', 'ч.л'];

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _quantityController.text = widget.item!.quantity == widget.item!.quantity.truncateToDouble()
          ? widget.item!.quantity.toInt().toString()
          : widget.item!.quantity.toString();
      _unitController.text = widget.item!.unit;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final pantry = context.read<PantryProvider>();
    final qty = double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 1.0;
    bool success;

    if (_isEditing) {
      success = await pantry.updateItem(
        widget.familyId,
        widget.item!.copyWith(
          name: _nameController.text.trim(),
          quantity: qty,
          unit: _unitController.text.trim(),
        ),
      );
    } else {
      success = await pantry.addItem(
        widget.familyId,
        name: _nameController.text.trim(),
        quantity: qty,
        unit: _unitController.text.trim(),
      );
    }

    if (mounted && success) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Редактировать продукт' : 'Добавить продукт',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Введите название' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Количество',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Введите количество';
                      if (double.tryParse(v.replaceAll(',', '.')) == null) {
                        return 'Неверный формат';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Единица',
                      border: OutlineInputBorder(),
                      hintText: 'г, кг, шт...',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Unit quick-pick chips
            Wrap(
              spacing: 6,
              children: _unitSuggestions.map((u) => ActionChip(
                label: Text(u),
                onPressed: () => setState(() => _unitController.text = u),
                backgroundColor: _unitController.text == u
                    ? Colors.green.shade100
                    : null,
              )).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(_isEditing ? 'Сохранить' : 'Добавить',
                  style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPantry extends StatelessWidget {
  const _EmptyPantry();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.kitchen, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Кладовая пуста',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          SizedBox(height: 8),
          Text('Добавьте продукты, которые есть дома',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
