class CookingBadge {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final bool earned;
  final int progress; // 0..100
  final String? earnedDate; // ISO when earned
  final int badgeNumber; // 1–10, maps to assets/badges/badge{n}.png

  const CookingBadge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.badgeNumber,
    this.earned = false,
    this.progress = 0,
    this.earnedDate,
  });

  /// PNG asset path — file must exist at assets/badges/badge{n}.png
  String get assetPath => 'assets/badges/badge$badgeNumber.png';

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
        badgeNumber: badgeNumber,
        earned: earned ?? this.earned,
        progress: progress ?? this.progress,
        earnedDate: earnedDate ?? this.earnedDate,
      );
}
