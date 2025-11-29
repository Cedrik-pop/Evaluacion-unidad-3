import 'dart:typed_data'; // Importante para Uint8List
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class DeliveryScreen extends StatefulWidget {
  final int packageId;
  final String trackingCode;
  final String address;

  const DeliveryScreen({
    super.key,
    required this.packageId,
    required this.trackingCode,
    required this.address,
  });

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  LatLng _currentPosition = const LatLng(20.5888, -100.3899);
  bool _isLoadingLocation = true;
  bool _isSubmitting = false;
  
  // LOGICA SEGURA (Compatible con Web y Móvil)
  Uint8List? _evidenceBytes;
  
  final MapController _mapController = MapController();

  String get _baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    return 'http://10.0.2.2:8000';
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack("El GPS está desactivado.");
      setState(() => _isLoadingLocation = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoadingLocation = false);
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
      _mapController.move(_currentPosition, 16.0);
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    
    if (photo != null) {
      // Leemos bytes para evitar errores de path en Web
      final bytes = await photo.readAsBytes();
      setState(() {
        _evidenceBytes = bytes;
      });
    }
  }

  Future<void> _submitDelivery() async {
    if (_evidenceBytes == null) {
      _showSnack("Debes tomar una foto de evidencia.");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      var uri = Uri.parse('$_baseUrl/deliver/${widget.packageId}');
      var request = http.MultipartRequest('POST', uri);
      
      request.fields['latitude'] = _currentPosition.latitude.toString();
      request.fields['longitude'] = _currentPosition.longitude.toString();
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file', 
          _evidenceBytes!,
          filename: 'evidence.jpg'
        )
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        _showSnack("¡Entrega registrada con éxito!");
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      } else {
        _showSnack("Error al subir: ${response.statusCode}");
      }

    } catch (e) {
      _showSnack("Error de conexión al enviar evidencia.");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmar Entrega"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // SECCIÓN 1: MAPA (Original, 40% pantalla)
          Expanded(
            flex: 4, 
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentPosition,
                          width: 80,
                          height: 80,
                          // Marcador ROJO original
                          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_isLoadingLocation)
                  const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Obteniendo GPS..."),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // SECCIÓN 2: DETALLES (Original, panel blanco)
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Guía: ${widget.trackingCode}", 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.map, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(child: Text(widget.address, style: const TextStyle(fontSize: 16))),
                      ],
                    ),
                    const Divider(height: 30),

                    const Text("Evidencia Fotográfica:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Center(
                      child: GestureDetector(
                        onTap: _takePhoto,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                            // Mostrar imagen desde memoria
                          ),
                          child: _evidenceBytes == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                                    Text("Tocar para tomar foto"),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(_evidenceBytes!, fit: BoxFit.cover),
                                ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitDelivery,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _isSubmitting 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_circle),
                        label: Text(_isSubmitting ? "ENVIANDO..." : "FINALIZAR ENTREGA"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}