import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart'; 
import 'delivery_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  final String username;

  const HomeScreen({super.key, required this.userId, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _packages = [];
  bool _isLoading = true;

  String get _baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    return 'http://10.0.2.2:8000';
  }

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  Future<void> _fetchPackages() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('$_baseUrl/packages/${widget.userId}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() => _packages = jsonDecode(response.body));
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _logout() {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => const LoginScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text("Envíos Pendientes", style: TextStyle(fontSize: 18)),
            Text("Agente: ${widget.username}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
            tooltip: "Cerrar Sesión",
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _packages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                      SizedBox(height: 10),
                      Text("¡Todo entregado!", style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchPackages,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _packages.length,
                    itemBuilder: (context, index) {
                      final pkg = _packages[index];
                      // DISEÑO ORIGINAL: Card simple
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo[100],
                            child: const Icon(Icons.inventory_2, color: Colors.indigo),
                          ),
                          title: Text(
                            "Guía: ${pkg['tracking_code']}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(pkg['address'], maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(pkg['description'] ?? "Sin descripción", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DeliveryScreen(
                                  packageId: pkg['id'],
                                  trackingCode: pkg['tracking_code'],
                                  address: pkg['address'],
                                ),
                              ),
                            ).then((_) => _fetchPackages());
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}