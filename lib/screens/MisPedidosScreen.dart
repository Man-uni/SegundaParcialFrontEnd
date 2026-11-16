import 'package:flutter/material.dart';
import 'package:tp1_segunda_parcial_frontend/models/Pedido.dart';
import 'package:tp1_segunda_parcial_frontend/screens/DetallePedidoScreen.dart';
import 'package:tp1_segunda_parcial_frontend/services/ApiService.dart';
import 'package:tp1_segunda_parcial_frontend/state/Carrito.dart';
import 'package:tp1_segunda_parcial_frontend/utils/format.dart';
import 'package:tp1_segunda_parcial_frontend/utils/ui.dart';

Color colorEstado(String estado) => estado == 'pendiente' ? Colors.orange : Colors.green;

class MisPedidosScreen extends StatefulWidget {
  final Carrito carrito;
  const MisPedidosScreen({super.key, required this.carrito});

  @override
  State<MisPedidosScreen> createState() => _MisPedidosScreenState();
}

class _MisPedidosScreenState extends State<MisPedidosScreen> {
  final _api = ApiService();
  List<Pedido> _pedidos = [];
  bool _cargando = true;
  String? _error;

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
      final datos = await _api.pedidos();
      if (mounted) setState(() => _pedidos = datos);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _abrirDetalle(Pedido p) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetallePedidoScreen(pedido: p)),
    );
    if (mounted) _cargar(); // refresca al volver
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pedidos'),
        backgroundColor: colorPrincipal,
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    itemCount: _pedidos.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final p = _pedidos[i];
                      return ListTile(
                        onTap: () => _abrirDetalle(p),
                        title: Text('#${p.id} Mesa ${p.mesa}'),
                        subtitle: Text('${p.cliente}\nGs. ${fmtGs(p.total)}'),
                        isThreeLine: true,
                        trailing: Text(
                          p.estado.toUpperCase(),
                          style: TextStyle(
                              color: colorEstado(p.estado), fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
