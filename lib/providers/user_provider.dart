import 'package:flutter/foundation.dart';

import '../data/models/badge.dart';
import '../data/models/enums.dart';
import '../data/models/user_profile.dart';

class UserProvider extends ChangeNotifier {
  UserProfile _profile = const UserProfile();
  bool _onboardingDone = false;

  UserProfile get profile => _profile;
  bool get onboardingDone => _onboardingDone;

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

  void completeOnboarding() {
    _onboardingDone = true;
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
