import 'dart:async';
import 'dart:ffi';

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
  Future<List<Map<String, dynamic>>> getAllItems(String path) async {
    bool isConnected = await checkInternetConnection();
    if (isConnected) {
      // return await getAllFromApi();
      Response response = await _customDio.getAllFromRemote(path);
      List<dynamic> list = response.data;

      // map res which is a list of dynamic to a list of map
      List<Map<String, dynamic>> fruits = list.map((e) => e as Map<String, dynamic>).toList();

      return fruits;
    } else {
      var fruits = _customLocal.getAllFromLocal();
      return fruits;
    }
  }

  // Get by id if connected from api else from local
  Future<Map<String, dynamic>> getItemById(String id) async {
    bool isConnected = await checkInternetConnection();
    if (isConnected) {
      Response response = await _customDio.getByIdFromRemote(int.parse(id));
      return response.data as Map<String, dynamic>;
    } else {
      return _customLocal.getByIdFromLocal(id);
    }
  }

  // Create item if connected from api else from local
  Future<int> createItem(String path, Map<String, dynamic> item) async {
    bool isConnected = await checkInternetConnection();

    Map<String, dynamic> fruit = {
      'id': '${DateTime.now().millisecondsSinceEpoch}',
      'createdAt': DateTime.now().toString(),
      'updatedAt': DateTime.now().toString(),
      'name': item['name'],
      'quantity': item['quantity'],
      'isDeleted': false,
    };

    if (isConnected) {
      // Faz o sync com o remoto
      await syncTransactions();

      // envia dados atual para remoto
      Map<String, dynamic> currentPayload = {...fruit};
      currentPayload.remove('id');

      Response response = await _customDio.createItemFromRemote(path, currentPayload);

      // envia dados atual tbm para local com id do remoto
      await _customLocal.createItemFromLocal({...fruit, 'id': response.data.toString()});

      return response.data as int;
    } else {
      int keyItem = await _customLocal.createItemFromLocal(fruit);

      Map<String, dynamic> transaction = {
        'keyBoxItem': keyItem,
        'id': '${fruit["name"]}_${DateTime.now().millisecondsSinceEpoch}',
        'path': '/post',
        'verb': 'POST',
        'createdAt': DateTime.now().toString(),
        'updatedAt': DateTime.now().toString(),
        'isSynced': false,
        'data': {...fruit, 'id': fruit["id"]},
      };

      await _customLocal.createTransaction(transaction);

      return keyItem;
    }
  }

  // Update item if connected from api else from local
  Future<void> updateItem(String path, int id, Map<String, dynamic> item) async {
    bool isConnected = await checkInternetConnection();
    if (isConnected) {
      await syncTransactions();

      await _customDio.updateItemFromRemote(path, id, item);
      await _customLocal.updateItemLocal(id, item);

      // return response.data as Map<String, dynamic>;
    } else {
      return await _customLocal.updateItemLocal(id, item);
    }
  }

  // Delete item if connected from api else from local
  Future<String> deleteItem(String path, String id) async {
    bool isConnected = await checkInternetConnection();

    if (isConnected) {
      await syncTransactions();

      Response response = await _customDio.deleteItemFromRemote(path, id);
      await _customLocal.deleteItemFromLocal(id);

      return response.data as String;
    } else {
      var res = await _customLocal.deleteItemFromLocal(id);
      return res;
    }
  }

  // verify if exists transaction to sync and make it based on verb
  Future<void> syncTransactions() async {
    // pega dados locais
    var listTransactions = _customLocal.getTransactionsByAttribute<String, bool>("isSynced", false);

    // envia dados locais para remoto
    if (listTransactions.isNotEmpty) {
      var listPOST = listTransactions.where((element) => element['verb'] == 'POST').toList();
      var listPUT = listTransactions.where((element) => element['verb'] == 'PUT').toList();
      var listDELETE = listTransactions.where((element) => element['verb'] == 'DEL').toList();

      if (listPOST.isNotEmpty) {
        for (var transaction in listPOST) {
          // if (transaction['verb'] == 'POST') {
          // post cada item para api
          Map<String, dynamic> payload = {...transaction['data']};
          payload.remove('id');

          Response resp = await _customDio.createItemFromRemote(transaction['path'], payload);

          // atualiza id local com id gerado no remoto (response.data)
          await _customLocal.updateAllLocalFromRemote(
              transaction['keyBoxItem'], {...transaction['data'], 'id': resp.data.toString()});
        }
      }

      if (listPUT.isNotEmpty) {
        for (var transaction in listPUT) {
          // put cada item para api
          await _customDio.updateItemFromRemote(transaction['path'], transaction['data']['id'], transaction['data']);

          // TO-DO: Atualiza se o status da requisição acima for 200

          // atualiza isSynced para true
          await _customLocal.updateTransaction(transaction['id'], transaction);
        }
      }

      if (listDELETE.isNotEmpty) {
        for (var transaction in listDELETE) {
          // delete cada item para api
          await _customDio.deleteItemFromRemote(transaction['path'], transaction['data']['id']);

          // TO-DO: Deleta se o status da requisição acima for 200

          // delete transaction
          await _customLocal.deleteTransaction(transaction['id']);
          await _customLocal.deleteItemFromLocal(transaction['data']['id']);
        }
      }
    }
  }
}
