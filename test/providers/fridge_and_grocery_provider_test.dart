import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridgenie/data/storage/local_store.dart';
import 'package:fridgenie/data/storage/storage_keys.dart';
import 'package:fridgenie/providers/fridge_provider.dart';
import 'package:fridgenie/providers/grocery_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await LocalStore.open();
  });

  group('FridgeProvider', () {
    test('first launch gets the starter fridge', () {
      expect(FridgeProvider(store).inventoryIds, contains('eggs'));
    });

    test('an emptied fridge stays empty after restart', () {
      final fridge = FridgeProvider(store);
      for (final id in fridge.inventoryIds.toList()) {
        fridge.toggleInventory(id);
      }
      expect(FridgeProvider(store).inventoryIds, isEmpty);
    });

    test('changes made right after start survive a restart', () {
      FridgeProvider(store)
        ..toggleInventory('salmon')
        ..toggleSelected('basil');

      final restarted = FridgeProvider(store);
      expect(restarted.isInInventory('salmon'), isTrue);
      expect(restarted.isSelected('basil'), isTrue);
    });

    test('removing from the fridge also unselects', () {
      final fridge = FridgeProvider(store)..toggleSelected('eggs');
      fridge.toggleInventory('eggs');
      expect(fridge.isSelected('eggs'), isFalse);
    });
  });

  group('GroceryProvider', () {
    test('ignores blanks and case-insensitive duplicates', () {
      final grocery = GroceryProvider(store)
        ..addItem('Milk', '🥛')
        ..addItem(' milk ', '🥛')
        ..addItem('   ', '🛒');
      expect(grocery.items.map((i) => i.name), ['Milk']);
    });

    test('checked items are removed after the delay, unchecking cancels', () {
      fakeAsync((async) {
        final grocery = GroceryProvider(store)
          ..addItem('Milk', '🥛')
          ..addItem('Eggs', '🥚');
        final milk = grocery.items.first.id;
        final eggs = grocery.items.last.id;

        grocery
          ..toggleItem(milk)
          ..toggleItem(eggs)
          ..toggleItem(eggs);
        async.elapse(const Duration(seconds: 6));

        expect(grocery.items.map((i) => i.name), ['Eggs']);
        expect(grocery.items.single.isChecked, isFalse);
      });
    });

    test('re-adding a checked item keeps it instead of losing it', () {
      fakeAsync((async) {
        final grocery = GroceryProvider(store)..addItem('Milk', '🥛');
        grocery.toggleItem(grocery.items.single.id);
        grocery.addItem('milk', '🥛');
        async.elapse(const Duration(seconds: 6));
        expect(grocery.items.single.isChecked, isFalse);
      });
    });

    test('clearAll cancels pending removals', () {
      fakeAsync((async) {
        final grocery = GroceryProvider(store)..addItem('Milk', '🥛');
        grocery.toggleItem(grocery.items.single.id);
        grocery.clearAll();
        grocery.addItem('Bread', '🍞');
        async.elapse(const Duration(seconds: 6));
        expect(grocery.items.map((i) => i.name), ['Bread']);
      });
    });

    test('the list survives a restart; checked leftovers are dropped', () {
      GroceryProvider(store)
        ..addItem('Milk', '🥛')
        ..addItem('Rice', '🍚');
      final first = GroceryProvider(store);
      first.toggleItem(first.items.first.id);

      final restarted = GroceryProvider(store);
      expect(restarted.items.map((i) => i.name), ['Rice']);
      expect(store.getString(StorageKeys.groceryList), contains('Rice'));
      first.dispose();
    });
  });
}
