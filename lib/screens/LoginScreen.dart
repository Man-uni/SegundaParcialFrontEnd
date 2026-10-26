import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tp1_segunda_parcial_frontend/screens/ListaVentasScreen.dart';
import 'package:tp1_segunda_parcial_frontend/services/TokenStorage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _ctrlUsuario  = TextEditingController();
  final _ctrlPassword = TextEditingController();
  bool    _cargando = false;
  String? _error;

  @override
  void dispose() {
    _ctrlUsuario.dispose();
    _ctrlPassword.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final r = await http.post(
        Uri.parse('http://localhost:4002/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'usuario': _ctrlUsuario.text.trim(), 'password': _ctrlPassword.text}),
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        TokenStorage.token = jsonDecode(r.body)['token'] as String;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ListaVentasScreen()));
      } else {
        setState(() => _error = 'Usuario/password incorrectos');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Error de conexión');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
        backgroundColor: const Color(0xFF1B263B),
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
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _cargando ? null : _ingresar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B263B),
                foregroundColor: Colors.white,
              ),
              child: _cargando
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
