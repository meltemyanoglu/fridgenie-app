import 'package:flutter_test/flutter_test.dart';
import 'package:fridgenie/data/storage/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('readJsonList skips bad items instead of dropping everything', () async {
    SharedPreferences.setMockInitialValues({
      'list': '[{"v": 1}, "oops", {"v": "x"}, {"v": 3}]',
    });
    final store = await LocalStore.open();

    final values = store.readJsonList('list', (json) => json['v'] as int);

    expect(values, [1, 3]);
  });

  test('readJsonList survives invalid JSON and wrong shapes', () async {
    SharedPreferences.setMockInitialValues({
      'broken': '{not json',
      'object': '{"a": 1}',
    });
    final store = await LocalStore.open();

    expect(store.readJsonList('broken', (json) => json), isEmpty);
    expect(store.readJsonList('object', (json) => json), isEmpty);
    expect(store.readJsonList('missing', (json) => json), isEmpty);
    expect(store.readJsonMap('broken'), isEmpty);
    expect(store.readJsonMap('object'), {'a': 1});
  });

  test('writes are visible immediately', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.open();

    store.setJson('k', [1, 2]);
    store.setStringList('s', ['a']);
    store.setInt('i', 7);

    expect(store.getString('k'), '[1,2]');
    expect(store.getStringList('s'), ['a']);
    expect(store.getInt('i'), 7);
  });
}
