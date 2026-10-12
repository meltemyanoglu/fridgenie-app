import '../models/badge.dart';
import '../models/cooking_stats.dart';
import '../models/user_profile.dart';

/// One badge definition: what it shows and how its progress is measured.
class BadgeRule {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final int badgeNumber;

  /// Value needed to earn the badge.
  final int target;
  final int Function(CookingStats stats, UserProfile profile) measure;

  const BadgeRule({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.badgeNumber,
    required this.target,
    required this.measure,
  });

  /// Progress from 0 to 100.
  int progressFor(CookingStats stats, UserProfile profile) =>
      (measure(stats, profile) * 100 ~/ target).clamp(0, 100);
}

/// All badges, computed from real cooking history (nothing is pre-earned).
class BadgeRules {
  BadgeRules._();

  static final List<BadgeRule> all = [
    BadgeRule(
      id: 'first_recipe',
      name: 'First Spark',
      emoji: '✨',
      description: 'Cook your first Fridgenie recipe.',
      badgeNumber: 1,
      target: 1,
      measure: (_, profile) => profile.recipesCooked,
    ),
    BadgeRule(
      id: 'streak_7',
      name: 'Week Warrior',
      emoji: '🔥',
      description: '7-day cooking streak.',
      badgeNumber: 2,
      target: 7,
      measure: (_, profile) => profile.longestStreak,
    ),
    BadgeRule(
      id: 'use_it_up',
      name: 'Waste Saver',
      emoji: '♻️',
      description: 'Cook 5 use-it-up meals.',
      badgeNumber: 3,
      target: 5,
      measure: (stats, _) => stats.useItUpCooked,
    ),
    BadgeRule(
      id: 'cuisine_explorer',
      name: 'Globetrotter',
      emoji: '🌍',
      description: 'Try recipes from 5 cuisines.',
      badgeNumber: 4,
      target: 5,
      measure: (stats, _) => stats.cuisinesCooked.length,
    ),
    BadgeRule(
      id: 'surprise_chef',
      name: 'Wildcard',
      emoji: '🎲',
      description: 'Cook 3 Surprise-Me suggestions.',
      badgeNumber: 5,
      target: 3,
      measure: (stats, _) => stats.surpriseCooked,
    ),
    BadgeRule(
      id: 'three_ingredient',
      name: 'Minimalist',
      emoji: '🪶',
      description: 'Win the 3-ingredient challenge.',
      badgeNumber: 6,
      target: 1,
      measure: (stats, _) => stats.challengeCooked,
    ),
    BadgeRule(
      id: 'mood_tracker',
      name: 'In Tune',
      emoji: '🌈',
      description: 'Cook for 5 different moods.',
      badgeNumber: 7,
      target: 5,
      measure: (stats, _) => stats.moodsCooked.length,
    ),
    BadgeRule(
      id: 'midnight',
      name: 'Midnight Chef',
      emoji: '🌙',
      description: 'Cook a recipe after 10pm.',
      badgeNumber: 8,
      target: 1,
      measure: (stats, _) => stats.lateNightCooked,
    ),
    BadgeRule(
      id: 'ai_pioneer',
      name: 'AI Pioneer',
      emoji: '🤖',
      description: 'Generate 10 recipes with Genie AI.',
      badgeNumber: 9,
      target: 10,
      measure: (stats, _) => stats.aiRecipesGenerated,
    ),
    BadgeRule(
      id: 'speed_cook',
      name: 'Speed Cook',
      emoji: '⚡',
      description: 'Cook 5 recipes under 20 minutes.',
      badgeNumber: 10,
      target: 5,
      measure: (stats, _) => stats.quickCooked,
    ),
  ];

  /// Builds the badge list; a badge stays earned once it was earned.
  static List<CookingBadge> evaluate(CookingStats stats, UserProfile profile) {
    return [
      for (final rule in all)
        _badge(
          rule,
          stats.badgesEarnedOn[rule.id],
          rule.progressFor(stats, profile),
        ),
    ];
  }

  /// Ids whose target is reached now but that were not earned before.
  static List<String> newlyEarned(CookingStats stats, UserProfile profile) => [
        for (final rule in all)
          if (!stats.badgesEarnedOn.containsKey(rule.id) &&
              rule.progressFor(stats, profile) >= 100)
            rule.id,
      ];

  static CookingBadge _badge(BadgeRule rule, DateTime? earnedOn, int progress) {
    final earned = earnedOn != null || progress >= 100;
    return CookingBadge(
      id: rule.id,
      name: rule.name,
      emoji: rule.emoji,
      description: rule.description,
      badgeNumber: rule.badgeNumber,
      earned: earned,
      progress: earned ? 100 : progress,
      earnedDate: earnedOn?.toIso8601String(),
    );
  }
}
