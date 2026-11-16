import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tp1_segunda_parcial_frontend/models/Pedido.dart';
import 'package:tp1_segunda_parcial_frontend/models/Plato.dart';
import 'package:tp1_segunda_parcial_frontend/services/ClienteConToken.dart';
import 'package:tp1_segunda_parcial_frontend/services/TokenStorage.dart';

class ApiException implements Exception {
  final int? status;
  final String mensaje;
  ApiException(this.mensaje, [this.status]);
  @override
  String toString() => mensaje;
}

class ApiService {
  // Emulador Android: http://10.0.2.2:4004
  static const _base = 'http://localhost:4004';
  static const _json = {'Content-Type': 'application/json'};

  // El Bearer se agrega en un único lugar: ClienteConToken.
  final _client = ClienteConToken();

  Future<http.Response> _enviar(Future<http.Response> Function() f) async {
    try {
      return await f();
    } catch (_) {
      throw ApiException('No se pudo conectar con el servidor');
    }
  }

  String _mensaje(http.Response r) {
    try {
      return jsonDecode(r.body)['error']?.toString() ?? 'Error ${r.statusCode}';
    } catch (_) {
      return 'Error ${r.statusCode}';
    }
  }

  Future<void> login(String usuario, String password) async {
    final r = await _enviar(() => http.post(
          Uri.parse('$_base/login'),
          headers: _json,
          body: jsonEncode({'usuario': usuario, 'password': password}),
        ));
    if (r.statusCode == 200) {
      TokenStorage.token = jsonDecode(r.body)['token'] as String;
    } else if (r.statusCode == 401) {
      throw ApiException('Usuario/password incorrectos', 401);
    } else {
      throw ApiException(_mensaje(r), r.statusCode);
    }
  }

  Future<List<Plato>> platos({String? categoria}) async {
    final uri = Uri.parse('$_base/platos')
        .replace(queryParameters: categoria != null ? {'categoria': categoria} : null);
    final r = await _enviar(() => _client.get(uri));
    if (r.statusCode != 200) throw ApiException(_mensaje(r), r.statusCode);
    return (jsonDecode(r.body) as List).map((j) => Plato.fromJson(j)).toList();
  }

  Future<List<Pedido>> pedidos() async {
    final r = await _enviar(() => _client.get(Uri.parse('$_base/pedidos')));
    if (r.statusCode != 200) throw ApiException(_mensaje(r), r.statusCode);
    return (jsonDecode(r.body) as List).map((j) => Pedido.fromJson(j)).toList();
  }

  Future<Pedido> crearPedido(int mesa, String cliente, List<Map<String, dynamic>> items) async {
    final r = await _enviar(() => _client.post(
          Uri.parse('$_base/pedidos'),
          headers: _json,
          body: jsonEncode({'mesa': mesa, 'cliente': cliente, 'items': items}),
        ));
    if (r.statusCode == 201) return Pedido.fromJson(jsonDecode(r.body));
    throw ApiException(_mensaje(r), r.statusCode);
  }

  Future<Pedido> marcarEntregado(int id) async {
    final r = await _enviar(() => _client.put(
          Uri.parse('$_base/pedidos/$id/estado'),
          headers: _json,
          body: jsonEncode({'estado': 'entregado'}),
        ));
    if (r.statusCode == 200) return Pedido.fromJson(jsonDecode(r.body));
    throw ApiException(_mensaje(r), r.statusCode);
  }

  Future<void> cancelarPedido(int id) async {
    final r = await _enviar(() => _client.delete(Uri.parse('$_base/pedidos/$id')));
    if (r.statusCode != 200) throw ApiException(_mensaje(r), r.statusCode);
  }
}
