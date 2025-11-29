import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  String get _baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    return 'http://10.0.2.2:8000';
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final username = _userController.text.trim();
    final password = _passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnack("Por favor ingrese usuario y contraseña");
      setState(() => _isLoading = false);
      return;
    }

    try {
      final url = Uri.parse('$_baseUrl/login/');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(userId: data['user_id'], username: data['username']),
            ),
          );
        }
      } else {
        _showSnack("Credenciales incorrectas");
      }
    } catch (e) {
      _showSnack("Error de conexión con el servidor");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ICONO ORIGINAL
              const Icon(
                Icons.local_shipping_rounded,
                size: 80,
                color: Colors.indigo,
              ),
              const SizedBox(height: 16),
              const Text(
                "Paquexpress",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Text(
                "Acceso Agentes",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _userController,
                decoration: const InputDecoration(
                  labelText: "Usuario",
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("INGRESAR"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}