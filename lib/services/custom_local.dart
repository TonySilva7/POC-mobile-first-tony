import 'package:hive/hive.dart';

class CustomLocal {
  final _shoppingBox = Hive.box('shopping_box');
  final _transactionBox = Hive.box('transaction_box');

  // create method to return _shoppingBox
  Box get shoppingBox => _shoppingBox;
  Box get transactionBox => _transactionBox;

  // Get all items from the database
  List<Map<String, dynamic>> getAllFromLocal() {
    final data = _shoppingBox.keys.map((key) {
      final value = _shoppingBox.get(key);
      // return {"key": key, "name": value["name"], "quantity": value['quantity']};
      return {
        "id": value["id"],
        "name": value["name"],
        "quantity": value['quantity'],
        "createdAt": value['createdAt'],
        "updatedAt": value['updatedAt']
      };
    }).toList();

    return data;
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

  // Pega elemento baseado no valor de um atributo
  Map<String, dynamic> getByAttribute<K, V>(K attr, V value) {
    var response = _shoppingBox.values.firstWhere((element) => element[attr] == value);

    return Map.from(response);
  }

  // Update a single item
  Future<void> updateItemFromLocal(int key, Map<String, dynamic> item) async {
    // atualiza as transações onde o produto aparece
    var oldItem = _shoppingBox.get(key); // Pega o box do produto

    if (oldItem != null) {
      var listTransactionByItem = getTransactionsByItemId(oldItem['id']); // pega o id do produto

      listTransactionByItem.forEach((element) {
        // atualiza nas transações
        element['data']['id'] = item['id'].toString();
        element['updatedAt'] = DateTime.now().toString();
        element['isSynced'] = true;

        updateTransaction(element['id'], element['data']);
      });

      // atualiza o produto em si
      await _shoppingBox.put(key, item);
    }
  }

  // Delete a single item
  Future<String> deleteItemFromLocal(String itemKey) async {
    var key = _shoppingBox.keys.firstWhere((element) => _shoppingBox.get(element)['id'] == itemKey);
    var fruit = _shoppingBox.get(key);

    Map<String, dynamic> transaction = {
      'id': '${fruit["name"]}_${DateTime.now().millisecondsSinceEpoch}',
      'path': '/delete?id=$itemKey',
      'verb': 'DEL',
      'createdAt': DateTime.now().toString(),
      'updatedAt': DateTime.now().toString(),
      'isSynced': false,
      'data': fruit,
    };

    await createTransaction(transaction);

    await _shoppingBox.delete(key);

    return "Success";
  }

  // ----------------- Transaction -----------------

  Future<int> createTransaction(Map<String, dynamic> transaction) async {
    int data = await _transactionBox.add(transaction);
    return data;
  }

  // Get all items where isSynced = false
  List<Map<String, dynamic>> getTransactionsByAttribute<T, V>(T key, V value) {
    var transactions = _transactionBox.values.where((element) => element[key] == value).toList();
    // var transactions =
    //     _transactionBox.values.where((element) => element[key] == value && element['verb'] == verb).toList();

    // convert list of dynamic to list of map
    List<Map<String, dynamic>> transactionsMap = transactions
        .map((e) => {
              "id": e["id"],
              "path": e["path"],
              "verb": e['verb'],
              "createdAt": e['createdAt'],
              "updatedAt": e['updatedAt'],
              "isSynced": e['isSynced'],
              "data": e['data'],
              "keyBox": e['keyBox'],
            })
        .toList();

    return transactionsMap;
  }

  // get transaction by attribute
  Map<String, dynamic> getTransactionByAttribute<T, V>(T attr, V value) {
    var transaction = _transactionBox.values.firstWhere((element) => element['data'][attr] == value);

    return Map.from(transaction);
  }

  // update isSynced to true in transaction
  Future<void> updateTransaction(String idTransaction, Map<String, dynamic> item) async {
    var key = _transactionBox.keys.firstWhere((transact) => _transactionBox.get(transact)['id'] == idTransaction);
    await _transactionBox.put(key, item);
  }

  // delete transaction
  Future<void> deleteTransaction(String itemKey) async {
    var key = _transactionBox.keys.firstWhere((element) => _transactionBox.get(element)['id'] == itemKey);
    await _transactionBox.delete(key);
  }

  // update data attribute in transaction by data id
  List<Map<String, dynamic>> getTransactionsByItemId(String idItem) {
    // pegar listas de transactions onde o id do item em data é igual ao idItem
    var transactions = _transactionBox.values.where((element) => element['data']['id'] == idItem).toList();

    var listOfMap = transactions
        .map((e) => {
              "id": e["id"],
              "path": e["path"],
              "verb": e['verb'],
              "createdAt": e['createdAt'],
              "updatedAt": e['updatedAt'],
              "isSynced": e['isSynced'],
              "data": e['data'],
              "keyBox": e['keyBox'],
            })
        .toList();

    return listOfMap;
  }
}
