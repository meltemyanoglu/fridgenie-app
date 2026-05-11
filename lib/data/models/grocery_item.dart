import 'dart:convert';

class GroceryItem {
  final String id;
  final String name;
  final String emoji;
  bool isChecked;

  GroceryItem({
    required this.id,
    required this.name,
    required this.emoji,
    this.isChecked = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'isChecked': isChecked,
      };

  factory GroceryItem.fromJson(Map<String, dynamic> j) => GroceryItem(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: (j['emoji'] as String?) ?? '🛒',
        isChecked: (j['isChecked'] as bool?) ?? false,
      );

  static List<GroceryItem> listFromJson(String raw) {
    final list = jsonDecode(raw) as List;
    return list.map((e) => GroceryItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<GroceryItem> items) =>
      jsonEncode(items.map((i) => i.toJson()).toList());
}
