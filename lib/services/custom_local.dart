import 'package:hive/hive.dart';

class CustomLocal {
  final _fruitTableBox = Hive.box('TestOffline');
  final _campaignTableBox = Hive.box('Campaigns');
  final _syndDataBox = Hive.box('sync_data_box');

  final List<String> _listOpenBoxes = ['TestOffline', 'Campaigns'];

  Box get fruitTableBox => _fruitTableBox;
  Box get campaignTableBox => _campaignTableBox;
  Box get syncDataBox => _syndDataBox;

  // Get all items from the database
  List<Map<String, dynamic>> getAllFromLocal(String boxName) {
    var data = [];
    if (boxName == fruitTableBox.name) {
      data = fruitTableBox.values.where((item) => item['isDeleted'] == false).toList();
    } else {
      data = campaignTableBox.values.where((item) => item['isDeleted'] == false).toList();
    }
    // var data = fruitTableBox.values.toList();

    final items = data.map((value) {
      return {
        "id": value["id"],
        "name": value["name"],
        "quantity": value['quantity'] ?? value['goalValue'],
        "createdAt": value['createdAt'],
        "updatedAt": value['updatedAt'],
        'price': value['price'],
      };
    }).toList();

    return items;
  }

  // Retrieve a single item from the database by using its key
  // Our app won't use this function but I put it here for your reference
  Map<String, dynamic> getByIdFromLocal(int idItem, String boxName) {
    Box myBox = boxName == fruitTableBox.name ? fruitTableBox : campaignTableBox;
    var keyItem = myBox.keys.firstWhere(
      (element) => myBox.get(element)['id'] == idItem,
      orElse: () => null,
    );

    final item = keyItem != null ? myBox.get(keyItem) : {};
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
  Future<void> updateItemLocal(int id, Map<String, dynamic> item, String boxName) async {
    Box myBox = boxName == fruitTableBox.name ? fruitTableBox : campaignTableBox;
    // get item by id
    var keyItem = myBox.keys.firstWhere((element) => myBox.get(element)['id'] == id);
    var tempItem = myBox.get(keyItem);

    Map<String, dynamic> upItem = {
      ...tempItem,
      ...item,
      'updatedAt': DateTime.now().toString(),
    };

    myBox.put(keyItem, upItem);
  }

  // Delete a single item
  Future<String> deleteItemFromLocal(int itemKey) async {
    var keyBoxItem = fruitTableBox.keys.firstWhere(
      (element) => fruitTableBox.get(element)['id'] == itemKey,
      orElse: () => null,
    );
    if (keyBoxItem == null) return "not_found";

    var item = fruitTableBox.get(keyBoxItem);
    await fruitTableBox.put(keyBoxItem, {
      ...item,
      'isDeleted': true,
      'updatedAt': DateTime.now().toString(),
    });

    return "deleted";
  }

  // ------ GET PARA A API --------------------------

  int getLastSyncUpdate(String direction) {
    var syncBox = syncDataBox.get(0);

    DateTime parsedDate = DateTime.parse("2023-01-29T00:00:00");
    var timestampDefault = parsedDate.millisecondsSinceEpoch;

    int timestamp = syncBox == null ? timestampDefault : syncBox[direction]['date'];

    return timestamp;
  }

  Future<void> setLastSyncUpdate(int timestamp, int countList, String direction) async {
    var syncBox = syncDataBox.get(0);

    DateTime parsedDate = DateTime.parse("2023-01-30T00:00:00");
    var timestampDefault = parsedDate.millisecondsSinceEpoch;

    if (syncBox == null) {
      await syncDataBox.add({
        'fromRemote': {
          'date': direction == 'fromRemote' ? timestamp : timestampDefault,
          'quantityItems': direction == 'fromRemote' ? countList : 0,
        },
        'toRemote': {
          'date': direction == 'toRemote' ? timestamp : timestampDefault,
          'quantityItems': direction == 'toRemote' ? countList : 0,
        },
      });
    } else {
      syncBox[direction]['date'] = timestamp;
      syncBox[direction]['quantityItems'] = countList;

      await syncDataBox.put(0, syncBox);
    }
  }

  // faz um update no banco local com os dados que vieram do servidor
  Future<void> updateAllLocalItems(List<Map<String, dynamic>> items) async {
    for (var item in items) {
      if (await Hive.boxExists(item['tableName']) && Hive.box(item['tableName']).isOpen) {
        var box = Hive.box(item['tableName']);

        // if (tableName == 'TestOffline') {
        if (item['row'] != null) {
          handleUpdateLocalItem(item['row'], box, false);
        } else if (item['rowDeleted'] != null) {
          handleUpdateLocalItem(item['rowDeleted'], box, true);
        } else {
          handleUpdateLocalItem(item, box, false);
        }
      } else {
        print('Não existe - TO-DO: criar tabela');
      }
    }
  }

  void handleUpdateLocalItem(Map<String, dynamic> newItem, Box<dynamic> box, bool isDelete) {
    int? keyItem = box.keys.firstWhere(
      (oldItem) => box.get(oldItem)['id'] as int == (newItem['id'] ?? newItem['localId']) as int,
      orElse: () => null,
    );

    if (isDelete) {
      if (keyItem != null) box.delete(keyItem);
    } else {
      if (keyItem != null) {
        if (newItem['localId'] != null) {
          var oldItem = box.get(keyItem);
          box.put(keyItem, {...oldItem, 'id': newItem['remoteId']});
        } else {
          var oldItem = box.get(keyItem);
          var itemUP = {...oldItem, ...newItem, 'updatedAt': DateTime.now().toString()};
          box.put(keyItem, itemUP);

          print('Item Atualizado Local: $itemUP');
        }
      } else {
        box.add({...newItem, 'isDeleted': false});
      }
    }
  }

  // ======================= POST PARA A API =======================

  // faz um get de todos os itens em fruitTableBox baseado em uma data x e retorna uma lista de mapas desses dados
  List<dynamic> getAllLocalItemsByDate(int timestamp) {
    var itemsToSync = [];

    for (String boxName in _listOpenBoxes) {
      var boxHive = Hive.box(boxName);

      var keysItems = boxHive.keys.toList();

      if (keysItems.isNotEmpty) {
        for (int key in keysItems) {
          var item = boxHive.get(key) as Map;

          var itemDate = DateTime.parse(item['updatedAt']).millisecondsSinceEpoch;

          if (itemDate > timestamp) {
            if (item['isDeleted'] == true) {
              itemsToSync.add({
                'tableName': boxName,
                'rowDeleted': item['id'],
              });

              boxHive.delete(key);
            } else {
              var itemToSend = {...item};

              itemToSend.remove('isDeleted');
              itemToSend.remove('updatedAt');
              itemToSend.remove('createdAt');
              itemToSend.remove('id');

              itemsToSync.add({
                'tableName': boxName,
                'idItem': item['id'],
                'row': itemToSend,
              });
            }
          }
        }
      }
    }

    return itemsToSync;
  }

// Esse método foi criado para  mudar o DDL da tabela mas foi abortado
  Future<void> configureAttributes(Box box, String attr, String action) async {
    var keysBoxe = box.keys.toList();

    if (keysBoxe.isNotEmpty) {
      for (var key in keysBoxe) {
        var item = box.get(key);

        if (action == 'add') {
          item[attr] = null;
        } else {
          await item.remove(attr);
        }
        await box.put(key, item);
      }
    }
  }
}
