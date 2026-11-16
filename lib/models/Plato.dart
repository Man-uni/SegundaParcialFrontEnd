class Plato {
  final int id;
  final String nombre;
  final String categoria;
  final int precio;
  final bool disponible;

  const Plato({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.disponible,
  });

  factory Plato.fromJson(Map<String, dynamic> j) => Plato(
        id: j['id'],
        nombre: j['nombre'],
        categoria: j['categoria'],
        precio: (j['precio'] as num).toInt(),
        disponible: j['disponible'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'categoria': categoria,
        'precio': precio,
        'disponible': disponible,
      };
}
