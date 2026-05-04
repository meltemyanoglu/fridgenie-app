class CookingBadge {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final bool earned;
  final int progress; // 0..100
  final String? earnedDate; // ISO when earned

  const CookingBadge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    this.earned = false,
    this.progress = 0,
    this.earnedDate,
  });

  CookingBadge copyWith({
    bool? earned,
    int? progress,
    String? earnedDate,
  }) =>
      CookingBadge(
        id: id,
        name: name,
        emoji: emoji,
        description: description,
        earned: earned ?? this.earned,
        progress: progress ?? this.progress,
        earnedDate: earnedDate ?? this.earnedDate,
      );
}
