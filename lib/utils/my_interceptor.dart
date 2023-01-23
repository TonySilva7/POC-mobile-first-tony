import 'package:dio/dio.dart';

class MyInterceptor implements InterceptorsWrapper {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    /* TODO: Todas as vezes que for fazer um POST, PUT, DELETE, verificar se o App está 
      online, se estiver, fazer a requisição normalmente, se não estiver, 
      salvar no banco de dados o path e o body.
    */

    // set token
    // String token = "12341234k134jqwerqwer1234";
    // insert authorization in headers
    // options.headers["Authorization"] = "Bearer $token"; // add token in header

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // TODO: Se o método for GET, salva no banco de dados o path e o response.data

    handler.next(response);
    print("Foi requisitado: ${response.requestOptions.path} com ${response.requestOptions.method}}");
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    /* TODO: Verificar se no banco de dados existe o path, se existir, 
      pegar o dado referente a ele e setar no estado do App.
    */
    print("Erro da request: ${err.requestOptions.path} com ${err.requestOptions.method}}");
    print("Oops, deu erro: ${err.message}");
    print("Erro: ${err.error?.message}");
  }
}
