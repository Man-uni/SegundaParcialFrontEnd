import 'package:http/http.dart' as http;
import 'package:tp1_segunda_parcial_frontend/services/TokenStorage.dart';

class ClienteConToken extends http.BaseClient {
  final _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final t = TokenStorage.token;
    if (t != null) request.headers['Authorization'] = 'Bearer $t';
    return _inner.send(request);
  }
}
