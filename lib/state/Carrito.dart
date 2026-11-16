import 'package:flutter/foundation.dart';
import 'package:tp1_segunda_parcial_frontend/models/Plato.dart';

class LineaCarrito {
  final Plato plato;
  int cantidad;
  LineaCarrito(this.plato, this.cantidad);
  int get subtotal => plato.precio * cantidad;
}

/// Estado único del carrito, compartido entre pantallas por constructor.
class Carrito extends ChangeNotifier {
  final Map<int, LineaCarrito> _lineas = {};

  List<LineaCarrito> get lineas => _lineas.values.toList();
  int get cantidadItems => _lineas.values.fold(0, (s, l) => s + l.cantidad);
  int get total => _lineas.values.fold(0, (s, l) => s + l.subtotal);
  bool get vacio => _lineas.isEmpty;

  void agregar(Plato p) {
    final l = _lineas[p.id];
    if (l == null) {
      _lineas[p.id] = LineaCarrito(p, 1);
    } else {
      l.cantidad++;
    }
    notifyListeners();
  }

  void quitarUno(Plato p) {
    final l = _lineas[p.id];
    if (l == null) return;
    l.cantidad--;
    if (l.cantidad <= 0) _lineas.remove(p.id);
    notifyListeners();
  }

  void vaciar() {
    _lineas.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> itemsParaApi() => _lineas.values
      .map((l) => {'plato_id': l.plato.id, 'cantidad': l.cantidad})
      .toList();
}
