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

  void _openDetail(BuildContext context, SpoonacularRecipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RecipeDetailSheet(
        recipe: recipe,
        service: _service,
      ),
    );
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
              hintText: 'Поиск блюд (на англ.): pasta, chicken soup...',
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
                  : _recipes.isEmpty
                      ? const _EmptyResult()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: _recipes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 4),
                          itemBuilder: (ctx, i) => _RecipeListTile(
                            recipe: _recipes[i],
                            onTap: () => _openDetail(ctx, _recipes[i]),
                          ),
                        ),
        ),
      ],
    );
  }
}

// ── Text-only list tile (no photo — photos load only on tap) ──────────────────

class _RecipeListTile extends StatelessWidget {
  final SpoonacularRecipe recipe;
  final VoidCallback onTap;

  const _RecipeListTile({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade50,
          child: const Icon(Icons.restaurant, color: Colors.green, size: 20),
        ),
        title: Text(
          recipe.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

// ── Detail bottom sheet — photo loads here (1 point per unique recipe) ─────────

class _RecipeDetailSheet extends StatefulWidget {
  final SpoonacularRecipe recipe;
  final SpoonacularService service;

  const _RecipeDetailSheet({required this.recipe, required this.service});

  @override
  State<_RecipeDetailSheet> createState() => _RecipeDetailSheetState();
}

class _RecipeDetailSheetState extends State<_RecipeDetailSheet> {
  SpoonacularRecipeDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await widget.service.getRecipeDetail(widget.recipe.id);
      if (mounted) setState(() { _detail = detail; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) {
        if (_loading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Colors.green),
            ),
          );
        }

        if (_error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                  const SizedBox(height: 12),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() { _loading = true; _error = null; });
                      _loadDetail();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Повторить',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        }

        final d = _detail!;
        return SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo — loads only when this sheet is opened
              if (d.image.isNotEmpty)
                Image.network(
                  d.image,
                  height: 220,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : SizedBox(
                          height: 220,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                              color: Colors.green,
                            ),
                          ),
                        ),
                  errorBuilder: (_, __, ___) =>
                      const SizedBox(height: 0),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.title,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (d.readyInMinutes > 0) ...[
                          const Icon(Icons.timer_outlined,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${d.readyInMinutes} мин',
                              style: const TextStyle(color: Colors.grey)),
                          const SizedBox(width: 16),
                        ],
                        if (d.servings > 0) ...[
                          const Icon(Icons.people_outline,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${d.servings} порц.',
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ],
                    ),
                    if (d.summary.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Описание',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(d.summary,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5)),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

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
