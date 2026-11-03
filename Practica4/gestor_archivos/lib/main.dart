import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

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

  // Variables para gestionar Copiar y Mover
  FileSystemEntity? _entidadPortapapeles;
  String? _accionPortapapeles;

  Future<void> _seleccionarCarpeta() async {
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

  void _mostrarMetadatos(FileSystemEntity entidad) {
    final esCarpeta = entidad is Directory;
    final nombre = entidad.path.split(Platform.pathSeparator).last;
    String tamanoStr = 'No disponible';
    String fechaStr = 'No disponible';
    String tipoMime = esCarpeta ? 'Directorio' : 'Desconocido';

    try {
      final stats = entidad.statSync();
      fechaStr = stats.modified.toString().split('.')[0];

      if (!esCarpeta) {
        tamanoStr = '${(stats.size / 1024).toStringAsFixed(2)} KB';
        final ext = nombre.contains('.') ? nombre.split('.').last.toLowerCase() : '';
        switch(ext) {
          case 'jpg':
          case 'jpeg': tipoMime = 'image/jpeg'; break;
          case 'png': tipoMime = 'image/png'; break;
          case 'gif': tipoMime = 'image/gif'; break;
          case 'webp': tipoMime = 'image/webp'; break;
          case 'txt': tipoMime = 'text/plain'; break;
          case 'json': tipoMime = 'application/json'; break;
          case 'xml': tipoMime = 'application/xml'; break;
          case 'pdf': tipoMime = 'application/pdf'; break;
          case 'mp4': tipoMime = 'video/mp4'; break;
          case 'mp3': tipoMime = 'audio/mpeg'; break;
          default: tipoMime = ext.isNotEmpty ? 'application/octet-stream ($ext)' : 'No disponible';
        }
      }
    } catch (e) {
      // Ignora el error y mantiene "No disponible"
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Metadatos del archivo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre:', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            Text(nombre),
            const SizedBox(height: 8),
            Text('Tipo (MIME):', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            Text(tipoMime),
            const SizedBox(height: 8),
            Text('Tamaño:', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            Text(tamanoStr),
            const SizedBox(height: 8),
            Text('Modificación:', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            Text(fechaStr),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoNoSoportado(String ruta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Formato no soportado'),
        content: const Text('Este tipo de archivo no se puede visualizar nativamente en la aplicación. ¿Deseas compartirlo o abrirlo con otra aplicación del sistema?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Share.shareXFiles([XFile(ruta)], text: 'Exportando archivo');
            },
            child: const Text('Exportar / Compartir'),
          ),
        ],
      ),
    );
  }

  // --- OPERACIONES DE GESTIÓN (NUEVO) ---

  void _eliminar(FileSystemEntity entidad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar este elemento de forma permanente?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              try {
                entidad.deleteSync(recursive: true);
                _cargarDirectorio(_rutaActual!);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Permisos insuficientes para eliminar')));
              }
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _renombrar(FileSystemEntity entidad) {
    final TextEditingController controlador = TextEditingController(text: entidad.path.split(Platform.pathSeparator).last);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar'),
        content: TextField(
          controller: controlador,
          decoration: const InputDecoration(labelText: 'Nuevo nombre'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              try {
                final nuevoPath = '${entidad.parent.path}${Platform.pathSeparator}${controlador.text}';
                entidad.renameSync(nuevoPath);
                _cargarDirectorio(_rutaActual!);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al renombrar el archivo')));
              }
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _copiarDirectorio(Directory origen, Directory destino) {
    destino.createSync(recursive: true);
    for (var entidad in origen.listSync(recursive: false)) {
      final nuevoPath = '${destino.path}${Platform.pathSeparator}${entidad.path.split(Platform.pathSeparator).last}';
      if (entidad is Directory) {
        _copiarDirectorio(entidad, Directory(nuevoPath));
      } else if (entidad is File) {
        entidad.copySync(nuevoPath);
      }
    }
  }

  void _ejecutarPegar() {
    if (_entidadPortapapeles == null || _rutaActual == null) return;

    final nombre = _entidadPortapapeles!.path.split(Platform.pathSeparator).last;
    final destinoPath = '$_rutaActual${Platform.pathSeparator}$nombre';

    try {
      if (_accionPortapapeles == 'mover') {
        _entidadPortapapeles!.renameSync(destinoPath);
      } else if (_accionPortapapeles == 'copiar') {
        if (_entidadPortapapeles is Directory) {
          _copiarDirectorio(_entidadPortapapeles! as Directory, Directory(destinoPath));
        } else if (_entidadPortapapeles is File) {
          (_entidadPortapapeles! as File).copySync(destinoPath);
        }
      }
      setState(() {
        _entidadPortapapeles = null;
        _accionPortapapeles = null;
      });
      _cargarDirectorio(_rutaActual!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de permisos al procesar la operación')));
    }
  }

  // --------------------------------------

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
          final esUltimo = index == partes.length - 1; // Corrección del error tipográfico
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
                final extension = nombre.contains('.') ? nombre.split('.').last.toLowerCase() : '';
                final esSoportado = ['png', 'jpg', 'jpeg', 'gif', 'webp', 'txt', 'json', 'xml'].contains(extension);

                return ListTile(
                  leading: Icon(
                    esCarpeta ? Icons.folder : Icons.insert_drive_file,
                    color: esCarpeta ? Colors.amber : Colors.grey,
                  ),
                  title: Text(nombre),
                  // Se reemplazó el IconButton por un PopupMenuButton para albergar todas las acciones
                  trailing: PopupMenuButton<String>(
                    onSelected: (valor) {
                      switch (valor) {
                        case 'info': _mostrarMetadatos(entidad); break;
                        case 'copiar':
                          setState(() {
                            _entidadPortapapeles = entidad;
                            _accionPortapapeles = 'copiar';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copiado. Navega al destino y presiona Pegar.')));
                          break;
                        case 'mover':
                          setState(() {
                            _entidadPortapapeles = entidad;
                            _accionPortapapeles = 'mover';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listo para mover. Navega al destino y presiona Pegar.')));
                          break;
                        case 'renombrar': _renombrar(entidad); break;
                        case 'eliminar': _eliminar(entidad); break;
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(value: 'info', child: Text('Información')),
                      const PopupMenuItem<String>(value: 'copiar', child: Text('Copiar')),
                      const PopupMenuItem<String>(value: 'mover', child: Text('Mover')),
                      const PopupMenuItem<String>(value: 'renombrar', child: Text('Renombrar')),
                      const PopupMenuItem<String>(value: 'eliminar', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                    ],
                    icon: const Icon(Icons.more_vert),
                  ),
                  onTap: esCarpeta
                      ? () => _cargarDirectorio(entidad.path)
                      : () {
                    if (esSoportado) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => VisorArchivo(archivo: File(entidad.path))),
                      );
                    } else {
                      _mostrarDialogoNoSoportado(entidad.path);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Se agregó un botón de pegado flotante condicional
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_entidadPortapapeles != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton.extended(
                heroTag: 'btnPegar',
                onPressed: _ejecutarPegar,
                icon: const Icon(Icons.paste),
                label: Text('Pegar (${_accionPortapapeles})'),
              ),
            ),
          FloatingActionButton.extended(
            heroTag: 'btnSeleccionar',
            onPressed: _seleccionarCarpeta,
            icon: const Icon(Icons.add),
            label: const Text('Seleccionar Carpeta'),
          ),
        ],
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
        enableRotation: true,
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