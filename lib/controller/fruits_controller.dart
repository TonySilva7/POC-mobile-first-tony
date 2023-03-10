import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

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
  List<Map<String, dynamic>> getAllItems(String boxName) {
    // bool isConnected = await checkInternetConnection();

    var fruits = _customLocal.getAllFromLocal(boxName.toLowerCase());
    return fruits;
  }

  // Get by id if connected from api else from local
  Future<Map<String, dynamic>> getItemById(int id, String boxName) async {
    return _customLocal.getByIdFromLocal(id, boxName.toLowerCase());
  }

  // Create item if connected from api else from local
  Future<int> createItem(String path, Map<String, dynamic> item) async {
    Map<String, dynamic> fruit = {
      'id': -Random().nextInt(1000),
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
  Future<void> updateItem(String path, int id, Map<String, dynamic> item, String boxName) async {
    return await _customLocal.updateItemLocal(id, item, boxName.toLowerCase());
  }

  // Delete item if connected from api else from local
  Future<String> deleteItem(String path, int id) async {
    var res = await _customLocal.deleteItemFromLocal(id);
    return res;
  }

  Future<void> syncTransactions() async {
    await handleSyncFromRemote();

    await handleSyncToRemote();

    // await _customLocal.testeDePerformance();
  }

  Future<void> handleSyncFromRemote() async {
    print('============================ INICIO ===========================================');
    int lastSyncFromRemote = _customLocal.getLastSyncUpdate();
    print('Data enviada (GET): ${DateTime.fromMillisecondsSinceEpoch(lastSyncFromRemote, isUtc: true)}');

    List<Map<String, dynamic>> listItemFromRemote = await _customDio.getAllFromRemoteByDate(
      '/get-db',
      lastSyncFromRemote,
    );
    print('Item recebido: $listItemFromRemote');

    if (listItemFromRemote.isNotEmpty) {
      await _customLocal.updateAllLocalItems(listItemFromRemote);

      int timestamp = DateTime.now().millisecondsSinceEpoch;
      print('Data gravada (GET): ${DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true)}');
      await _customLocal.setLastSyncUpdate(timestamp, listItemFromRemote.length, 'GET');
    }
  }

  Future<void> handleSyncToRemote() async {
    print('*********************************************************************************');
    int lastSyncToRemote = _customLocal.getLastSyncUpdate();
    print('Data consultada: ${DateTime.fromMillisecondsSinceEpoch(lastSyncToRemote, isUtc: true)}');
    var listItemFromLocal = _customLocal.getAllLocalItemsByDate(lastSyncToRemote);

    if (listItemFromLocal.isNotEmpty) {
      print('Payload enviado (POST): $listItemFromLocal');
      Response response = await _customDio.createItemFromRemote('/post', listItemFromLocal);

      var data = response.data;
      print('Ids recebidos de volta: $data');

      if (data.length > 0) {
        List<Map<String, dynamic>> listPayload = List<Map<String, dynamic>>.from(data);

        await _customLocal.updateAllLocalItems(listPayload);
      }
      var timestamp = DateTime.now().millisecondsSinceEpoch;
      print('Data gravada (POST): ${DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true)}');

      await _customLocal.setLastSyncUpdate(timestamp, listItemFromLocal.length, 'POST');
    }
  }
}
