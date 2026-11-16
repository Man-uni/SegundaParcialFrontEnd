class ItemPedido {
  final int platoId;
  final String nombre;
  final int precio;
  final int cantidad;
  final int subtotal;

  const ItemPedido({
    required this.platoId,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    required this.subtotal,
  });

  factory ItemPedido.fromJson(Map<String, dynamic> j) => ItemPedido(
        platoId: j['plato_id'],
        nombre: j['nombre'],
        precio: (j['precio'] as num).toInt(),
        cantidad: (j['cantidad'] as num).toInt(),
        subtotal: (j['subtotal'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'plato_id': platoId,
        'nombre': nombre,
        'precio': precio,
        'cantidad': cantidad,
        'subtotal': subtotal,
      };
}

class Pedido {
  final int id;
  final String fecha;
  final int mesa;
  final String cliente;
  final String estado;
  final int total;
  final List<ItemPedido> items;

  const Pedido({
    required this.id,
    required this.fecha,
    required this.mesa,
    required this.cliente,
    required this.estado,
    required this.total,
    required this.items,
  });

  bool get pendiente => estado == 'pendiente';

  factory Pedido.fromJson(Map<String, dynamic> j) => Pedido(
        id: j['id'],
        fecha: j['fecha'] ?? '',
        mesa: (j['mesa'] as num).toInt(),
        cliente: j['cliente'],
        estado: j['estado'],
        total: (j['total'] as num).toInt(),
        items: (j['items'] as List).map((e) => ItemPedido.fromJson(e)).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha': fecha,
        'mesa': mesa,
        'cliente': cliente,
        'estado': estado,
        'total': total,
        'items': items.map((e) => e.toJson()).toList(),
      };
}
