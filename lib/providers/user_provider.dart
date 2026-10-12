import 'package:flutter/foundation.dart';

import '../data/models/badge.dart';
import '../data/models/cooking_stats.dart';
import '../data/models/enums.dart';
import '../data/models/recipe.dart';
import '../data/models/user_profile.dart';
import '../data/services/badge_rules.dart';
import '../data/storage/local_store.dart';
import '../data/storage/storage_keys.dart';

class UserProvider extends ChangeNotifier {
  UserProvider(this._store, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _onboardingDone = _store.getBool(StorageKeys.onboardingDone) ?? false;
    _profile = _loadProfile();
    _stats =
        CookingStats.fromJson(_store.readJsonMap(StorageKeys.cookingStats));
    _expireStreak();
    _badges = BadgeRules.evaluate(_stats, _profile);
    debugPrint('$_tag loaded profile "${_profile.name}", '
        'onboarding ${_onboardingDone ? 'done' : 'pending'}, '
        'streak ${_profile.currentStreak}, $earnedBadgeCount badges');
  }

  static const _tag = '[UserProvider]';

  final LocalStore _store;

  /// Injectable clock so streak rules can be tested across days.
  final DateTime Function() _clock;
  UserProfile _profile = const UserProfile();
  bool _onboardingDone = false;

  UserProfile get profile => _profile;
  bool get onboardingDone => _onboardingDone;

  /// Reads the saved profile; unknown enum names are skipped, not defaulted.
  UserProfile _loadProfile() {
    const defaults = UserProfile();
    final dietary = _names(StorageKeys.dietary, DietaryPreference.values);
    final cuisines = _names(StorageKeys.cuisines, CuisineType.values);

    return defaults.copyWith(
      name: _store.getString(StorageKeys.name),
      dietary: dietary == null || dietary.isEmpty ? null : dietary,
      skill: _name(StorageKeys.skill, CookingSkill.values),
      favoriteCuisines: cuisines == null || cuisines.isEmpty ? null : cuisines,
      defaultMood: _name(StorageKeys.mood, Mood.values),
      avatarEmoji: _store.getString(StorageKeys.avatarEmoji),
      avatarBgColor: _store.getInt(StorageKeys.avatarBgColor),
      recipesCooked: _store.getInt(StorageKeys.recipesCooked),
      currentStreak: _store.getInt(StorageKeys.currentStreak),
      longestStreak: _store.getInt(StorageKeys.longestStreak),
      lastCookedOn: DateTime.tryParse(
        _store.getString(StorageKeys.lastCookedOn) ?? '',
      ),
    );
  }

  T? _name<T extends Enum>(String key, List<T> values) {
    final stored = _store.getString(key);
    return values.where((v) => v.name == stored).firstOrNull;
  }

  Set<T>? _names<T extends Enum>(String key, List<T> values) {
    final stored = _store.getStringList(key);
    if (stored == null) return null;
    return values.where((v) => stored.contains(v.name)).toSet();
  }

  /// Writes every profile field; called after any profile change.
  void _persistProfile() {
    final p = _profile;
    _store.setString(StorageKeys.name, p.name);
    _store.setStringList(
        StorageKeys.dietary, p.dietary.map((e) => e.name).toList());
    _store.setString(StorageKeys.skill, p.skill.name);
    _store.setStringList(
        StorageKeys.cuisines, p.favoriteCuisines.map((e) => e.name).toList());
    _store.setString(StorageKeys.mood, p.defaultMood.name);
    final emoji = p.avatarEmoji;
    emoji == null
        ? _store.remove(StorageKeys.avatarEmoji)
        : _store.setString(StorageKeys.avatarEmoji, emoji);
    final color = p.avatarBgColor;
    color == null
        ? _store.remove(StorageKeys.avatarBgColor)
        : _store.setInt(StorageKeys.avatarBgColor, color);
    _store.setInt(StorageKeys.recipesCooked, p.recipesCooked);
    _store.setInt(StorageKeys.currentStreak, p.currentStreak);
    _store.setInt(StorageKeys.longestStreak, p.longestStreak);
    final lastCooked = p.lastCookedOn;
    lastCooked == null
        ? _store.remove(StorageKeys.lastCookedOn)
        : _store.setString(
            StorageKeys.lastCookedOn, lastCooked.toIso8601String());
  }

  Future<void> setAvatarEmoji(String emoji) async {
    _profile = _profile.copyWith(avatarEmoji: emoji);
    _persistProfile();
    notifyListeners();
  }

  Future<void> setAvatarBgColor(int colorValue) async {
    _profile = _profile.copyWith(avatarBgColor: colorValue);
    _persistProfile();
    notifyListeners();
  }

  // ── Onboarding state mutators ──────────────────────────────────────────
  void setName(String name) {
    _profile = _profile.copyWith(name: name);
    notifyListeners();
  }

  void setDietary(Set<DietaryPreference> dietary) {
    _profile = _profile.copyWith(dietary: dietary);
    notifyListeners();
  }

  void setSkill(CookingSkill skill) {
    _profile = _profile.copyWith(skill: skill);
    notifyListeners();
  }

  void setFavoriteCuisines(Set<CuisineType> cuisines) {
    _profile = _profile.copyWith(favoriteCuisines: cuisines);
    notifyListeners();
  }

