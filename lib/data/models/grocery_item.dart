/// One line on the shopping list; immutable, so change it with [copyWith].
class GroceryItem {
  final String id;
  final String name;
  final String emoji;
  final bool isChecked;

  const GroceryItem({
    required this.id,
    required this.name,
    required this.emoji,
    this.isChecked = false,
  });

  GroceryItem copyWith({bool? isChecked}) => GroceryItem(
        id: id,
        name: name,
        emoji: emoji,
        isChecked: isChecked ?? this.isChecked,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'isChecked': isChecked,
      };

  /// Throws [FormatException] when `id` or `name` is missing.
  factory GroceryItem.fromJson(Map<String, dynamic> j) {
    final id = j['id'];
    final name = j['name'];
    if (id is! String || name is! String || name.trim().isEmpty) {
      throw const FormatException('Grocery item needs an id and a name.');
    }
    final emoji = j['emoji'];
    return GroceryItem(
      id: id,
      name: name,
      emoji: emoji is String && emoji.isNotEmpty ? emoji : '🛒',
      isChecked: j['isChecked'] == true,
    );
  }
}
