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
  Future<Map<String, dynamic>> getItemById(String id) async {
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
  Future<String> deleteItem(String path, String id) async {
    var res = await _customLocal.deleteItemFromLocal(id);
    return res;
  }

  // verify if exists transaction to sync and make it based on verb
  Future<void> syncTransactions() async {
    int lastSync = _customLocal.getLastSyncUpdate();
    // pega dados remotos
    List<Map<String, dynamic>> listItemFromRemote = await _customDio.getAllFromRemoteByDate(
      '/get-db',
      lastSync,
    );

    // pega dados locais
    // List<Map<String, dynamic>> listItemFromLocal = _customLocal.getLocalAllItemsByDate('2023-01-20 00:00:00');

    // Atualiza dados locais
    if (listItemFromRemote.isNotEmpty) {
      await _customLocal.updateAllLocalItems(listItemFromRemote);
      // print(listItemFromRemote);

      // TO-DO: grava data da ultima sincronização

    }

    // Atualiza dados remotos
    // if (listItemFromLocal.isNotEmpty) {}
  }
}