  void setMood(Mood mood) {
    _profile = _profile.copyWith(defaultMood: mood);
    notifyListeners();
  }

  /// Saves the answers collected during onboarding.
  Future<void> completeOnboarding() async {
    _onboardingDone = true;
    _store.setBool(StorageKeys.onboardingDone, true);
    _persistProfile();
    debugPrint('$_tag onboarding completed');
    notifyListeners();
  }

  /// Shows onboarding again; the profile is kept and pre-fills the answers.
  Future<void> resetOnboarding() async {
    _onboardingDone = false;
    _store.setBool(StorageKeys.onboardingDone, false);
    debugPrint('$_tag onboarding reset');
    notifyListeners();
  }

  // ── Cooking events, streaks and badges ─────────────────────────────────
  CookingStats _stats = const CookingStats();
  List<CookingBadge> _badges = const [];

  List<CookingBadge> get badges => List.unmodifiable(_badges);
  int get earnedBadgeCount => _badges.where((b) => b.earned).length;

  /// Records a cooked recipe: counters, a calendar-day streak and badges.
  CookResult recordCookedRecipe(
    Recipe recipe, {
    bool fromSurprise = false,
    bool fromChallenge = false,
  }) {
    final now = _clock();
    final today = _dateOnly(now);
    final last = _profile.lastCookedOn;
    final gap = last == null ? null : _daysBetween(last, today);
    final previousStreak = _profile.currentStreak;

    // Same day keeps the streak, the next day extends it, a gap restarts it.
    final streak = switch (gap) {
      null => 1,
      1 => previousStreak + 1,
      int days when days <= 0 => previousStreak < 1 ? 1 : previousStreak,
      _ => 1,
    };

    _profile = _profile.copyWith(
      recipesCooked: _profile.recipesCooked + 1,
      currentStreak: streak,
      longestStreak: streak > _profile.longestStreak
          ? streak
          : _profile.longestStreak,
      lastCookedOn: today,
    );

    final quick = recipe.cookMinutes > 0 && recipe.cookMinutes <= 20;
    final lateNight = now.hour >= 22 || now.hour < 4;
    _stats = _stats.copyWith(
      useItUpCooked: _stats.useItUpCooked +
          (recipe.category == RecipeCategory.useItUp ? 1 : 0),
      quickCooked: _stats.quickCooked + (quick ? 1 : 0),
      lateNightCooked: _stats.lateNightCooked + (lateNight ? 1 : 0),
      surpriseCooked: _stats.surpriseCooked + (fromSurprise ? 1 : 0),
      challengeCooked: _stats.challengeCooked + (fromChallenge ? 1 : 0),
      cuisinesCooked: {..._stats.cuisinesCooked, ...recipe.cuisines},
      moodsCooked: {..._stats.moodsCooked, ...recipe.matchingMoods},
    );

    final newBadges = _awardBadges(today);
    _persistProfile();
    _persistStats();
    debugPrint('$_tag cooked "${recipe.title}": streak $previousStreak -> '
        '$streak, total ${_profile.recipesCooked}, new badges $newBadges');
    notifyListeners();

    return CookResult(
      streak: streak,
      streakIncreased: streak > previousStreak,
      newBadges: _badges.where((b) => newBadges.contains(b.id)).toList(),
    );
  }

  /// Counts one recipe generated by the real AI (for the AI Pioneer badge).
  void recordAiRecipeGenerated() {
    _stats = _stats.copyWith(aiRecipesGenerated: _stats.aiRecipesGenerated + 1);
    _awardBadges(_dateOnly(_clock()));
    _persistStats();
    notifyListeners();
  }

  /// Stamps newly reached badges with [today] and refreshes the badge list.
  List<String> _awardBadges(DateTime today) {
    final newIds = BadgeRules.newlyEarned(_stats, _profile);
    if (newIds.isNotEmpty) {
      _stats = _stats.copyWith(badgesEarnedOn: {
        ..._stats.badgesEarnedOn,
        for (final id in newIds) id: today,
      });
      debugPrint('$_tag badges earned: $newIds');
    }
    _badges = BadgeRules.evaluate(_stats, _profile);
    return newIds;
  }

  /// A streak whose last cooking day is before yesterday is over.
  void _expireStreak() {
    final last = _profile.lastCookedOn;
    if (last == null || _profile.currentStreak == 0) return;
    if (_daysBetween(last, _dateOnly(_clock())) > 1) {
      debugPrint('$_tag streak of ${_profile.currentStreak} expired');
      _profile = _profile.copyWith(currentStreak: 0);
      _persistProfile();
    }
  }

  void _persistStats() =>
      _store.setJson(StorageKeys.cookingStats, _stats.toJson());

  static DateTime _dateOnly(DateTime time) =>
      DateTime(time.year, time.month, time.day);

  /// Whole calendar days from [from] to [to], immune to daylight-saving shifts.
  static int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
        to.year,
        to.month,
        to.day,
      ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
}

/// What happened when a recipe was marked as cooked, for UI feedback.
class CookResult {
  final int streak;
  final bool streakIncreased;
  final List<CookingBadge> newBadges;

  const CookResult({
    required this.streak,
    required this.streakIncreased,
    required this.newBadges,
  });
}
