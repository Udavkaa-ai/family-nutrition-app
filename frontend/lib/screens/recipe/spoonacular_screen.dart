import 'package:flutter/material.dart';
import '../../models/spoonacular_recipe.dart';
import '../../services/spoonacular_service.dart';

class SpoonacularScreen extends StatefulWidget {
  const SpoonacularScreen({super.key});

  @override
  State<SpoonacularScreen> createState() => _SpoonacularScreenState();
}

class _SpoonacularScreenState extends State<SpoonacularScreen> {
  final _searchController = TextEditingController();
  final _service = SpoonacularService();

  List<SpoonacularRecipe> _recipes = [];
  bool _loading = false;
  String? _error;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _search('healthy family dinner');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });

    try {
      final results = await _service.searchRecipes(query);
      setState(() {
        _recipes = results;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Поиск рецептов (на англ.): pasta, chicken...',
              prefixIcon: const Icon(Icons.search, color: Colors.green),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onSubmitted: (q) => _search(q.trim()),
            onChanged: (_) => setState(() {}),
          ),
        ),

        // Content
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.green))
              : _error != null
                  ? _ErrorView(
                      message: _error!,
                      onRetry: () => _search(_searchController.text.trim()),
                    )
                  : _recipes.isEmpty && _searched
                      ? const _EmptyResult()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          itemCount: _recipes.length,
                          itemBuilder: (_, i) =>
                              _SpoonacularCard(recipe: _recipes[i]),
                        ),
        ),
      ],
    );
  }
}

class _SpoonacularCard extends StatelessWidget {
  final SpoonacularRecipe recipe;
  const _SpoonacularCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetail(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            if (recipe.image.isNotEmpty)
              SizedBox(
                width: 110,
                height: 90,
                child: Image.network(
                  recipe.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.restaurant, color: Colors.grey),
                  ),
                ),
              )
            else
              Container(
                width: 110,
                height: 90,
                color: Colors.grey.shade200,
                child: const Icon(Icons.restaurant, color: Colors.grey),
              ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text('${recipe.readyInMinutes} мин',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                        const SizedBox(width: 10),
                        const Icon(Icons.people_outline,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text('${recipe.servings} порц.',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (recipe.image.isNotEmpty)
                Image.network(
                  recipe.image,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const SizedBox(height: 0),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.title,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${recipe.readyInMinutes} минут',
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(width: 16),
                        const Icon(Icons.people_outline,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${recipe.servings} порций',
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    if (recipe.summary.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Описание',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(recipe.summary,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black87)),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Повторить',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('Рецепты не найдены',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          SizedBox(height: 4),
          Text('Попробуйте другой запрос',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
