import 'package:flutter/material.dart';
import 'package:tp1_segunda_parcial_frontend/models/Pedido.dart';
import 'package:tp1_segunda_parcial_frontend/screens/MisPedidosScreen.dart' show colorEstado;
import 'package:tp1_segunda_parcial_frontend/services/ApiService.dart';
import 'package:tp1_segunda_parcial_frontend/utils/format.dart';
import 'package:tp1_segunda_parcial_frontend/utils/ui.dart';

class DetallePedidoScreen extends StatefulWidget {
  final Pedido pedido;
  const DetallePedidoScreen({super.key, required this.pedido});

  @override
  State<DetallePedidoScreen> createState() => _DetallePedidoScreenState();
}

class _DetallePedidoScreenState extends State<DetallePedidoScreen> {
  final _api = ApiService();
  late Pedido _pedido = widget.pedido;
  bool _ocupado = false;

  Future<void> _entregar() async {
    setState(() => _ocupado = true);
    try {
      final p = await _api.marcarEntregado(_pedido.id);
      if (mounted) setState(() => _pedido = p);
    } on ApiException catch (e) {
      if (mounted) mostrarError(context, e.mensaje);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _cancelar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: Text('¿Seguro que desea cancelar el pedido #${_pedido.id}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _ocupado = true);
    try {
      await _api.cancelarPedido(_pedido.id);
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) mostrarError(context, e.mensaje);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${_pedido.id} - Mesa ${_pedido.mesa}'),
        backgroundColor: colorPrincipal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Cliente: ${_pedido.cliente}'),
            Row(children: [
              const Text('Estado: '),
              Text(_pedido.estado.toUpperCase(),
                  style: TextStyle(
                      color: colorEstado(_pedido.estado), fontWeight: FontWeight.bold)),
            ]),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  for (final it in _pedido.items)
                    ListTile(
                      dense: true,
                      title: Text('${it.cantidad} x ${it.nombre}'),
                      trailing: Text(fmtGs(it.subtotal)),
                    ),
                ],
              ),
            ),
            Text('Total: Gs. ${fmtGs(_pedido.total)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_pedido.pendiente) ...[
              ElevatedButton(
                onPressed: _ocupado ? null : _entregar,
                child: const Text('Marcar entregado'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _ocupado ? null : _cancelar,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Cancelar pedido'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
