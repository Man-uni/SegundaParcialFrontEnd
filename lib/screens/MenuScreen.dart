import 'package:flutter/material.dart';
import 'package:tp1_segunda_parcial_frontend/models/Plato.dart';
import 'package:tp1_segunda_parcial_frontend/screens/CarritoScreen.dart';
import 'package:tp1_segunda_parcial_frontend/screens/MisPedidosScreen.dart';
import 'package:tp1_segunda_parcial_frontend/services/ApiService.dart';
import 'package:tp1_segunda_parcial_frontend/state/Carrito.dart';
import 'package:tp1_segunda_parcial_frontend/utils/format.dart';
import 'package:tp1_segunda_parcial_frontend/utils/ui.dart';

class MenuScreen extends StatefulWidget {
  final Carrito carrito;
  const MenuScreen({super.key, required this.carrito});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _api = ApiService();
  List<Plato> _platos = [];
  bool _cargando = true;
  String? _error;
  String? _categoria; // null = Todos

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final datos = await _api.platos();
      if (mounted) setState(() => _platos = datos);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _abrir(Widget pantalla) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));

  @override
  Widget build(BuildContext context) {
    final categorias = _platos.map((p) => p.categoria).toSet().toList();
    final visibles =
        _categoria == null ? _platos : _platos.where((p) => p.categoria == _categoria).toList();

    return ListenableBuilder(
      listenable: widget.carrito,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Menú'),
          backgroundColor: colorPrincipal,
          foregroundColor: Colors.white,
          actions: [
            TextButton.icon(
              onPressed: () => _abrir(CarritoScreen(carrito: widget.carrito)),
              label: Text(
                'Carrito ${widget.carrito.cantidadItems} · Gs. ${fmtGs(widget.carrito.total)}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () => _abrir(MisPedidosScreen(carrito: widget.carrito)),
              child: const Text('Pedidos', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: _cuerpo(categorias, visibles),
      ),
    );
  }

  Widget _cuerpo(List<String> categorias, List<Plato> visibles) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: const Text('Todos'),
                  selected: _categoria == null,
                  onSelected: (_) => setState(() => _categoria = null),
                ),
              ),
              for (final c in categorias)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: _categoria == c,
                    onSelected: (_) => setState(() => _categoria = c),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: visibles.length,
            itemBuilder: (_, i) {
              final p = visibles[i];
              return ListTile(
                title: Text(p.disponible ? p.nombre : '${p.nombre} (N/D)',
                    style: TextStyle(color: p.disponible ? null : Colors.grey)),
                subtitle: Text(p.categoria),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(fmtGs(p.precio)),
                    TextButton(
                      onPressed: p.disponible ? () => widget.carrito.agregar(p) : null,
                      child: p.disponible ? const Text('[+]') : const Text('[x]'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
