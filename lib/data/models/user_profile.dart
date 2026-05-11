import 'enums.dart';

class TasteProfile {
  /// 0..1 weights describing how much the user leans into each axis.
  final double sweet;
  final double savory;
  final double spicy;
  final double fresh;
  final double comforting;
  final double adventurous;

  const TasteProfile({
    this.sweet = 0.5,
    this.savory = 0.6,
    this.spicy = 0.4,
    this.fresh = 0.5,
    this.comforting = 0.6,
    this.adventurous = 0.5,
  });

  Map<String, double> get axes => {
        'Sweet': sweet,
        'Savory': savory,
        'Spicy': spicy,
        'Fresh': fresh,
        'Comforting': comforting,
        'Adventurous': adventurous,
      };

  TasteProfile copyWith({
    double? sweet,
    double? savory,
    double? spicy,
    double? fresh,
    double? comforting,
    double? adventurous,
  }) {
    return TasteProfile(
      sweet: sweet ?? this.sweet,
      savory: savory ?? this.savory,
      spicy: spicy ?? this.spicy,
      fresh: fresh ?? this.fresh,
      comforting: comforting ?? this.comforting,
      adventurous: adventurous ?? this.adventurous,
    );
  }
}

class UserProfile {
  final String name;
  final Set<DietaryPreference> dietary;
  final CookingSkill skill;
  final Set<CuisineType> favoriteCuisines;
  final Mood defaultMood;
  final TasteProfile taste;

  /// Customisable avatar fields (null = use defaults).
  final String? avatarImagePath;
  final int? avatarBgColor; // stored as ARGB int

  /// These values should be updated by UserProvider when the user cooks/saves meals.
  final int currentStreak;
  final int longestStreak;
  final int recipesCooked;
  final int wasteSavedGrams;

  const UserProfile({
    this.name = 'Chef',
    this.dietary = const {DietaryPreference.noRestrictions},
    this.skill = CookingSkill.comfortable,
    this.favoriteCuisines = const {
      CuisineType.italian,
      CuisineType.mediterranean,
    },
    this.defaultMood = Mood.cozy,
    this.taste = const TasteProfile(),
    this.avatarImagePath,
    this.avatarBgColor,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.recipesCooked = 0,
    this.wasteSavedGrams = 0,
  });

  UserProfile copyWith({
    String? name,
    Set<DietaryPreference>? dietary,
    CookingSkill? skill,
    Set<CuisineType>? favoriteCuisines,
    Mood? defaultMood,
    TasteProfile? taste,
    Object? avatarImagePath = _sentinel,
    Object? avatarBgColor = _sentinel,
    int? currentStreak,
    int? longestStreak,
    int? recipesCooked,
    int? wasteSavedGrams,
  }) {
    return UserProfile(
      name: name ?? this.name,
      dietary: dietary ?? this.dietary,
      skill: skill ?? this.skill,
      favoriteCuisines: favoriteCuisines ?? this.favoriteCuisines,
      defaultMood: defaultMood ?? this.defaultMood,
      taste: taste ?? this.taste,
      avatarImagePath: avatarImagePath == _sentinel
          ? this.avatarImagePath
          : avatarImagePath as String?,
      avatarBgColor: avatarBgColor == _sentinel
          ? this.avatarBgColor
          : avatarBgColor as int?,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      recipesCooked: recipesCooked ?? this.recipesCooked,
      wasteSavedGrams: wasteSavedGrams ?? this.wasteSavedGrams,
    );
  }
}

// Sentinel for nullable copyWith fields
const _sentinel = Object();