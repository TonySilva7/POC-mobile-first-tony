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
    int fruitId = int.parse(id);

    Response response = await dio.delete("$path/?id=$fruitId");

    return response;
  }

  // Pega todos os dados na api a partir de uma data x e retorna uma lista de map para atualizar o banco local
  Future<List<Map<String, dynamic>>> getAllFromRemoteByDate(String path, int lastSyncDate) async {
    Response response = await dio.get("$path/?date=$lastSyncDate");
    List<dynamic> list = response.data;

    // map res which is a list of dynamic to a list of map
    List<Map<String, dynamic>> fruits = list.map((e) => e as Map<String, dynamic>).toList();

    return fruits;
  }
}
