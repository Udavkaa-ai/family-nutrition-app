class MealPlanMeal {
  final String name;
  final int timeMinutes;
  final String note;

  MealPlanMeal({required this.name, required this.timeMinutes, required this.note});

  factory MealPlanMeal.fromJson(Map<String, dynamic> j) => MealPlanMeal(
        name: j['name'] as String? ?? '',
        timeMinutes: (j['time_minutes'] as num?)?.toInt() ?? 0,
        note: j['note'] as String? ?? '',
      );
}

class MealPlanDay {
  final int day;
  final MealPlanMeal breakfast;
  final MealPlanMeal lunch;
  final MealPlanMeal dinner;

  MealPlanDay({
    required this.day,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  factory MealPlanDay.fromJson(Map<String, dynamic> j) => MealPlanDay(
        day: (j['day'] as num?)?.toInt() ?? 0,
        breakfast: MealPlanMeal.fromJson(j['breakfast'] as Map<String, dynamic>? ?? {}),
        lunch: MealPlanMeal.fromJson(j['lunch'] as Map<String, dynamic>? ?? {}),
        dinner: MealPlanMeal.fromJson(j['dinner'] as Map<String, dynamic>? ?? {}),
      );
}

class ShoppingItem {
  final String name;
  final String quantity;
  final int priceApprox;

  ShoppingItem({required this.name, required this.quantity, required this.priceApprox});

  factory ShoppingItem.fromJson(Map<String, dynamic> j) => ShoppingItem(
        name: j['name'] as String? ?? '',
        quantity: j['quantity'] as String? ?? '',
        priceApprox: (j['price_approx'] as num?)?.toInt() ?? 0,
      );
}

class ShoppingCategory {
  final String category;
  final List<ShoppingItem> items;

  ShoppingCategory({required this.category, required this.items});

  factory ShoppingCategory.fromJson(Map<String, dynamic> j) => ShoppingCategory(
        category: j['category'] as String? ?? '',
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  int get subtotal => items.fold(0, (sum, i) => sum + i.priceApprox);
}

class MealPlan {
  final List<MealPlanDay> plan;
  final List<ShoppingCategory> shoppingList;
  final int totalEstimatedCost;
  final List<String> cookingTips;

  MealPlan({
    required this.plan,
    required this.shoppingList,
    required this.totalEstimatedCost,
    required this.cookingTips,
  });

  factory MealPlan.fromJson(Map<String, dynamic> j) => MealPlan(
        plan: (j['plan'] as List<dynamic>? ?? [])
            .map((e) => MealPlanDay.fromJson(e as Map<String, dynamic>))
            .toList(),
        shoppingList: (j['shopping_list'] as List<dynamic>? ?? [])
            .map((e) => ShoppingCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalEstimatedCost: (j['total_estimated_cost'] as num?)?.toInt() ?? 0,
        cookingTips: (j['cooking_tips'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}
