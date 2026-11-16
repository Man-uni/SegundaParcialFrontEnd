import 'dart:convert';
import 'package:tp1_segunda_parcial_frontend/models/Venta.dart';
import 'package:tp1_segunda_parcial_frontend/services/ClienteConToken.dart';
import 'package:tp1_segunda_parcial_frontend/models/Producto.dart';

class VentaService {
  static const _base = 'http://localhost:4002/ventas';
  final _client = ClienteConToken();

  Future<List<Venta>> listar() async {
    final r = await _client.get(Uri.parse(_base));
    if (r.statusCode == 401) throw Exception('401');
    final List datos = jsonDecode(r.body);
    return datos.map((j) => Venta.fromJson(j)).toList();
  }

  Future<List<Producto>> listarproductos() async {
    final r = await _client.get(Uri.parse("http://localhost:4002/productos"));
    if (r.statusCode == 401) throw Exception('401');
    final List datos = jsonDecode(r.body);
    return datos.map((j) => Producto.fromJson(j)).toList();
  }

  Future<Venta> agregar(Venta v) async {
    final r = await _client.post(
      Uri.parse(_base),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(v.toJson()),
    );
    if (r.statusCode == 401) throw Exception('401');
    if (r.statusCode == 201) return Venta.fromJson(jsonDecode(r.body));
    throw Exception('Error ${r.statusCode}');
  }
}
