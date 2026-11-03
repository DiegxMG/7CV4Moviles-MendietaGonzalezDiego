import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:permission_handler/permission_handler.dart';

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

class ExploradorView extends StatefulWidget {
  final int temaSeleccionado;
  final ValueChanged<int> onThemeChanged;

  const ExploradorView({
    super.key,
    required this.temaSeleccionado,
    required this.onThemeChanged,
  });

  @override
  State<ExploradorView> createState() => _ExploradorViewState();
}

class _ExploradorViewState extends State<ExploradorView> {
  String? _rutaActual;
  List<FileSystemEntity> _archivos = [];

  Future<void> _seleccionarCarpeta() async {
    // Se agregan los permisos requeridos por Android 11+
    if (Platform.isAndroid) {
      if (!await Permission.manageExternalStorage.isGranted) {
        await Permission.manageExternalStorage.request();
      }
      if (!await Permission.storage.isGranted) {
        await Permission.storage.request();
      }
    }

    String? ruta = await FilePicker.getDirectoryPath();
    if (ruta != null) {
      _cargarDirectorio(ruta);
    }
  }

  void _cargarDirectorio(String ruta) {
    try {
      final directorio = Directory(ruta);
      setState(() {
        _rutaActual = ruta;
        _archivos = directorio.listSync();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al leer el directorio o acceso denegado')),
      );
    }
  }

  Widget _construirBreadcrumbs() {
    if (_rutaActual == null) return const SizedBox.shrink();

    List<String> partes = _rutaActual!.split(Platform.pathSeparator);
    if (partes.isNotEmpty && partes[0].isEmpty) {
      partes[0] = Platform.pathSeparator;
    }

    return Container(
      height: 48,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: partes.length,
        separatorBuilder: (context, index) => const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        itemBuilder: (context, index) {
          final esUltimo = index == partes.length - 1; // Se corrigió el error de sintaxis de tu bloque
          return TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
            ),
            onPressed: esUltimo ? null : () {
              String nuevaRuta = partes.sublist(0, index + 1).join(Platform.pathSeparator);
              if (nuevaRuta.startsWith('${Platform.pathSeparator}${Platform.pathSeparator}')) {
                nuevaRuta = nuevaRuta.substring(1);
              }
              _cargarDirectorio(nuevaRuta);
            },
            child: Text(
              partes[index] == Platform.pathSeparator ? 'Inicio' : partes[index],
              style: TextStyle(
                color: esUltimo ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                fontWeight: esUltimo ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorador de Archivos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          DropdownButton<int>(
            value: widget.temaSeleccionado,
            dropdownColor: Theme.of(context).colorScheme.surface,
            underline: const SizedBox(),
            onChanged: (int? newValue) {
              if (newValue != null) widget.onThemeChanged(newValue);
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
      body: _rutaActual == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            const Text('Ninguna carpeta seleccionada'),
          ],
        ),
      )
          : Column(
        children: [
          _construirBreadcrumbs(),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: _archivos.length,
              itemBuilder: (context, index) {
                final entidad = _archivos[index];
                final esCarpeta = entidad is Directory;
                final nombre = entidad.path.split(Platform.pathSeparator).last;

                return ListTile(
                  leading: Icon(
                    esCarpeta ? Icons.folder : Icons.insert_drive_file,
                    color: esCarpeta ? Colors.amber : Colors.grey,
                  ),
                  title: Text(nombre),
                  onTap: esCarpeta
                      ? () => _cargarDirectorio(entidad.path)
                      : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VisorArchivo(archivo: File(entidad.path)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _seleccionarCarpeta,
        icon: const Icon(Icons.add),
        label: const Text('Seleccionar Carpeta'),
      ),
    );
  }
}

class VisorArchivo extends StatelessWidget {
  final File archivo;

  const VisorArchivo({super.key, required this.archivo});

  @override
  Widget build(BuildContext context) {
    final extension = archivo.path.split('.').last.toLowerCase();
    final esImagen = ['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(extension);
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(archivo.path.split(Platform.pathSeparator).last),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: esImagen
          ? PhotoView(
        imageProvider: FileImage(archivo),
        backgroundDecoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
        enableRotation: true, // <-- Esta es la propiedad que cumple el requisito
      )
          : FutureBuilder<String>(
        future: archivo.readAsString(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al leer el archivo. Es posible que el formato no esté soportado o no sea texto plano.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final contenido = snapshot.data ?? '';
          String lenguaje = 'plaintext';
          if (extension == 'json') lenguaje = 'json';
          if (extension == 'xml') lenguaje = 'xml';

          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: HighlightView(
                  contenido,
                  language: lenguaje,
                  theme: esModoOscuro ? draculaTheme : githubTheme,
                  padding: const EdgeInsets.all(12),
                  textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}