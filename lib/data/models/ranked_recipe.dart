class RankedRecipe {
  final String id;
  final String title;
  final double score;

  RankedRecipe({
    required this.id,
    required this.title,
    required this.score,
  });

  factory RankedRecipe.fromRecipe(dynamic recipe) {
    return RankedRecipe(
      id: recipe['id'] ?? '',
      title: recipe['title'] ?? '',
      score: (recipe['score'] ?? 0).toDouble(),
    );
  }
}