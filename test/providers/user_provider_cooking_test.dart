import 'package:flutter_test/flutter_test.dart';
import 'package:fridgenie/data/mock/mock_recipes.dart';
import 'package:fridgenie/data/models/enums.dart';
import 'package:fridgenie/data/models/recipe.dart';
import 'package:fridgenie/data/storage/local_store.dart';
import 'package:fridgenie/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStore store;
  late DateTime now;

  UserProvider newUser() => UserProvider(store, clock: () => now);

  Recipe recipe({
    RecipeCategory category = RecipeCategory.comfort,
    int minutes = 30,
    List<CuisineType> cuisines = const [],
  }) =>
      Recipe.fromJson(MockRecipes.all.first.toJson()
        ..['category'] = category.name
        ..['cookMinutes'] = minutes
        ..['cuisines'] = cuisines.map((c) => c.name).toList()
        ..['matchingMoods'] = ['cozy']);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await LocalStore.open();
    now = DateTime(2026, 10, 12, 18);
  });

  group('streaks', () {
    test('cooking twice on the same day counts once', () {
      final user = newUser();
      final first = user.recordCookedRecipe(recipe());
      final second = user.recordCookedRecipe(recipe());

      expect(first.streakIncreased, isTrue);
      expect(second.streakIncreased, isFalse);
      expect(user.profile.currentStreak, 1);
      expect(user.profile.recipesCooked, 2);
    });

    test('consecutive days grow the streak, a gap restarts it', () {
      final user = newUser()..recordCookedRecipe(recipe());
      now = now.add(const Duration(days: 1));
      user.recordCookedRecipe(recipe());
      expect(user.profile.currentStreak, 2);

      now = now.add(const Duration(days: 3));
      user.recordCookedRecipe(recipe());
      expect(user.profile.currentStreak, 1);
      expect(user.profile.longestStreak, 2);
    });

    test('a streak shows 0 after a missed day, but survives "yesterday"', () {
      newUser().recordCookedRecipe(recipe());

      now = now.add(const Duration(days: 1));
      expect(newUser().profile.currentStreak, 1);

      now = now.add(const Duration(days: 1));
      expect(newUser().profile.currentStreak, 0);
    });

    test('a late-night cook just after midnight is the next day', () {
      now = DateTime(2026, 10, 12, 23, 30);
      final user = newUser()..recordCookedRecipe(recipe());
      now = DateTime(2026, 10, 13, 0, 15);
      user.recordCookedRecipe(recipe());
      expect(user.profile.currentStreak, 2);
    });
  });

  group('badges', () {
    test('a new user has no badges', () {
      expect(newUser().earnedBadgeCount, 0);
    });

    test('earning a badge is reported once and survives a restart', () {
      final user = newUser();
      final result = user.recordCookedRecipe(recipe());
      expect(result.newBadges.map((b) => b.id), contains('first_recipe'));
      expect(user.recordCookedRecipe(recipe()).newBadges, isEmpty);

      final restarted = newUser();
      final first = restarted.badges.firstWhere((b) => b.id == 'first_recipe');
      expect(first.earned, isTrue);
      expect(first.earnedDate, isNotNull);
    });

    test('counters drive progress: quick, use-it-up, cuisines, late night', () {
      now = DateTime(2026, 10, 12, 22, 30);
      final user = newUser();
      for (final cuisine in CuisineType.values.take(5)) {
        user.recordCookedRecipe(recipe(
          category: RecipeCategory.useItUp,
          minutes: 15,
          cuisines: [cuisine],
        ));
      }

      bool earned(String id) =>
          user.badges.firstWhere((b) => b.id == id).earned;
      expect(earned('speed_cook'), isTrue);
      expect(earned('use_it_up'), isTrue);
      expect(earned('cuisine_explorer'), isTrue);
      expect(earned('midnight'), isTrue);
      expect(earned('streak_7'), isFalse);
    });

    test('surprise and challenge flags count toward their badges', () {
      final user = newUser()
        ..recordCookedRecipe(recipe(), fromChallenge: true)
        ..recordCookedRecipe(recipe(), fromSurprise: true);

      final surprise = user.badges.firstWhere((b) => b.id == 'surprise_chef');
      expect(surprise.progress, 33);
      expect(
        user.badges.firstWhere((b) => b.id == 'three_ingredient').earned,
        isTrue,
      );
    });

    test('ten AI recipes earn AI Pioneer', () {
      final user = newUser();
      for (var i = 0; i < 10; i++) {
        user.recordAiRecipeGenerated();
      }
      expect(user.badges.firstWhere((b) => b.id == 'ai_pioneer').earned, isTrue);
    });
  });
}
