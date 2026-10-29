import 'package:flutter/material.dart';

void main() {
  runApp(const GestorArchivosApp());
}

const Color ipnGuinda = Color(0xFF6D203D);
const Color escomAzul = Color(0xFF005DAA);
const Color moradoPersonalizado = Colors.purple;

class GestorArchivosApp extends StatefulWidget {
  const GestorArchivosApp({super.key});

  @override
  State<GestorArchivosApp> createState() => _GestorArchivosAppState();
}

class _GestorArchivosAppState extends State<GestorArchivosApp> {
  int _temaSeleccionado = 0;

  Color get _colorActual {
    switch (_temaSeleccionado) {
      case 1: return escomAzul;
      case 2: return moradoPersonalizado;
      case 0:
      default: return ipnGuinda;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor Multiplataforma',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _colorActual,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _colorActual,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: ExploradorView(
        temaSeleccionado: _temaSeleccionado,
        onThemeChanged: (int val) {
          setState(() {
            _temaSeleccionado = val;
          });
        },
      ),
    );
  }
}

class ExploradorView extends StatelessWidget {
  final int temaSeleccionado;
  final ValueChanged<int> onThemeChanged;

  const ExploradorView({
    super.key,
    required this.temaSeleccionado,
    required this.onThemeChanged
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorador de Archivos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          DropdownButton<int>(
            value: temaSeleccionado,
            dropdownColor: Theme.of(context).colorScheme.surface,
            underline: const SizedBox(),
            onChanged: (int? newValue) {
              if (newValue != null) onThemeChanged(newValue);
            },
            items: const [
              DropdownMenuItem(value: 0, child: Text('Guinda (IPN)')),
              DropdownMenuItem(value: 1, child: Text('Azul (ESCOM)')),
              DropdownMenuItem(value: 2, child: Text('Morado (Personal)')),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            const Text('Espacio para renderizar el sistema de archivos'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
        },
        icon: const Icon(Icons.add),
        label: const Text('Seleccionar Carpeta'),
      ),
    );
  }
}