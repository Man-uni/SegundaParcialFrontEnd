class Producto {
  final int? id;
  final String descripcion;
  final int stock;
  final int precio;

  const Producto({
    this.id,
    required this.descripcion,
    required this.stock,
    required this.precio,
  });

  factory Producto.fromJson(Map<String, dynamic> j) => Producto(
        id: j['id'],
        descripcion: j['descripcion'],
        stock: (j['stock'] as num).toInt(),
        precio: (j['precio'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'descripcion': descripcion,
        'stock': stock,
        'precio': precio,
      };
}
