import 'package:hive/hive.dart';

class CustomLocal {
  final _shoppingBox = Hive.box('shopping_box');
  final _transactionBox = Hive.box('transaction_box');

  // create method to return _shoppingBox
  Box get shoppingBox => _shoppingBox;
  Box get transactionBox => _transactionBox;

  // Get all items from the database
  List<Map<String, dynamic>> getAllFromLocal() {
    var data = _shoppingBox.values.where((element) => element['isDeleted'] == false).toList();

    final items = data.map((value) {
      return {
        "id": value["id"],
        "name": value["name"],
        "quantity": value['quantity'],
        "createdAt": value['createdAt'],
        "updatedAt": value['updatedAt'],
        'isDeleted': value['isDeleted'],
      };
    }).toList();

    return items;
    // we use "reversed" to sort items in order from the latest to the oldest
  }

  // Create new item
  Future<int> createItemFromLocal(Map<String, dynamic> newItem) async {
    int data = await _shoppingBox.add(newItem);
    return data;
  }

  // Retrieve a single item from the database by using its key
  // Our app won't use this function but I put it here for your reference
  Map<String, dynamic> getByIdFromLocal(String idItem) {
    var keyItem = _shoppingBox.keys.firstWhere(
      (element) => _shoppingBox.get(element)['id'] == idItem,
      orElse: () => null,
    );
    final item = keyItem != null ? _shoppingBox.get(keyItem) : {};
    return item.isNotEmpty ? Map.from(item) : {};
  }

  // Pega elemento baseado no valor de um atributo
  Map<String, dynamic> getByAttribute<K, V>(K attr, V value) {
    var response = _shoppingBox.values.firstWhere((element) => element[attr] == value);

    return Map.from(response);
  }

  // Update a single item
  Future<void> updateAllLocalFromRemote(int key, Map<String, dynamic> item) async {
    // atualiza as transações onde o produto aparece
    var oldItem = _shoppingBox.get(key); // Pega o box do produto

    if (oldItem != null) {
      var listTransactionByItem = getTransactionsByItemId(oldItem['id']); // pega as transações onde ele aparece

      if (listTransactionByItem.isNotEmpty) {
        listTransactionByItem.forEach((element) {
          var transaction = {
            ...element,
            'isSynced': true,
            'updatedAt': DateTime.now().toString(),
            'data': {
              ...element['data'],
              'id': item['id'].toString(),
              'name': item['name'],
              'quantity': item['quantity'],
              'updatedAt': DateTime.now().toString(),
            }
          };

          updateTransaction(element['id'], transaction);
        });
      }

      // atualiza o produto em si
      await _shoppingBox.put(key, {...item, 'updatedAt': DateTime.now().toString()});
    }
  }

  // Update a single item
  Future<void> updateItemLocal(int id, Map<String, dynamic> item) async {
    // get item by id
    var keyItem = _shoppingBox.keys.firstWhere((element) => _shoppingBox.get(element)['id'] == id);
    var tempItem = _shoppingBox.get(keyItem);

    Map<String, dynamic> upItem = {
      ...tempItem,
      'name': item['name'],
      'quantity': item['quantity'],
      'updatedAt': DateTime.now().toString(),
    };

    // await _shoppingBox.put(keyItem, upItem);

    // atualiza as transações onde o produto aparece
    await updateAllLocalFromRemote(keyItem, upItem);

    // Insere na Fila de transações
    var transaction = {
      'id': '${item["name"]}_${DateTime.now().millisecondsSinceEpoch}',
      'path': '/update',
      'verb': 'PUT',
      'createdAt': DateTime.now().toString(),
      'updatedAt': DateTime.now().toString(),
      'isSynced': false,
      'data': upItem,
    };
    // cria uma nova transação
    await createTransaction(transaction);
  }

  // Delete a single item
  Future<String> deleteItemFromLocal(String itemKey) async {
    var keyBoxItem = _shoppingBox.keys.firstWhere(
      (element) => _shoppingBox.get(element)['id'] == itemKey,
      orElse: () => null,
    );
    if (keyBoxItem == null) return "not_found";

    var fruit = _shoppingBox.get(keyBoxItem);

    // buscar as transações que tem esse item
    var listTransactionByItem = getTransactionsByItemId(fruit['id']);
    // verificar se isSynced = false e retornar um boolean
    var isSynced =
        listTransactionByItem.isNotEmpty ? listTransactionByItem.any((element) => element['isSynced'] == true) : false;
    // var listNotSynced = listTransactionByItem.where((element) => element['isSynced'] == false).toList();

    // se isSynced = true, atualizar o item para isDeleted = true e add na transação, caso contrário, deletar o item e as transações onde ele aparece
    if (isSynced) {
      if (fruit['isDeleted'] == true) {
        _shoppingBox.delete(keyBoxItem);
        return "hard_delete";
      } else {
        // atualiza o item no banco local
        fruit['isDeleted'] = true;
        fruit['updatedAt'] = DateTime.now().toString();
        await _shoppingBox.put(keyBoxItem, fruit);

        // cria uma nova transação
        Map<String, dynamic> transaction = {
          'id': '${fruit["name"]}_${DateTime.now().millisecondsSinceEpoch}',
          // 'path': '/delete?id=$itemKey',
          'path': '/delete',
          'verb': 'DEL',
          'createdAt': DateTime.now().toString(),
          'updatedAt': DateTime.now().toString(),
          'isSynced': false,
          'data': fruit,
        };

        await createTransaction(transaction);
        return "soft_delete";
      }
    } else {
      // deleta o item e as transações onde ele aparece
      await _shoppingBox.delete(keyBoxItem);

      listTransactionByItem.isNotEmpty
          ? listTransactionByItem.forEach((element) {
              deleteTransaction(element['id']);
            })
          : null;

      return "hard_delete";
    }
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
              'keyBoxItem': e['keyBoxItem'],
              'id': e["id"],
              'path': e["path"],
              'verb': e['verb'],
              'createdAt': e['createdAt'],
              'updatedAt': e['updatedAt'],
              'isSynced': e['isSynced'],
              'data': e['data'],
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
  Future<void> updateTransaction(String idTransaction, Map<String, dynamic> transact) async {
    var key = _transactionBox.keys.firstWhere((transact) => _transactionBox.get(transact)['id'] == idTransaction);

    Map<String, dynamic> upTransaction = {
      ...transact,
      'isSynced': true,
      'updatedAt': DateTime.now().toString(),
    };

    await _transactionBox.put(key, upTransaction);
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
    List<Map<String, dynamic>> list = [];

    transactions.isNotEmpty
        ? list = transactions
            .map((e) => {
                  'keyBoxItem': e['keyBoxItem'],
                  'id': e["id"],
                  'path': e["path"],
                  'verb': e['verb'],
                  'createdAt': e['createdAt'],
                  'updatedAt': e['updatedAt'],
                  'isSynced': e['isSynced'],
                  'data': e['data'],
                })
            .toList()
        : list;

    return list;
  }
}
