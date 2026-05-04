import '../models/genie_tip.dart';

class MockTips {
  MockTips._();

  static const List<GenieTip> all = [
    GenieTip(
      id: 'tip_salt',
      title: 'Salt early, salt often',
      body: 'Season at every stage — onions, water, sauce. A pinch each time builds depth no last-minute salt can fake.',
      emoji: '🧂',
    ),
    GenieTip(
      id: 'tip_acid',
      title: 'Acid = secret weapon',
      body: 'Tastes flat? Add lemon, vinegar, or yogurt. Acid wakes up the rest of the dish like a sound check.',
      emoji: '🍋',
    ),
    GenieTip(
      id: 'tip_pasta_water',
      title: 'Pasta water is liquid gold',
      body: 'Reserve a cup before draining. Starchy water emulsifies sauces into something silky and restaurant-grade.',
      emoji: '💧',
    ),
    GenieTip(
      id: 'tip_dry_protein',
      title: 'Dry protein = crispy protein',
      body: 'Pat chicken, tofu, fish dry before searing. Wet surfaces steam instead of brown — the #1 home-cooking miss.',
      emoji: '🧻',
    ),
    GenieTip(
      id: 'tip_garlic_low',
      title: 'Cook garlic low and slow',
      body: 'Burnt garlic is bitter forever. Start it cold in oil over medium-low — patience tastes better.',
      emoji: '🧄',
    ),
    GenieTip(
      id: 'tip_rest_meat',
      title: 'Rest your meat',
      body: 'Let cooked chicken or steak sit 5 minutes before slicing. Juices redistribute; you keep them on the plate, not the cutting board.',
      emoji: '⏱️',
    ),
    GenieTip(
      id: 'tip_taste_finish',
      title: 'Taste before you serve',
      body: 'Always — every single time. A pinch of salt, a squeeze of lemon, a crank of pepper. The last taste is the loudest.',
      emoji: '👅',
    ),
    GenieTip(
      id: 'tip_sharp_knife',
      title: 'A sharp knife is a safe knife',
      body: 'Dull knives slip. If you upgrade one tool this month, sharpen your chef knife.',
      emoji: '🔪',
    ),
    GenieTip(
      id: 'tip_freeze_herbs',
      title: 'Freeze herbs in olive oil',
      body: 'Tray-freeze chopped basil or parsley with olive oil in cubes. Drop into anything sizzling year-round.',
      emoji: '❄️',
    ),
    GenieTip(
      id: 'tip_caramelise_onion',
      title: 'Onions take 30 minutes',
      body: 'Real caramelised onions are a 30-min commitment, not 5. Low heat, occasional stir, big payoff.',
      emoji: '🧅',
    ),
  ];

  static GenieTip ofTheDay(int dayOfYear) =>
      all[dayOfYear % all.length];
}
