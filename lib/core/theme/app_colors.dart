import 'package:flutter/material.dart';

/// Fridgenie color system — Fresh Green + Citrus.
///
/// Inspired by Pinterest food aesthetics, with Duolingo-bright energy.
/// Greens = freshness & nature. Citrus yellow = playfulness & joy.
/// Warm cream backgrounds = cozy, food-friendly.
class AppColors {
  AppColors._();

  // ── Primary: Leaf green ───────────────────────────────────────────────
  static const Color primary = Color(0xFF3DA35D);
  static const Color primaryDark = Color(0xFF1F6B3A);
  static const Color primaryLight = Color(0xFF8AD49C);
  static const Color primarySurface = Color(0xFFE2F3DF);

  // ── Accent: Citrus / lemon ────────────────────────────────────────────
  static const Color citrus = Color(0xFFFFD23F);
  static const Color citrusDeep = Color(0xFFFFA630);
  static const Color citrusSurface = Color(0xFFFFF6D6);

  // ── Tertiary: Tomato / coral (for warmth) ─────────────────────────────
  static const Color tomato = Color(0xFFFF6B6B);
  static const Color tomatoSurface = Color(0xFFFFE3E3);

  // ── Surfaces / neutrals ───────────────────────────────────────────────
  static const Color background = Color(0xFFFAF8F1); // cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF2EFE5);
  static const Color outline = Color(0xFFE5E1D4);

  // ── Text ──────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1B2E22); // deep forest
  static const Color textSecondary = Color(0xFF5F6F62);
  static const Color textTertiary = Color(0xFF96A199);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Status ────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF3DA35D);
  static const Color warning = Color(0xFFFFA630);
  static const Color error = Color(0xFFE5484D);
  static const Color info = Color(0xFF4A9DDB);

  // ── Mood palette (for mood-based cooking) ─────────────────────────────
  static const Color moodCozy = Color(0xFFFFB088);
  static const Color moodEnergetic = Color(0xFFFFD23F);
  static const Color moodCalm = Color(0xFF9DC3E6);
  static const Color moodCelebratory = Color(0xFFE6A4D4);
  static const Color moodAdventurous = Color(0xFFC07AE0);
  static const Color moodComfort = Color(0xFFD49C6B);

  // ── Category accents (for recipe categories) ──────────────────────────
  static const Color catComfort = Color(0xFFD49C6B);
  static const Color catHealthy = Color(0xFF3DA35D);
  static const Color catQuick = Color(0xFFFFA630);
  static const Color catBudget = Color(0xFF7FB069);
  static const Color catUseItUp = Color(0xFFE5854A);

  // ── Gradients ─────────────────────────────────────────────────────────
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE2F3DF), Color(0xFFFFF6D6)],
  );

  static const LinearGradient citrusGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD23F), Color(0xFFFFA630)],
  );

  static const LinearGradient leafGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8AD49C), Color(0xFF3DA35D)],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD23F), Color(0xFFFF6B6B)],
  );

  static const LinearGradient calmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFAF8F1), Color(0xFFE2F3DF)],
  );
}
