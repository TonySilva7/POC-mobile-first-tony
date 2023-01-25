import 'package:hive/hive.dart';

class CustomLocal {
  final _fruitTableBox = Hive.box('fruits_table_box');
  final _campaignTableBox = Hive.box('campaign_table_box');
  final _syndDataBox = Hive.box('sync_data_box');

  final List<String> _listOpenBoxes = ['FruitTable', 'CampaignTable'];

  // create method to return _fruitTableBox
  Box get fruitTableBox => _fruitTableBox;
  Box get campaignTableBox => _campaignTableBox;
  Box get syncDataBox => _syndDataBox;

  // Get all items from the database
  List<Map<String, dynamic>> getAllFromLocal() {
    var data = fruitTableBox.values.toList();

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
  }

  // Retrieve a single item from the database by using its key
  // Our app won't use this function but I put it here for your reference
  Map<String, dynamic> getByIdFromLocal(String idItem) {
    var keyItem = fruitTableBox.keys.firstWhere(
      (element) => fruitTableBox.get(element)['id'] == idItem,
      orElse: () => null,
    );
    final item = keyItem != null ? fruitTableBox.get(keyItem) : {};
    return item.isNotEmpty ? Map.from(item) : {};
  }

  // Pega elemento baseado no valor de um atributo
  Map<String, dynamic> getByAttribute<K, V>(K attr, V value) {
    var response = fruitTableBox.values.firstWhere((element) => element[attr] == value);

    return Map.from(response);
  }

  // Create new item
  Future<int> createItemFromLocal(Map<String, dynamic> newItem) async {
    int data = await fruitTableBox.add(newItem);
    return data;
  }

  // Update a single item
  Future<void> updateItemLocal(int id, Map<String, dynamic> item) async {
    // get item by id
    var keyItem = fruitTableBox.keys.firstWhere((element) => fruitTableBox.get(element)['id'] == id);
    var tempItem = fruitTableBox.get(keyItem);

    Map<String, dynamic> upItem = {
      ...tempItem,
      ...item,
      'updatedAt': DateTime.now().toString(),
    };

    fruitTableBox.put(keyItem, upItem);
  }

  // Delete a single item
  Future<String> deleteItemFromLocal(String itemKey) async {
    var keyBoxItem = fruitTableBox.keys.firstWhere(
      (element) => fruitTableBox.get(element)['id'] == itemKey,
      orElse: () => null,
    );
    if (keyBoxItem == null) return "not_found";

    await fruitTableBox.delete(keyBoxItem);

    return "deleted";
  }

  // ----------------- Transaction -----------------
  // faz um get de todos os itens em fruitTableBox baseado em uma data x e retorna uma lista de mapas desses dados
  List<Map<String, dynamic>> getLocalAllItemsByDate(String date) {
    var data = fruitTableBox.values.where((element) => element['createdAt'] == date).toList();

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
  }

  // pega a última data de atualização dos dados
  int getLastSyncUpdate() {
    var lastDate = syncDataBox.get(0);
    String date = "2023-01-20T00:00:00";
    DateTime parsedDate = DateTime.parse(date);

    var timestamp = parsedDate.millisecondsSinceEpoch;

    return lastDate == null ? timestamp : lastDate['toRemote']['date'];
  }

  // seta a última data de atualização dos dados
  int setLastUpdateDate(int timestamp) {
    syncDataBox.put('lastUpdateDate', timestamp);
    return timestamp;
  }

  // faz um update no banco local com os dados que vieram do servidor
  Future<void> updateAllLocalItems(List<Map<String, dynamic>> items) async {
    for (var item in items) {
      if (_listOpenBoxes.contains(item['tableName'])) {
        var tableName = _listOpenBoxes.firstWhere((boxName) => boxName == item['tableName']);

        if (tableName == 'FruitTable') {
          handleUpdateLocalItem(item['row'], fruitTableBox);
        } else if (tableName == 'CampaignTable') {
          handleUpdateLocalItem(item['row'], campaignTableBox);
        }
      } else {
        print('Não existe essa tabela no banco local');
      }
    }
  }

  void handleUpdateLocalItem(Map<String, dynamic> newItem, Box<dynamic> box) {
    var keyItem = box.keys.firstWhere(
      (oldItem) => box.get(oldItem)['id'] == newItem['id'],
      orElse: () => null,
    );

    if (keyItem != null) {
      print(box.get(keyItem));
      print(newItem);
      box.put(keyItem, {...newItem, 'updatedAt': DateTime.now().toString()});
    } else {
      // PS. Add com o ID que veio do Banco Remoto
      print(newItem);
      box.add(newItem);
    }
  }
}
