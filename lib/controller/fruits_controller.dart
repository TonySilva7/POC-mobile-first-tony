import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:poc_offline_first/services/custom_dio.dart';
import 'package:poc_offline_first/services/custom_local.dart';

class FruitController {
  final CustomDio _customDio = CustomDio();
  final CustomLocal _customLocal = CustomLocal();

  // Check internet connection
  Future<bool> checkInternetConnection() async {
    ConnectivityResult connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      return true;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      return true;
    }
    return false;
  }

  // Get all items if connected from api else from local
  List<Map<String, dynamic>> getAllItems() {
    // bool isConnected = await checkInternetConnection();

    var fruits = _customLocal.getAllFromLocal();
    return fruits;
  }

  // Get by id if connected from api else from local
  Future<Map<String, dynamic>> getItemById(int id) async {
    return _customLocal.getByIdFromLocal(id);
  }

  // Create item if connected from api else from local
  Future<int> createItem(String path, Map<String, dynamic> item) async {
    Map<String, dynamic> fruit = {
      'id': '${DateTime.now().millisecondsSinceEpoch}',
      'createdAt': DateTime.now().toString(),
      'updatedAt': DateTime.now().toString(),
      'name': item['name'],
      'quantity': item['quantity'],
      'isDeleted': false,
    };

    int keyItem = await _customLocal.createItemFromLocal(fruit);

    return keyItem;
  }

  // Update item if connected from api else from local
  Future<void> updateItem(String path, int id, Map<String, dynamic> item) async {
    return await _customLocal.updateItemLocal(id, item);
  }

  // Delete item if connected from api else from local
  Future<String> deleteItem(String path, int id) async {
    var res = await _customLocal.deleteItemFromLocal(id);
    return res;
  }

  Future<void> syncTransactions() async {
    int lastSyncFromRemote = _customLocal.getLastSyncUpdate('fromRemote');
    // pega dados remotos
    List<Map<String, dynamic>> listItemFromRemote = await _customDio.getAllFromRemoteByDate(
      '/get-db',
      lastSyncFromRemote,
    );

    if (listItemFromRemote.isNotEmpty) {
      await _customLocal.updateAllLocalItems(listItemFromRemote);

      int timestamp = DateTime.now().millisecondsSinceEpoch;
      await _customLocal.setLastSyncUpdate(timestamp, listItemFromRemote.length, 'fromRemote');
    }

    // pega dados locais
    int lastSyncToRemote = _customLocal.getLastSyncUpdate('toRemote');
    var listItemFromLocal = _customLocal.getAllLocalItemsByDate(lastSyncToRemote);

    print(listItemFromLocal);

    if (listItemFromLocal.isNotEmpty) {
      // TO-DO - enviar dados locais para o servidor
      await _customDio.createItemFromRemote('/post', listItemFromLocal);
      // TO-DO - Atualizar o syncToRemote com setLastSyncUpdate
      var timestamp = DateTime.now().millisecondsSinceEpoch;
      await _customLocal.setLastSyncUpdate(timestamp, listItemFromLocal.length, 'toRemote');
    }
  }
}
