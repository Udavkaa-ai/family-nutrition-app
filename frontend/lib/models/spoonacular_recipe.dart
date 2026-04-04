/// Basic info returned by the search endpoint (id + title only, 1 point/search).
class SpoonacularRecipe {
  final int id;
  final String title;
  /// Raw image URL from search results — only used when detail is loaded.
  final String image;

  const SpoonacularRecipe({
    required this.id,
    required this.title,
    required this.image,
  });

  factory SpoonacularRecipe.fromJson(Map<String, dynamic> json) =>
      SpoonacularRecipe(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        image: json['image'] as String? ?? '',
      );
}

/// Full details fetched on demand when the user taps a recipe (1 point/tap).
class SpoonacularRecipeDetail {
  final int id;
  final String title;
  final String image;
  final int readyInMinutes;
  final int servings;
  final String summary;
  final String sourceUrl;

  const SpoonacularRecipeDetail({
    required this.id,
    required this.title,
    required this.image,
    required this.readyInMinutes,
    required this.servings,
    required this.summary,
    required this.sourceUrl,
  });

  factory SpoonacularRecipeDetail.fromJson(Map<String, dynamic> json) =>
      SpoonacularRecipeDetail(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        image: json['image'] as String? ?? '',
        readyInMinutes: (json['readyInMinutes'] as num?)?.toInt() ?? 0,
        servings: (json['servings'] as num?)?.toInt() ?? 0,
        summary: json['summary'] as String? ?? '',
        sourceUrl: json['sourceUrl'] as String? ?? '',
      );
}
