import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

// ======================== RECONOCIMIENTO ========================
class ReconocimientoVista extends StatefulWidget {
  @override
  _ReconocimientoVistaState createState() => _ReconocimientoVistaState();
}

class _ReconocimientoVistaState extends State<ReconocimientoVista> {
  String resultado = "Selecciona una imagen para identificar.";
  File? imagen;

  Future<void> seleccionarYEnviarImagen({required ImageSource origen}) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: origen);
    if (pickedFile == null) return;

    File originalImage = File(pickedFile.path);
    File resizedImage = await _optimizarImagen(originalImage);

    setState(() {
      imagen = resizedImage;
      resultado = "Procesando imagen...";
    });

    final uri = Uri.parse("https://apprun-987541220483.us-west1.run.app/reconocer");
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('imagen', resizedImage.path));

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(respStr);
        if (data["status"] == "identificado") {
          bool requisitoriado = data["requisitoriado"] == true;
          setState(() {
            resultado = "Estudiante: ${data["nombres"]} ${data["apellidos"]}\n"
                "ID: ${data["id_estudiante"]}\n"
                "Correo: ${data["correo"]}\n"
                "Requisitoriado: ${requisitoriado ? 'Sí' : 'No'}";
          });
          if (requisitoriado) _mostrarAlertaRequisitoriado(context, data);
        } else {
          setState(() => resultado = "No identificado.");
        }
      } else {
        setState(() => resultado = "Error del servidor");
      }
    } catch (_) {
      setState(() => resultado = "Error al conectar");
    }
  }

  Future<File> _optimizarImagen(File file) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return file;
    if (image.width > 800 || image.height > 800) {
      image = img.copyResize(image, width: 800);
    }
    final tempDir = await getTemporaryDirectory();
    final resizedPath = path.join(tempDir.path, "resized_${DateTime.now().millisecondsSinceEpoch}.jpg");
    return File(resizedPath)..writeAsBytesSync(img.encodeJpg(image, quality: 85));
  }

  Future<void> _mostrarAlertaRequisitoriado(BuildContext context, Map data) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("¡Alerta!"),
        content: Text("El estudiante ${data["nombres"]} ${data["apellidos"]} está requisitoriado."),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text("Cerrar")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            imagen != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(imagen!, height: 200),
            )
                : Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Icon(Icons.image, size: 50)),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3B3B98),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(Icons.photo),
              label: Text("Seleccionar desde galería"),
              onPressed: () => seleccionarYEnviarImagen(origen: ImageSource.gallery),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3B3B98),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(Icons.camera_alt),
              label: Text("Tomar foto"),
              onPressed: () => seleccionarYEnviarImagen(origen: ImageSource.camera),
            ),
            SizedBox(height: 20),
            Text(resultado, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ======================== REGISTRO ========================
class RegistroVista extends StatefulWidget {
  @override
  _RegistroVistaState createState() => _RegistroVistaState();
}

class _RegistroVistaState extends State<RegistroVista> {
  File? _imagen;
  final picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final _idController = TextEditingController();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _correoController = TextEditingController();
  bool _requisitoriado = false;

  String _mensaje = "";
  bool _enviando = false;

  Future<void> _tomarFoto() async {
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    File originalImage = File(pickedFile.path);
    File resizedImage = await _optimizarImagen(originalImage);

    setState(() {
      _imagen = resizedImage;
    });
  }

  Future<File> _optimizarImagen(File file) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return file;
    if (image.width > 800 || image.height > 800) {
      image = img.copyResize(image, width: 800);
    }
    final tempDir = await getTemporaryDirectory();
    final resizedPath = path.join(tempDir.path, "resized_${DateTime.now().millisecondsSinceEpoch}.jpg");
    return File(resizedPath)..writeAsBytesSync(img.encodeJpg(image, quality: 85));
  }

  Future<void> _enviarDatos() async {
    if (_imagen == null) {
      setState(() => _mensaje = "Por favor toma una foto.");
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _enviando = true;
      _mensaje = "";
    });

    final uri = Uri.parse("https://apprun-987541220483.us-west1.run.app/registrar");

    var request = http.MultipartRequest('POST', uri);
    request.fields['id_estudiante'] = _idController.text.trim();
    request.fields['nombres'] = _nombresController.text.trim();
    request.fields['apellidos'] = _apellidosController.text.trim();
    request.fields['correo'] = _correoController.text.trim();
    request.fields['requisitoriado'] = _requisitoriado ? "true" : "false";
    request.files.add(await http.MultipartFile.fromPath('imagen', _imagen!.path));

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      setState(() {
        _mensaje = response.statusCode == 200
            ? json.decode(respStr)["mensaje"] ?? "Registro exitoso."
            : "Error del servidor";
      });
    } catch (_) {
      setState(() => _mensaje = "Error al conectar");
    } finally {
      setState(() => _enviando = false);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  String? _validar(String? value) => (value == null || value.isEmpty) ? "Campo requerido" : null;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          _imagen != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_imagen!, height: 200),
          )
              : Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Icon(Icons.camera_alt, size: 50)),
          ),
          SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3B3B98),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _tomarFoto,
            icon: Icon(Icons.camera_alt),
            label: Text("Tomar foto"),
          ),
          SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _idController,
                  decoration: InputDecoration(labelText: "ID Estudiante", border: OutlineInputBorder()),
                  validator: _validar,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _nombresController,
                  decoration: InputDecoration(labelText: "Nombres", border: OutlineInputBorder()),
                  validator: _validar,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _apellidosController,
                  decoration: InputDecoration(labelText: "Apellidos", border: OutlineInputBorder()),
                  validator: _validar,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _correoController,
                  decoration: InputDecoration(labelText: "Correo", border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Ingrese correo";
                    return RegExp(r"^[^\\s@]+@[^\\s@]+\\.[^\\s@]+\$").hasMatch(value) ? null : "Correo inválido";
                  },
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: _requisitoriado,
                      activeColor: Color(0xFF3B3B98),
                      onChanged: (val) => setState(() => _requisitoriado = val ?? false),
                    ),
                    Text("Requisitoriado"),
                  ],
                ),
                SizedBox(height: 20),
                _enviando
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3B3B98),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _enviarDatos,
                  child: Text("Enviar"),
                ),
                SizedBox(height: 20),
                Text(_mensaje, textAlign: TextAlign.center),
              ],
            ),
          )
        ],
      ),
    );
  }
}


