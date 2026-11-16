import 'package:flutter_test/flutter_test.dart';
import 'package:tp1_segunda_parcial_frontend/models/Plato.dart';
import 'package:tp1_segunda_parcial_frontend/state/Carrito.dart';

void main() {
  test('Carrito suma, resta y quita', () {
    const p = Plato(id: 1, nombre: 'Empanada', categoria: 'Entradas', precio: 8000, disponible: true);
    final c = Carrito();
    c.agregar(p);
    c.agregar(p);
    expect(c.cantidadItems, 2);
    expect(c.total, 16000);
    c.quitarUno(p);
    c.quitarUno(p);
    expect(c.vacio, true);
  });
}
