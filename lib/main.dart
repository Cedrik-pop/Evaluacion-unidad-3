import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const PaquexpressApp());
}

class PaquexpressApp extends StatelessWidget {
  const PaquexpressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paquexpress',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // ESTILO ORIGINAL: Azul Índigo
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
        
        // Configuración de AppBar Original
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
        ),

        // Inputs Originales (Bordes cuadrados simples)
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
          prefixIconColor: Colors.indigo,
        ),
        
        // Botones Originales
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}