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

  Future<Response> getAll(String path) async {
    Response response = await dio.get(path);
    return response;
  }

  Future<Response> getById(String path, int id) async {
    Response response = await dio.get("$path/$id");
    return response;
  }

  Future<Response> post(String path, dynamic data) async {
    Response response = await dio.post(path, data: data);
    return response;
  }

  Future<Response> put(String path, int id, dynamic data) async {
    Response response = await dio.put("$path/$id", data: data);
    return response;
  }
}
