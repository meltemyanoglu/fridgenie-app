import 'enums.dart';

/// Lifetime cooking history that badges are computed from; saved as JSON.
class CookingStats {
  final int useItUpCooked;
  final int quickCooked;
  final int lateNightCooked;
  final int surpriseCooked;
  final int challengeCooked;
  final int aiRecipesGenerated;
  final Set<CuisineType> cuisinesCooked;
  final Set<Mood> moodsCooked;

  /// Badge id → day it was first earned, so it never gets "un-earned".
  final Map<String, DateTime> badgesEarnedOn;

  const CookingStats({
    this.useItUpCooked = 0,
    this.quickCooked = 0,
    this.lateNightCooked = 0,
    this.surpriseCooked = 0,
    this.challengeCooked = 0,
    this.aiRecipesGenerated = 0,
    this.cuisinesCooked = const {},
    this.moodsCooked = const {},
    this.badgesEarnedOn = const {},
  });

  CookingStats copyWith({
    int? useItUpCooked,
    int? quickCooked,
    int? lateNightCooked,
    int? surpriseCooked,
    int? challengeCooked,
    int? aiRecipesGenerated,
    Set<CuisineType>? cuisinesCooked,
    Set<Mood>? moodsCooked,
    Map<String, DateTime>? badgesEarnedOn,
  }) =>
      CookingStats(
        useItUpCooked: useItUpCooked ?? this.useItUpCooked,
        quickCooked: quickCooked ?? this.quickCooked,
        lateNightCooked: lateNightCooked ?? this.lateNightCooked,
        surpriseCooked: surpriseCooked ?? this.surpriseCooked,
        challengeCooked: challengeCooked ?? this.challengeCooked,
        aiRecipesGenerated: aiRecipesGenerated ?? this.aiRecipesGenerated,
        cuisinesCooked: cuisinesCooked ?? this.cuisinesCooked,
        moodsCooked: moodsCooked ?? this.moodsCooked,
        badgesEarnedOn: badgesEarnedOn ?? this.badgesEarnedOn,
      );

  Map<String, dynamic> toJson() => {
        'useItUpCooked': useItUpCooked,
        'quickCooked': quickCooked,
        'lateNightCooked': lateNightCooked,
        'surpriseCooked': surpriseCooked,
        'challengeCooked': challengeCooked,
        'aiRecipesGenerated': aiRecipesGenerated,
        'cuisinesCooked': cuisinesCooked.map((c) => c.name).toList(),
        'moodsCooked': moodsCooked.map((m) => m.name).toList(),
        'badgesEarnedOn': badgesEarnedOn
            .map((id, day) => MapEntry(id, day.toIso8601String())),
      };

  /// Lenient: missing counters are 0 and unknown names are skipped.
  factory CookingStats.fromJson(Map<String, dynamic> j) {
    int count(String key) {
      final value = j[key];
      return value is int && value > 0 ? value : 0;
    }

    Set<T> names<T extends Enum>(String key, List<T> values) {
      final raw = j[key];
      if (raw is! List) return {};
      return values.where((v) => raw.contains(v.name)).toSet();
    }

    final earned = <String, DateTime>{};
    final rawEarned = j['badgesEarnedOn'];
    if (rawEarned is Map) {
      rawEarned.forEach((id, day) {
        final parsed = day is String ? DateTime.tryParse(day) : null;
        if (id is String && parsed != null) earned[id] = parsed;
      });
    }

    return CookingStats(
      useItUpCooked: count('useItUpCooked'),
      quickCooked: count('quickCooked'),
      lateNightCooked: count('lateNightCooked'),
      surpriseCooked: count('surpriseCooked'),
      challengeCooked: count('challengeCooked'),
      aiRecipesGenerated: count('aiRecipesGenerated'),
      cuisinesCooked: names('cuisinesCooked', CuisineType.values),
      moodsCooked: names('moodsCooked', Mood.values),
      badgesEarnedOn: earned,
    );
  }
}
