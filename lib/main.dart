import 'package:flutter/material.dart';
import 'logica.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reconocimiento Facial AI',
      theme: ThemeData(
        primaryColor: Color(0xFF0A3D62),
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF0A3D62)),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),

        useMaterial3: true,
      ),
      home: const MenuDrawerApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MenuDrawerApp extends StatefulWidget {
  const MenuDrawerApp({super.key});

  @override
  State<MenuDrawerApp> createState() => _MenuDrawerAppState();
}

class _MenuDrawerAppState extends State<MenuDrawerApp> {
  int _paginaSeleccionada = 0;

  final List<Widget> _paginas = [
    ReconocimientoVista(),
    RegistroVista(),
    EstudiantesVista(),
  ];

  final List<String> _titulos = [
    'Reconocimiento Facial',
    'Registrar Estudiante',
    'Lista de Estudiantes',
  ];

  void _cambiarPagina(int index) {
    Navigator.pop(context); // Cierra el drawer
    setState(() {
      _paginaSeleccionada = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
          title: Text(_titulos[_paginaSeleccionada], style: Theme.of(context).textTheme.titleLarge),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF3B3B98), Color(0xFF0A3D62)]),
              ),
              child: const Center(
                child: Text('Menú Principal', style: TextStyle(color: Colors.white, fontSize: 22)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.face),
              title: const Text('Reconocer'),
              onTap: () => _cambiarPagina(0),
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt),
              title: const Text('Registrar'),
              onTap: () => _cambiarPagina(1),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Estudiantes'),
              onTap: () => _cambiarPagina(2),
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: _paginas[_paginaSeleccionada],
      ),
    );
  }
}
