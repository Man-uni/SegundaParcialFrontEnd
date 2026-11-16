import 'package:flutter/material.dart';

const colorPrincipal = Color(0xFF1B263B);

void mostrarError(BuildContext context, Object e) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
}
