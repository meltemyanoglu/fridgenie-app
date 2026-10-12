import 'package:flutter/foundation.dart';

import '../data/models/badge.dart';
import '../data/models/enums.dart';
import '../data/models/user_profile.dart';
import '../data/storage/local_store.dart';
import '../data/storage/storage_keys.dart';

class UserProvider extends ChangeNotifier {
  UserProvider(this._store) {
    _onboardingDone = _store.getBool(StorageKeys.onboardingDone) ?? false;
    _profile = _loadProfile();
    debugPrint('$_tag loaded profile "${_profile.name}", '
        'onboarding ${_onboardingDone ? 'done' : 'pending'}');
  }

  static const _tag = '[UserProvider]';

  final LocalStore _store;
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

  // ── Cooking events ─────────────────────────────────────────────────────
  void recordCookedRecipe() {
    _profile = _profile.copyWith(
      recipesCooked: _profile.recipesCooked + 1,
      currentStreak: _profile.currentStreak + 1,
      longestStreak: (_profile.currentStreak + 1) > _profile.longestStreak
          ? _profile.currentStreak + 1
          : _profile.longestStreak,
    );
    _evaluateBadges();
    _persistProfile();
    notifyListeners();
  }

  // ── Badges ─────────────────────────────────────────────────────────────
  List<CookingBadge> _badges = [
    const CookingBadge(
      id: 'first_recipe',
      name: 'First Spark',
      emoji: '✨',
      description: 'Cook your first Fridgenie recipe.',
      badgeNumber: 1,
      earned: true,
      progress: 100,
    ),
    const CookingBadge(
      id: 'streak_7',
      name: 'Week Warrior',
      emoji: '🔥',
      description: '7-day cooking streak.',
      badgeNumber: 2,
      earned: false,
      progress: 57,
    ),
    const CookingBadge(
      id: 'use_it_up',
      name: 'Waste Saver',
      emoji: '♻️',
      description: 'Cook 5 use-it-up meals.',
      badgeNumber: 3,
      earned: false,
      progress: 60,
    ),
    const CookingBadge(
      id: 'cuisine_explorer',
      name: 'Globetrotter',
      emoji: '🌍',
      description: 'Try recipes from 5 cuisines.',
      badgeNumber: 4,
      earned: true,
      progress: 100,
    ),
    const CookingBadge(
      id: 'surprise_chef',
      name: 'Wildcard',
      emoji: '🎲',
      description: 'Cook 3 Surprise-Me suggestions.',
      badgeNumber: 5,
      earned: false,
      progress: 33,
    ),
    const CookingBadge(
      id: 'three_ingredient',
      name: 'Minimalist',
      emoji: '🪶',
      description: 'Win the 3-ingredient challenge.',
      badgeNumber: 6,
      earned: true,
      progress: 100,
    ),
    const CookingBadge(
      id: 'mood_tracker',
      name: 'In Tune',
      emoji: '🌈',
      description: 'Cook for 5 different moods.',
      badgeNumber: 7,
      earned: false,
      progress: 80,
    ),
    const CookingBadge(
      id: 'midnight',
      name: 'Midnight Chef',
      emoji: '🌙',
      description: 'Cook a recipe after 10pm.',
      badgeNumber: 8,
      earned: false,
      progress: 0,
    ),
    const CookingBadge(
      id: 'ai_pioneer',
      name: 'AI Pioneer',
      emoji: '🤖',
      description: 'Generate 10 recipes with Genie AI.',
      badgeNumber: 9,
      earned: false,
      progress: 0,
    ),
    const CookingBadge(
      id: 'speed_cook',
      name: 'Speed Cook',
      emoji: '⚡',
      description: 'Cook 5 recipes under 20 minutes.',
      badgeNumber: 10,
      earned: false,
      progress: 0,
    ),
  ];

  List<CookingBadge> get badges => List.unmodifiable(_badges);
  int get earnedBadgeCount => _badges.where((b) => b.earned).length;

  void _evaluateBadges() {
    _badges = _badges.map((b) {
      if (b.id == 'streak_7' && _profile.currentStreak >= 7) {
        return b.copyWith(earned: true, progress: 100);
      }
      return b;
    }).toList();
  }
}
