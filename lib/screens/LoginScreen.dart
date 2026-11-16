import 'package:flutter/material.dart';
import 'package:tp1_segunda_parcial_frontend/screens/MenuScreen.dart';
import 'package:tp1_segunda_parcial_frontend/services/ApiService.dart';
import 'package:tp1_segunda_parcial_frontend/state/Carrito.dart';
import 'package:tp1_segunda_parcial_frontend/utils/ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _ctrlUsuario = TextEditingController();
  final _ctrlPassword = TextEditingController();
  final _api = ApiService();
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _ctrlUsuario.dispose();
    _ctrlPassword.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await _api.login(_ctrlUsuario.text.trim(), _ctrlPassword.text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MenuScreen(carrito: Carrito())),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
        backgroundColor: colorPrincipal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _ctrlUsuario,
              decoration: const InputDecoration(labelText: 'Usuario', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrlPassword,
              obscureText: true,
              onSubmitted: (_) => _cargando ? null : _ingresar(),
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _cargando ? null : _ingresar,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorPrincipal,
                foregroundColor: Colors.white,
              ),
              child: _cargando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Ingresar'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
