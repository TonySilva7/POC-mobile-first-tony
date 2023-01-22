import 'package:hive/hive.dart';

class CustomLocal {
  final _shoppingBox = Hive.box('shopping_box');

  // Get all items from the database
  List<Map<String, dynamic>> getAllFromLocal() {
    final data = _shoppingBox.keys.map((key) {
      final value = _shoppingBox.get(key);
      return {"key": key, "name": value["name"], "quantity": value['quantity']};
    }).toList();

    return data.reversed.toList();
    // we use "reversed" to sort items in order from the latest to the oldest
  }

  // Create new item
  Future<int> createItemFromLocal(Map<String, dynamic> newItem) async {
    int data = await _shoppingBox.add(newItem);
    return data;
  }

  // Retrieve a single item from the database by using its key
  // Our app won't use this function but I put it here for your reference
  Map<String, dynamic> getByIdFromLocal(int key) {
    final item = _shoppingBox.get(key);
    return item;
  }

  // Update a single item
  Future<void> updateItemFromLocal(int itemKey, Map<String, dynamic> item) async {
    await _shoppingBox.put(itemKey, item);
  }

  // Delete a single item
  Future<void> deleteItemFromLocal(int itemKey) async {
    await _shoppingBox.delete(itemKey);
  }
}