// ======================== ESTUDIANTES ========================
class EstudiantesVista extends StatefulWidget {
  @override
  _EstudiantesVistaState createState() => _EstudiantesVistaState();
}

class _EstudiantesVistaState extends State<EstudiantesVista> {
  List<dynamic> estudiantes = [];
  List<dynamic> filtrados = [];
  bool cargando = true;
  String busqueda = '';
  bool soloRequisitoriados = false;
  final _controller = TextEditingController();
  final String baseUrl = "https://apprun-987541220483.us-west1.run.app";

  @override
  void initState() {
    super.initState();
    _controller.addListener(_filtrar);
    _cargar();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      cargando = true;
    });
    try {
      final res = await http.get(Uri.parse("$baseUrl/estudiantes"));
      if (res.statusCode == 200) {
        estudiantes = json.decode(res.body);
        _filtrar();
      } else {
        setState(() => cargando = false);
      }
    } catch (_) {
      setState(() => cargando = false);
    }
  }

  void _filtrar() {
    final q = _controller.text.toLowerCase();
    setState(() {
      filtrados = estudiantes.where((e) {
        final coincide = e['nombres'].toString().toLowerCase().contains(q) ||
            e['apellidos'].toString().toLowerCase().contains(q) ||
            e['id_estudiante'].toString().contains(q);
        final requis = !soloRequisitoriados || e['requisitoriado'] == true;
        return coincide && requis;
      }).toList();
      cargando = false;
    });
  }

  Future<void> _eliminar(String id) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirmar"),
        content: Text("¿Eliminar estudiante $id?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Eliminar")),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await http.delete(Uri.parse("$baseUrl/estudiantes/$id"));
    if (res.statusCode == 200) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) return Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Buscar por ID, nombre o apellido',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                value: soloRequisitoriados,
                activeColor: Color(0xFF3B3B98),
                onChanged: (v) => setState(() {
                  soloRequisitoriados = v ?? false;
                  _filtrar();
                }),
              ),
              Text("Solo requisitoriados"),
            ],
          ),
          SizedBox(height: 10),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              child: filtrados.isEmpty
                  ? Center(child: Text("No se encontraron estudiantes."))
                  : ListView.builder(
                itemCount: filtrados.length,
                itemBuilder: (_, i) {
                  final e = filtrados[i];
                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    shadowColor: Colors.grey.withOpacity(0.3),
                    child: ListTile(
                      title: Text("${e['nombres']} ${e['apellidos']}"),
                      subtitle: Text(
                          "ID: ${e['id_estudiante']}\nCorreo: ${e['correo']}\nRequisitoriado: ${e['requisitoriado']}"),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminar(e['id_estudiante']),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
