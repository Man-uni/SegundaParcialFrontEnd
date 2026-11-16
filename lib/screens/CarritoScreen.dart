import 'package:flutter/material.dart';
import 'package:tp1_segunda_parcial_frontend/screens/MisPedidosScreen.dart';
import 'package:tp1_segunda_parcial_frontend/services/ApiService.dart';
import 'package:tp1_segunda_parcial_frontend/state/Carrito.dart';
import 'package:tp1_segunda_parcial_frontend/utils/format.dart';
import 'package:tp1_segunda_parcial_frontend/utils/ui.dart';

class CarritoScreen extends StatefulWidget {
  final Carrito carrito;
  const CarritoScreen({super.key, required this.carrito});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  final _api = ApiService();
  final _ctrlMesa = TextEditingController();
  final _ctrlCliente = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _ctrlMesa.dispose();
    _ctrlCliente.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final mesa = int.tryParse(_ctrlMesa.text.trim());
    final cliente = _ctrlCliente.text.trim();
    if (widget.carrito.vacio) return mostrarError(context, 'El carrito está vacío');
    if (mesa == null || mesa <= 0) return mostrarError(context, 'La mesa debe ser un entero mayor a 0');
    if (cliente.isEmpty) return mostrarError(context, 'Ingrese el nombre del cliente');

    setState(() => _enviando = true);
    try {
      await _api.crearPedido(mesa, cliente, widget.carrito.itemsParaApi());
      widget.carrito.vaciar();
      if (!mounted) return;
      // Reemplaza el carrito por "Mis pedidos" (queda el menú debajo).
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MisPedidosScreen(carrito: widget.carrito)),
      );
    } on ApiException catch (e) {
      if (mounted) mostrarError(context, e.mensaje);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.carrito,
      builder: (context, _) {
        final lineas = widget.carrito.lineas;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Carrito'),
            backgroundColor: colorPrincipal,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              Expanded(
                child: lineas.isEmpty
                    ? const Center(child: Text('El carrito está vacío'))
                    : ListView.builder(
                        itemCount: lineas.length,
                        itemBuilder: (_, i) {
                          final l = lineas[i];
                          return ListTile(
                            title: Text(l.plato.nombre),
                            subtitle: Text(fmtGs(l.plato.precio)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => widget.carrito.quitarUno(l.plato),
                                  child: const Text('-'),
                                ),
                                Text('${l.cantidad}'),
                                TextButton(
                                  onPressed: () => widget.carrito.agregar(l.plato),
                                  child: const Text('+'),
                                ),
                                SizedBox(
                                  width: 70,
                                  child: Text(fmtGs(l.subtotal), textAlign: TextAlign.right),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Total: Gs. ${fmtGs(widget.carrito.total)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _ctrlMesa,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Mesa', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _ctrlCliente,
                            decoration: const InputDecoration(
                                labelText: 'Cliente', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _enviando ? null : _confirmar,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: colorPrincipal, foregroundColor: Colors.white),
                      child: _enviando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Confirmar pedido'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
