import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/shopping_list.dart';
import '../../providers/family_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/shopping_list_provider.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  String? _loadedFamilyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final familyId = context.read<FamilyProvider>().familyId;
    if (familyId != null && familyId != _loadedFamilyId) {
      _loadedFamilyId = familyId;
      context.read<ShoppingListProvider>().loadLists(familyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shoppingList = context.watch<ShoppingListProvider>();
    final active = shoppingList.active;
    final familyId = context.watch<FamilyProvider>().familyId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Список покупок'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (active != null) ...[
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Экспортировать',
              onPressed: () => _exportList(active),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, active),
            ),
          ],
        ],
      ),
      body: shoppingList.loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : active == null
              ? _EmptyList(familyId: familyId)
              : _ActiveList(list: active),
      floatingActionButton: familyId == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Создать список'),
              onPressed: () => _showCreateDialog(context, familyId),
            ),
    );
  }

  void _exportList(ShoppingList list) {
    final unchecked = list.items.where((i) => !i.checked).toList();
    final checked = list.items.where((i) => i.checked).toList();

    final buffer = StringBuffer();
    buffer.writeln('🛒 Список покупок');
    buffer.writeln('─' * 30);

    for (final item in unchecked) {
      buffer.writeln('☐ ${item.name} — ${item.displayQuantity}');
    }
    if (checked.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('✓ Куплено:');
      for (final item in checked) {
        buffer.writeln('☑ ${item.name}');
      }
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Список скопирован в буфер обмена'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _confirmDelete(BuildContext context, ShoppingList list) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить список?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              context.read<ShoppingListProvider>().deleteList(list.id);
              Navigator.of(context).pop();
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, String familyId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: context.read<ShoppingListProvider>()),
          ChangeNotifierProvider.value(value: context.read<RecipeProvider>()),
        ],
        child: _CreateListSheet(familyId: familyId),
      ),
    );
  }
}

// ── Active list ───────────────────────────────────────────────────────────────

class _ActiveList extends StatelessWidget {
  final ShoppingList list;
  const _ActiveList({required this.list});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoppingListProvider>();
    final unchecked = <int>[];
    final checked = <int>[];

    for (var i = 0; i < list.items.length; i++) {
      (list.items[i].checked ? checked : unchecked).add(i);
    }

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${list.checkedCount} / ${list.items.length} куплено'),
                  if (list.isComplete)
                    const Chip(
                      label: Text('Готово!'),
                      backgroundColor: Color(0xFFE8F5E9),
                      labelStyle: TextStyle(color: Colors.green),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: list.items.isEmpty
                    ? 0
                    : list.checkedCount / list.items.length,
                backgroundColor: Colors.grey.shade200,
                color: Colors.green,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              ...unchecked.map((i) => _ItemTile(
                    item: list.items[i],
                    onToggle: (v) => provider.toggleItem(i, v),
                  )),
              if (checked.isNotEmpty) ...[
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text('Куплено',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                ...checked.map((i) => _ItemTile(
                      item: list.items[i],
                      onToggle: (v) => provider.toggleItem(i, v),
                    )),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  final ShoppingListItem item;
  final ValueChanged<bool> onToggle;

  const _ItemTile({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: item.checked,
        activeColor: Colors.green,
        onChanged: (v) => onToggle(v ?? false),
      ),
      title: Text(
        item.name,
        style: TextStyle(
          decoration: item.checked ? TextDecoration.lineThrough : null,
          color: item.checked ? Colors.grey : null,
        ),
      ),
      trailing: Text(
        item.displayQuantity,
        style: TextStyle(color: item.checked ? Colors.grey : Colors.green,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyList extends StatelessWidget {
  final String? familyId;
  const _EmptyList({this.familyId});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Список покупок пуст',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          SizedBox(height: 8),
          Text('Создайте список из рецептов\nили вручную',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// ── Create list bottom sheet ──────────────────────────────────────────────────

class _CreateListSheet extends StatefulWidget {
  final String familyId;
  const _CreateListSheet({required this.familyId});

  @override
  State<_CreateListSheet> createState() => _CreateListSheetState();
}

class _CreateListSheetState extends State<_CreateListSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Set<String> _selectedRecipeIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _createFromRecipes() async {
    if (_selectedRecipeIds.isEmpty) return;
    final provider = context.read<ShoppingListProvider>();
    final success = await provider.createFromRecipes(
      familyId: widget.familyId,
      recipeIds: _selectedRecipeIds.toList(),
    );
    if (mounted) {
      Navigator.of(context).pop();
      if (!success && provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage!), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipes = context.watch<RecipeProvider>().recipes;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 8),
          const Text('Создать список',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TabBar(
            controller: _tabController,
            labelColor: Colors.green,
            indicatorColor: Colors.green,
            tabs: const [
              Tab(text: 'Из рецептов'),
              Tab(text: 'Вручную'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // From recipes
                recipes.isEmpty
                    ? const Center(
                        child: Text('Сначала сгенерируйте рецепты',
                            style: TextStyle(color: Colors.grey)))
                    : ListView(
                        controller: controller,
                        padding: const EdgeInsets.all(12),
                        children: [
                          ...recipes.map((r) {
                            final selected = _selectedRecipeIds.contains(r.id);
                            return CheckboxListTile(
                              title: Text(r.name),
                              subtitle: Text('${r.timeMinutes} мин · ${r.difficultyLabel}'),
                              value: selected,
                              activeColor: Colors.green,
                              onChanged: (v) => setState(() =>
                                  v! ? _selectedRecipeIds.add(r.id) : _selectedRecipeIds.remove(r.id)),
                            );
                          }),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _selectedRecipeIds.isEmpty ? null : _createFromRecipes,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green, foregroundColor: Colors.white),
                            child: Text('Создать список (${_selectedRecipeIds.length} рецептов)'),
                          ),
                        ],
                      ),
                // Manual
                const _ManualListForm(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualListForm extends StatefulWidget {
  const _ManualListForm();

  @override
  State<_ManualListForm> createState() => _ManualListFormState();
}

class _ManualListFormState extends State<_ManualListForm> {
  final _items = <Map<String, dynamic>>[];
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _unitCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() {
      _items.add({
        'name': _nameCtrl.text.trim(),
        'quantity': double.tryParse(_qtyCtrl.text) ?? 1,
        'unit': _unitCtrl.text.trim(),
        'checked': false,
      });
      _nameCtrl.clear();
      _qtyCtrl.text = '1';
      _unitCtrl.clear();
    });
  }

  Future<void> _create() async {
    if (_items.isEmpty) return;
    final familyId = context.read<FamilyProvider>().familyId!;
    await context.read<ShoppingListProvider>().createManual(
          familyId: familyId,
          items: _items,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Продукт', border: OutlineInputBorder(), isDense: true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Кол-во', border: OutlineInputBorder(), isDense: true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _unitCtrl,
              decoration: const InputDecoration(
                  labelText: 'Ед.', border: OutlineInputBorder(), isDense: true, hintText: 'г/шт'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.green),
            onPressed: _addItem,
          ),
        ]),
        const SizedBox(height: 8),
        ..._items.map((item) => ListTile(
              dense: true,
              title: Text(item['name'] as String),
              trailing: Text('${item['quantity']} ${item['unit']}'),
              leading: IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                onPressed: () => setState(() => _items.remove(item)),
              ),
            )),
        if (_items.isNotEmpty) ...[
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _create,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: Text('Создать список (${_items.length} товаров)'),
          ),
        ],
      ],
    );
  }
}
