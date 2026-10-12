import '../mock/mock_ingredients.dart';
import '../models/ingredient.dart';

/// Maps free-text ingredient names from the AI to catalog [Ingredient]s.
/// Matches whole words only, so "eggplant" never becomes "eggs".
class IngredientMatcher {
  IngredientMatcher({List<Ingredient> catalog = MockIngredients.all})
      : _index = _buildIndex(catalog);

  final Map<String, Ingredient> _index;

  /// Names that should map to a specific catalog id (or to nothing).
  static const Map<String, String?> _synonyms = {
    'scallion': 'onion',
    'green onion': 'onion',
    'spring onion': 'onion',
    'shallot': 'onion',
    'courgette': 'zucchini',
    'aubergine': 'eggplant',
    'capsicum': 'bell_pepper',
    'sweet pepper': 'bell_pepper',
    'red pepper': 'bell_pepper',
    'green pepper': 'bell_pepper',
    'yellow pepper': 'bell_pepper',
    'black pepper': null,
    'white pepper': null,
    'pepper': null,
    'coriander': 'cilantro',
    'garbanzo': 'chickpeas',
    'garbanzo bean': 'chickpeas',
    'broth': 'stock',
    'chilli': 'chili',
    'chili pepper': 'chili',
    'red chili': 'chili',
    'jalapeno': 'chili',
    'spaghetti': 'pasta',
    'penne': 'pasta',
    'macaroni': 'pasta',
    'fusilli': 'pasta',
    'prawn': 'shrimp',
    'ramen': 'noodles',
    'parmigiano': 'parmesan',
    'parmesan cheese': 'parmesan',
    'feta cheese': 'feta',
    'mozzarella cheese': 'mozzarella',
    'heavy cream': 'cream',
    'egg white': 'eggs',
    'egg yolk': 'eggs',
    'red pepper flake': 'chili',
    'ice cream': null,
    'peanut': null,
    'olive': null,
  };

  static const Map<String, String> _accents = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ç': 'c', 'è': 'e', 'é': 'e',
    'ê': 'e', 'ë': 'e', 'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ñ': 'n',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'ù': 'u', 'ú': 'u', 'û': 'u',
    'ü': 'u', 'ş': 's', 'ğ': 'g', 'ı': 'i',
  };

  /// Returns the catalog item for [name], or null when nothing fits.
  /// Tries the longest word sequence first; ties go to the last word
  /// (the head noun: "chicken stock" is stock, "chicken breast" is chicken).
  Ingredient? match(String name) {
    final words = _normalize(name);
    if (words.isEmpty) return null;

    for (var length = words.length; length >= 1; length--) {
      for (var start = words.length - length; start >= 0; start--) {
        final phrase = words.sublist(start, start + length).join(' ');
        if (_synonyms.containsKey(phrase)) {
          final id = _synonyms[phrase];
          return id == null ? null : MockIngredients.byId(id);
        }
        final hit = _index[phrase];
        if (hit != null) return hit;
      }
    }
    return null;
  }

  /// Matches every name; returns unique catalog items and unmatched names.
  IngredientMatchResult matchAll(Iterable<String> names) {
    final matched = <Ingredient>{};
    final unmatched = <String>[];
    for (final name in names) {
      final hit = match(name);
      if (hit != null) {
        matched.add(hit);
      } else if (name.trim().isNotEmpty) {
        unmatched.add(name.trim().toLowerCase());
      }
    }
    return IngredientMatchResult(matched.toList(), unmatched);
  }

  static Map<String, Ingredient> _buildIndex(List<Ingredient> catalog) {
    final index = <String, Ingredient>{};
    for (final ingredient in catalog) {
      for (final key in [ingredient.name, ingredient.id.replaceAll('_', ' ')]) {
        index.putIfAbsent(_normalize(key).join(' '), () => ingredient);
      }
    }
    return index;
  }

  /// Lowercases, folds accents, keeps letters/digits, singularizes each word.
  static List<String> _normalize(String raw) => raw
      .toLowerCase()
      .split('')
      .map((char) => _accents[char] ?? char)
      .join()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map(_singular)
      .toList();

  static String _singular(String word) {
    if (word.length <= 3) return word;
    if (word.endsWith('ies')) return '${word.substring(0, word.length - 3)}y';
    if (word.endsWith('oes')) return word.substring(0, word.length - 2);
    if (word.endsWith('ss') || word.endsWith('us')) return word;
    if (word.endsWith('s')) return word.substring(0, word.length - 1);
    return word;
  }
}

/// Outcome of [IngredientMatcher.matchAll].
class IngredientMatchResult {
  final List<Ingredient> matched;
  final List<String> unmatched;

  const IngredientMatchResult(this.matched, this.unmatched);
}
