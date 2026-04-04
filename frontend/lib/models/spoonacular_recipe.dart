class SpoonacularRecipe {
  final int id;
  final String title;
  final String image;
  final int readyInMinutes;
  final int servings;
  final String summary;
  final String sourceUrl;

  const SpoonacularRecipe({
    required this.id,
    required this.title,
    required this.image,
    required this.readyInMinutes,
    required this.servings,
    required this.summary,
    required this.sourceUrl,
  });

  factory SpoonacularRecipe.fromJson(Map<String, dynamic> json) =>
      SpoonacularRecipe(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        image: json['image'] as String? ?? '',
        readyInMinutes: (json['readyInMinutes'] as num?)?.toInt() ?? 0,
        servings: (json['servings'] as num?)?.toInt() ?? 0,
        summary: json['summary'] as String? ?? '',
        sourceUrl: json['sourceUrl'] as String? ?? '',
      );
}
