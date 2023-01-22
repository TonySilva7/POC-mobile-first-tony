import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:poc_offline_first/services/custom_dio.dart';

class FruitController {
  final CustomDio _customDio = CustomDio();
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
      // return await getAllFromLocal();
      return [];
    }
  }

  // Get by id if connected from api else from local
  Future<Map<String, dynamic>> getItemById(int id) async {
    bool isConnected = await checkInternetConnection();
    if (isConnected) {
      Response response = await _customDio.getByIdFromRemote(id);
      return response.data as Map<String, dynamic>;
    } else {
      // return await getByIdFromLocal(id);
      return {};
    }
  }

  // Create item if connected from api else from local
  Future<int> createItem(String path, Map<String, dynamic> item) async {
    bool isConnected = await checkInternetConnection();
    if (isConnected) {
      Response response = await _customDio.createItemFromRemote(path, item);
      return response.data as int;
    } else {
      // return await createFromLocal(item);
      return 0;
    }
  }

  // Update item if connected from api else from local
  Future<Map<String, dynamic>> updateItem(String path, int id, Map<String, dynamic> item) async {
    bool isConnected = await checkInternetConnection();
    if (isConnected) {
      Response response = await _customDio.updateItemFromRemote(path, id, item);
      return response.data as Map<String, dynamic>;
    } else {
      // return await updateFromLocal(id, item);
      return {};
    }
  }

  // Delete item if connected from api else from local
  Future<String> deleteItem(String path, int id) async {
    bool isConnected = await checkInternetConnection();
    if (isConnected) {
      Response response = await _customDio.deleteItemFromRemote(path, id);
      return response.data as String;
    } else {
      // return await deleteFromLocal(id);
      return "Success";
    }
  }
}
