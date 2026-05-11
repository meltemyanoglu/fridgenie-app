import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/badge.dart';
import '../data/models/enums.dart';
import '../data/models/user_profile.dart';

class UserProvider extends ChangeNotifier {
  UserProfile _profile = const UserProfile();
  bool _onboardingDone = false;

  UserProfile get profile => _profile;
  bool get onboardingDone => _onboardingDone;

  // ── Persistence keys ────────────────────────────────────────────────────
  static const _kOnboardingDone = 'fridgenie.onboarding_done';
  static const _kName = 'fridgenie.name';
  static const _kDietary = 'fridgenie.dietary';
  static const _kSkill = 'fridgenie.skill';
  static const _kCuisines = 'fridgenie.cuisines';
  static const _kMood = 'fridgenie.mood';
  static const _kAvatarImage = 'fridgenie.avatar_image';
  static const _kAvatarBgColor = 'fridgenie.avatar_bg_color';

  /// Hydrate state from SharedPreferences. Call once at app start.
  Future<void> hydrate() async {
    final p = await SharedPreferences.getInstance();
    _onboardingDone = p.getBool(_kOnboardingDone) ?? false;
    final name = p.getString(_kName) ?? _profile.name;
    final dietaryNames = p.getStringList(_kDietary);
    final skillName = p.getString(_kSkill);
    final cuisineNames = p.getStringList(_kCuisines);
    final moodName = p.getString(_kMood);

    final dietary = dietaryNames == null
        ? _profile.dietary
        : dietaryNames
            .map((n) => DietaryPreference.values
                .firstWhere((e) => e.name == n, orElse: () => DietaryPreference.noRestrictions))
            .toSet();

    final skill = skillName == null
        ? _profile.skill
        : CookingSkill.values.firstWhere(
            (e) => e.name == skillName,
            orElse: () => CookingSkill.comfortable,
          );

    final cuisines = cuisineNames == null
        ? _profile.favoriteCuisines
        : cuisineNames
            .map((n) => CuisineType.values
                .firstWhere((e) => e.name == n, orElse: () => CuisineType.italian))
            .toSet();

    final mood = moodName == null
        ? _profile.defaultMood
        : Mood.values.firstWhere(
            (e) => e.name == moodName,
            orElse: () => Mood.cozy,
          );

    final avatarImage = p.getString(_kAvatarImage);
    final avatarBgColor = p.getInt(_kAvatarBgColor);

    _profile = _profile.copyWith(
      name: name,
      dietary: dietary,
      skill: skill,
      favoriteCuisines: cuisines,
      defaultMood: mood,
      avatarImagePath: avatarImage,
      avatarBgColor: avatarBgColor,
    );
    notifyListeners();
  }

  Future<void> _persistProfile() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, _profile.name);
    await p.setStringList(
      _kDietary,
      _profile.dietary.map((e) => e.name).toList(),
    );
    await p.setString(_kSkill, _profile.skill.name);
    await p.setStringList(
      _kCuisines,
      _profile.favoriteCuisines.map((e) => e.name).toList(),
    );
    await p.setString(_kMood, _profile.defaultMood.name);
    if (_profile.avatarImagePath != null) {
      await p.setString(_kAvatarImage, _profile.avatarImagePath!);
    } else {
      await p.remove(_kAvatarImage);
    }
    if (_profile.avatarBgColor != null) {
      await p.setInt(_kAvatarBgColor, _profile.avatarBgColor!);
    } else {
      await p.remove(_kAvatarBgColor);
    }
  }

  Future<void> setAvatarImage(String path) async {
    _profile = _profile.copyWith(avatarImagePath: path);
    notifyListeners();
    await _persistProfile();
  }

  Future<void> setAvatarBgColor(int colorValue) async {
    _profile = _profile.copyWith(avatarBgColor: colorValue);
    notifyListeners();
    await _persistProfile();
  }

  Future<void> clearAvatarImage() async {
    _profile = _profile.copyWith(avatarImagePath: null);
    notifyListeners();
    await _persistProfile();
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

  Future<void> completeOnboarding() async {
    _onboardingDone = true;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOnboardingDone, true);
    await _persistProfile();
    notifyListeners();
  }

  /// Wipe stored profile + onboarding flag (used by "restart onboarding").
  Future<void> resetOnboarding() async {
    _onboardingDone = false;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOnboardingDone, false);
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
    notifyListeners();
  }

  // ── Badges ─────────────────────────────────────────────────────────────
  List<CookingBadge> _badges = [
    const CookingBadge(
      id: 'first_recipe',
      name: 'First Spark',
      emoji: '✨',
      description: 'Cook your first Fridgenie recipe.',
      earned: true,
      progress: 100,
    ),
    const CookingBadge(
      id: 'streak_7',
      name: 'Week Warrior',
      emoji: '🔥',
      description: '7-day cooking streak.',
      earned: false,
      progress: 57,
    ),
    const CookingBadge(
      id: 'use_it_up',
      name: 'Waste Saver',
      emoji: '♻️',
      description: 'Cook 5 use-it-up meals.',
      earned: false,
      progress: 60,
    ),
    const CookingBadge(
      id: 'cuisine_explorer',
      name: 'Globetrotter',
      emoji: '🌍',
      description: 'Try recipes from 5 cuisines.',
      earned: true,
      progress: 100,
    ),
    const CookingBadge(
      id: 'surprise_chef',
      name: 'Wildcard',
      emoji: '🎲',
      description: 'Cook 3 Surprise-Me suggestions.',
      earned: false,
      progress: 33,
    ),
    const CookingBadge(
      id: 'three_ingredient',
      name: 'Minimalist',
      emoji: '🪶',
      description: 'Win the 3-ingredient challenge.',
      earned: true,
      progress: 100,
    ),
    const CookingBadge(
      id: 'mood_tracker',
      name: 'In Tune',
      emoji: '🌈',
      description: 'Cook for 5 different moods.',
      earned: false,
      progress: 80,
    ),
    const CookingBadge(
      id: 'midnight',
      name: 'Midnight Chef',
      emoji: '🌙',
      description: 'Cook a recipe after 10pm.',
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
