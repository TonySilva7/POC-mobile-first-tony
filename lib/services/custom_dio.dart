import 'package:dio/dio.dart';
import 'package:poc_offline_first/utils/my_interceptor.dart';

class CustomDio {
  static final CustomDio _instance = CustomDio._internal();
  factory CustomDio() => _instance;
  late Dio dio;

  CustomDio._internal() {
    BaseOptions options = BaseOptions(
      baseUrl: "http://3.213.203.158/test/test-offline",
      connectTimeout: 5000,
      receiveTimeout: 3000,
    );
    dio = Dio(options);
    dio.interceptors.add(MyInterceptor());
  }

  Future<Response> getAllFromRemote(String path) async {
    Response response = await dio.get(path);

    return response;
  }

  Future<Response> getByIdFromRemote(int id) async {
    Response response = await dio.get("/$id");
    return response;
  }

  Future<Response> createItemFromRemote(String path, dynamic fruit) async {
    Response response = await dio.post(path, data: fruit);
    return response;
  }

  Future<Response> updateItemFromRemote(String path, int id, dynamic fruit) async {
    // Response response = await dio.put("$path/$id", data: fruit);
    Response response = await dio.put("/$path", data: fruit);
    return response;
  }

  Future<Response> deleteItemFromRemote(String path, String id) async {
    late Response response;
    int fruitId = int.parse(id);

    var pathSplit = path.split('?');

    if (pathSplit[pathSplit.length - 1] == 'id=$id') {
      response = await dio.delete("${pathSplit[0]}?id=$fruitId");
    } else {
      response = await dio.delete("$path/?id=$fruitId");
    }

    return response;
  }
}



  // void getAllFruits() async {
  //   final response = await CustomDio().getAll('/get-all');
  //   var fruits = response.data;

  //   fruits.forEach((fruit) {
  //     _createItem({"name": fruit['name'], "quantity": fruit['quantity']});
  //   });
  // }
