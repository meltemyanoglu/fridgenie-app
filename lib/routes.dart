import 'package:flutter/material.dart';

import 'data/models/recipe.dart';
import 'data/services/ai_service.dart';
import 'screens/discover/challenge_screen.dart';
import 'screens/discover/mood_screen.dart';
import 'screens/discover/rescue_screen.dart';
import 'screens/discover/surprise_screen.dart';
import 'screens/discover/swipe_deck_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/pantry/scan_screen.dart';
import 'screens/profile/badges_screen.dart';
import 'screens/recipe/recipe_detail_screen.dart';
import 'screens/shell/app_shell.dart';
import 'screens/splash/splash_screen.dart';

/// Centralised named-route registry. Use `pushNamed(AppRoutes.x)` everywhere
/// to keep navigation typo-proof.
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const shell = '/shell';
  static const recipeDetail = '/recipe';
  static const swipeDeck = '/discover/swipe';
  static const surprise = '/discover/surprise';
  static const challenge = '/discover/challenge';
  static const rescue = '/discover/rescue';
  static const mood = '/discover/mood';
  static const scan = '/pantry/scan';
  static const badges = '/profile/badges';
}

/// Generator that builds the right screen for a route name. We use this so
/// strongly-typed args (Recipe, RankedRecipe) can be passed via settings.
Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.splash:
      return _page(settings, const SplashScreen());
    case AppRoutes.onboarding:
      return _page(settings, const OnboardingScreen());
    case AppRoutes.shell:
      return _page(settings, const AppShell());
    case AppRoutes.recipeDetail:
      final arg = settings.arguments;
      if (arg is RankedRecipe) {
        return _page(settings, RecipeDetailScreen(ranked: arg));
      }
      if (arg is Recipe) {
        return _page(
          settings,
          RecipeDetailScreen(
            ranked: RankedRecipe(
              recipe: arg,
              matchScore: 1.0,
              haveIngredients: arg.requiredIngredientIds,
              missingIngredients: const [],
              aiReason: arg.whyRecommended,
            ),
          ),
        );
      }
      return _notFound(settings);
    case AppRoutes.swipeDeck:
      return _page(settings, const SwipeDeckScreen());
    case AppRoutes.surprise:
      return _page(settings, const SurpriseScreen());
    case AppRoutes.challenge:
      return _page(settings, const ChallengeScreen());
    case AppRoutes.rescue:
      return _page(settings, const RescueScreen());
    case AppRoutes.mood:
      return _page(settings, const MoodScreen());
    case AppRoutes.scan:
      return _page(settings, const ScanScreen());
    case AppRoutes.badges:
      return _page(settings, const BadgesScreen());
    default:
      return _notFound(settings);
  }
}

PageRoute<T> _page<T>(RouteSettings settings, Widget child) =>
    MaterialPageRoute<T>(
      settings: settings,
      builder: (_) => child,
    );

Route<dynamic> _notFound(RouteSettings settings) => MaterialPageRoute(
      settings: settings,
      builder: (_) => Scaffold(
        body: Center(child: Text('Route not found: ${settings.name}')),
      ),
    );
