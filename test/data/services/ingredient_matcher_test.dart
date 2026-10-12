import 'package:flutter_test/flutter_test.dart';
import 'package:fridgenie/data/services/ingredient_matcher.dart';

void main() {
  final matcher = IngredientMatcher();

  String? idOf(String name) => matcher.match(name)?.id;

  group('IngredientMatcher.match', () {
    test('matches names, ids and plurals', () {
      expect(idOf('Tomato'), 'tomato');
      expect(idOf('tomatoes'), 'tomato');
      expect(idOf('egg'), 'eggs');
      expect(idOf('Eggs'), 'eggs');
      expect(idOf('olive oil'), 'olive_oil');
      expect(idOf('sweet potatoes'), 'sweet_potato');
      expect(idOf('green beans'), 'green_bean');
    });

    test('never matches inside another word', () {
      expect(idOf('eggplant'), 'eggplant');
      expect(idOf('pineapple'), isNull);
      expect(idOf('cornflakes'), isNull);
    });

    test('prefers the longest phrase, then the head noun', () {
      expect(idOf('peanut butter'), 'peanut_butter');
      expect(idOf('red bell pepper'), 'bell_pepper');
      expect(idOf('chicken stock'), 'stock');
      expect(idOf('chicken breast'), 'chicken');
      expect(idOf('greek yogurt'), 'yogurt');
      expect(idOf('tomato sauce'), 'tomato_sauce');
    });

    test('applies synonyms, including explicit non-matches', () {
      expect(idOf('scallions'), 'onion');
      expect(idOf('aubergine'), 'eggplant');
      expect(idOf('spaghetti'), 'pasta');
      expect(idOf('parmesan cheese'), 'parmesan');
      expect(idOf('black pepper'), isNull);
      expect(idOf('olives'), isNull);
    });

    test('folds accents and ignores punctuation', () {
      expect(idOf('Jalapeño'), 'chili');
      expect(idOf('Jalapen\u0303o'), 'chili');
      expect(idOf('oat milk'), isNull);
      expect(idOf('  Garlic, minced '), 'garlic');
      expect(idOf(''), isNull);
      expect(idOf('!!!'), isNull);
    });
  });

  group('IngredientMatcher.matchAll', () {
    test('de-duplicates matches and keeps unmatched names', () {
      final result = matcher.matchAll(['tomato', 'Tomatoes', 'saffron', ' ']);
      expect(result.matched.map((i) => i.id), ['tomato']);
      expect(result.unmatched, ['saffron']);
    });
  });
}
