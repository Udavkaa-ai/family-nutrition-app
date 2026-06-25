import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/meal_plan.dart';
import '../../providers/family_provider.dart';
import '../../services/meal_plan_service.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  int _days = 7;
  int _maxCookMinutes = 40;
  String _mode = 'normal';
  final _budgetController = TextEditingController(text: '5000');

  bool _loading = false;
  String? _error;
  MealPlan? _plan;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final familyId = context.read<FamilyProvider>().familyId;
    if (familyId == null) return;

    final budget = int.tryParse(_budgetController.text.trim()) ?? 0;
    if (budget <= 0) {
      setState(() => _error = 'Укажите бюджет');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final plan = await MealPlanService().generateMealPlan(
        familyId: familyId,
        days: _days,
        budgetRub: budget,
        maxCookMinutes: _maxCookMinutes,
        mode: _mode,
      );
      setState(() { _plan = plan; _loading = false; });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Планировщик меню'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: _plan != null
            ? [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Новый план',
                  onPressed: _loading ? null : () => setState(() => _plan = null),
                )
              ]
            : null,
      ),
      body: _plan != null ? _PlanView(plan: _plan!) : _buildForm(),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Days
        _SectionTitle('Период: $_days ${_dayWord(_days)}'),
        Slider(
          value: _days.toDouble(),
          min: 1,
          max: 7,
          divisions: 6,
          activeColor: Colors.green,
          label: '$_days',
          onChanged: (v) => setState(() => _days = v.round()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [1, 2, 3, 4, 5, 6, 7]
              .map((d) => Text('$d',
                  style: TextStyle(
                      color: Colors.grey,
                      fontWeight:
                          _days == d ? FontWeight.bold : FontWeight.normal)))
              .toList(),
        ),
        const SizedBox(height: 24),

        // Budget
        _SectionTitle('Бюджет на период'),
        TextField(
          controller: _budgetController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            suffixText: '₽',
            hintText: '5000',
          ),
        ),
        const SizedBox(height: 24),

        // Cook time
        _SectionTitle('Время готовки: до $_maxCookMinutes мин/день'),
        Slider(
          value: _maxCookMinutes.toDouble(),
          min: 15,
          max: 90,
          divisions: 5,
          activeColor: Colors.green,
          label: '$_maxCookMinutes мин',
          onChanged: (v) => setState(() => _maxCookMinutes = v.round()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [15, 30, 45, 60, 75, 90]
              .map((t) => Text('$t',
                  style: TextStyle(
                      color: Colors.grey,
                      fontWeight: _maxCookMinutes == t
                          ? FontWeight.bold
                          : FontWeight.normal)))
              .toList(),
        ),
        const SizedBox(height: 24),

        // Mode
        _SectionTitle('Режим готовки'),
        Row(
          children: [
            Expanded(
              child: _ModeButton(
                label: 'Обычный',
                icon: Icons.local_dining,
                selected: _mode == 'normal',
                onTap: () => setState(() => _mode = 'normal'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ModeButton(
                label: 'Быстро',
                icon: Icons.flash_on,
                selected: _mode == 'quick',
                onTap: () => setState(() => _mode = 'quick'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _mode == 'quick'
              ? 'Полуфабрикаты, минимум готовки'
              : 'Простые домашние рецепты',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 32),

        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 16),
        ],

        ElevatedButton.icon(
          onPressed: _loading ? null : _generate,
          icon: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.calendar_month),
          label: Text(
            _loading ? 'Составляем план...' : 'Составить план',
            style: const TextStyle(fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

String _dayWord(int n) {
  if (n == 1) return 'день';
  if (n < 5) return 'дня';
  return 'дней';
}

// ── Plan view with tabs ───────────────────────────────────────────────────────

class _PlanView extends StatelessWidget {
  final MealPlan plan;
  const _PlanView({required this.plan});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Cost banner
          Container(
            width: double.infinity,
            color: Colors.green.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Примерная стоимость: ${plan.totalEstimatedCost} ₽',
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const TabBar(
            labelColor: Colors.green,
            indicatorColor: Colors.green,
            tabs: [
              Tab(icon: Icon(Icons.restaurant_menu), text: 'Меню'),
              Tab(icon: Icon(Icons.shopping_cart), text: 'Покупки'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _MenuTab(plan: plan),
                _ShoppingTab(plan: plan),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Menu tab ──────────────────────────────────────────────────────────────────

class _MenuTab extends StatelessWidget {
  final MealPlan plan;
  const _MenuTab({required this.plan});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ...plan.plan.map((day) => _DayCard(day: day)),
        if (plan.cookingTips.isNotEmpty) ...[
          const SizedBox(height: 8),
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.orange, size: 18),
                      SizedBox(width: 6),
                      Text('Советы',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...plan.cookingTips.map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(color: Colors.orange)),
                            Expanded(
                                child: Text(tip,
                                    style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  final MealPlanDay day;
  const _DayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('День ${day.day}',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
            const Divider(height: 12),
            _MealRow(icon: Icons.free_breakfast, label: 'Завтрак', meal: day.breakfast),
            const SizedBox(height: 6),
            _MealRow(icon: Icons.lunch_dining, label: 'Обед', meal: day.lunch),
            const SizedBox(height: 6),
            _MealRow(icon: Icons.dinner_dining, label: 'Ужин', meal: day.dinner),
          ],
        ),
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final MealPlanMeal meal;
  const _MealRow({required this.icon, required this.label, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        SizedBox(
          width: 56,
          child: Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(meal.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14)),
              if (meal.note.isNotEmpty)
                Text(meal.note,
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
        Text('${meal.timeMinutes} мин',
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

// ── Shopping tab ──────────────────────────────────────────────────────────────

class _ShoppingTab extends StatelessWidget {
  final MealPlan plan;
  const _ShoppingTab({required this.plan});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ...plan.shoppingList.map((cat) => _CategoryCard(cat: cat)),
        const SizedBox(height: 8),
        Card(
          color: Colors.green.shade50,
          child: ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: Colors.green),
            title: const Text('Итого',
                style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              '${plan.totalEstimatedCost} ₽',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ShoppingCategory cat;
  const _CategoryCard({required this.cat});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(cat.category,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green)),
                ),
                Text('~${cat.subtotal} ₽',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13)),
              ],
            ),
            const Divider(height: 10),
            ...cat.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.fiber_manual_record,
                          size: 8, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.name, style: const TextStyle(fontSize: 14))),
                      Text(item.quantity,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                      const SizedBox(width: 12),
                      Text('${item.priceApprox} ₽',
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 13)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.green, fontWeight: FontWeight.bold)),
      );
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeButton(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.green : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? Colors.green : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: selected ? Colors.white : Colors.grey, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
