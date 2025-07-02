import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AgregarEventoScreen extends StatefulWidget {
  final User user;
  const AgregarEventoScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<AgregarEventoScreen> createState() => _AgregarEventoScreenState();
}

class _AgregarEventoScreenState extends State<AgregarEventoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _capacidadController = TextEditingController();
  final _costoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _horaController = TextEditingController();
  final _contactoController = TextEditingController();
  final _etiquetasController = TextEditingController();
  final _politicasController = TextEditingController();
  final _fechaController = TextEditingController();
  final _cuentaBancariaController = TextEditingController();
  final _nequiController = TextEditingController();
  final _daviplataController = TextEditingController();

  // Zonas de la ciudad
  final List<String> _zonas = [
    'Norte', 'Occidente', 'Oriente', 'Sur', 
    'Noroccidente', 'Nororiente', 'Suroccidente', 'Suroriente'
  ];

  // Medios de pago
  final List<String> _mediosDePagoDisponibles = [
    'Efectivo',
    'Tarjeta crédito/débito',
    'Transferencia bancaria',
    'Nequi',
    'Daviplata'
  ];
  List<String> _mediosSeleccionados = [];
  
  String? _zonaSeleccionada;
  String? _tipoSeleccionado;
  bool _accesibilidad = false;
  bool _parqueadero = false;
  bool _esGratis = true; // Nuevo campo para evento gratis

  File? _imageFile;
  bool _isLoading = false;
  LatLng? _ubicacionEvento;
  final List<String> _tiposEvento = [
    'Gastrobar', 'Discotecas', 'Cultural', 'Deportivo'
  ];

  // Mapa de imágenes predeterminadas por tipo de evento
  final Map<String, String> _imagenesPredeterminadas = {
    'Gastrobar': 'assets/eventos/gastrobar.jpg',
    'Discotecas': 'assets/default_discotecas.jpg',
    'Cultural': 'assets/eventos/cultural.jpg',
    'Deportivo': 'assets/eventos/deportivo.jpg',
  };

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error al seleccionar imagen: ${e.toString()}');
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      setState(() => _isLoading = true);
      final fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref('event_images/$fileName');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      _showErrorSnackBar('Error al subir la imagen');
      return null;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF6A11CB),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _horaController.text = picked.format(context);
      });
    }
  }

  Future<void> _selectLocation() async {
    final TextEditingController _direccionInputController = TextEditingController();
    String? errorText;

    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Escribir dirección'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _direccionInputController,
                    decoration: InputDecoration(
                      hintText: 'Ej. Calle 123 #45-67, Bogotá',
                      errorText: errorText,
                    ),
                    autofocus: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    final direccion = _direccionInputController.text.trim();
                    if (direccion.isEmpty) {
                      setState(() {
                        errorText = 'Por favor escribe una dirección.';
                      });
                    } else {
                      Navigator.pop(context, direccion);
                    }
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    ).then((result) {
      if (result != null && result.isNotEmpty) {
        setState(() {
          _direccionController.text = result;
          _ubicacionEvento = null;
        });
      }
    });
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mediosSeleccionados.isEmpty) {
      _showErrorSnackBar('Selecciona al menos un medio de pago');
      return;
    }

    if (_mediosSeleccionados.contains('Transferencia bancaria') && 
        _cuentaBancariaController.text.isEmpty) {
      _showErrorSnackBar('Ingresa la cuenta bancaria');
      return;
    }
    if (_mediosSeleccionados.contains('Nequi') && _nequiController.text.isEmpty) {
      _showErrorSnackBar('Ingresa el número de Nequi');
      return;
    }
    if (_mediosSeleccionados.contains('Daviplata') && 
        _daviplataController.text.isEmpty) {
      _showErrorSnackBar('Ingresa el número de Daviplata');
      return;
    }

    // Validación adicional para costo
    if (!_esGratis && (_costoController.text.isEmpty || double.tryParse(_costoController.text) == null)) {
      _showErrorSnackBar('Ingresa un costo válido para el evento');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_fechaController.text.isEmpty) {
        throw 'Por favor selecciona una fecha válida';
      }

      final fechaEvento = DateFormat('yyyy-MM-dd').parse(_fechaController.text);
      
      if (fechaEvento.isBefore(DateTime.now())) {
        throw 'La fecha del evento debe ser futura';
      }

      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
      } else if (_tipoSeleccionado != null) {
        // Asignar imagen predeterminada si no se seleccionó una
        // Nota: En producción necesitarías implementar la carga de assets
        imageUrl = 'default_${_tipoSeleccionado?.toLowerCase()}.jpg';
      }

      Map<String, String> infoPagos = {};
      if (_mediosSeleccionados.contains('Transferencia bancaria')) {
        infoPagos['cuenta_bancaria'] = _cuentaBancariaController.text.trim();
      }
      if (_mediosSeleccionados.contains('Nequi')) {
        infoPagos['nequi'] = _nequiController.text.trim();
      }
      if (_mediosSeleccionados.contains('Daviplata')) {
        infoPagos['daviplata'] = _daviplataController.text.trim();
      }

      final eventData = {
  'eventName': _nombreController.text.trim(),
  'descripcion': _descripcionController.text.trim(),
  'zona': _zonaSeleccionada ?? 'No especificada',
  'fecha': DateFormat('yyyy-MM-dd').format(fechaEvento), // Formato más estándar
  'fechaTimestamp': Timestamp.fromDate(fechaEvento),
  'hora': _horaController.text.trim() ?? 'Hora no especificada',
  'tipo': _tipoSeleccionado ?? 'General',
  'image': imageUrl ?? 'https://via.placeholder.com/400', // URL pública genérica
  'creatorId': widget.user.uid,
  'createdAt': FieldValue.serverTimestamp(),
  'status': 'pending',
  'esGratis': _esGratis,
  'capacidad': _esGratis ? 0 : (int.tryParse(_capacidadController.text) ?? 0),
  'costo': _esGratis ? 0.0 : (double.tryParse(_costoController.text) ?? 0.0),
  'direccion': _direccionController.text.trim() ?? 'Dirección no especificada',
  'ubicacion': _ubicacionEvento != null 
      ? GeoPoint(_ubicacionEvento!.latitude, _ubicacionEvento!.longitude)
      : null,
  'contacto': _contactoController.text.trim(),
  'etiquetas': _etiquetasController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
  'politicas': _politicasController.text.trim(),
  'accesibilidad': _accesibilidad,
  'parqueadero': _parqueadero,
  'mediosPago': _mediosSeleccionados,
  'infoPagos': infoPagos,
  'rating': 0,
  'views': 0,
};
// Antes de guardar, verifica todos los campos requeridos
final requiredFields = {
  'Nombre': _nombreController.text.isEmpty,
  'Descripción': _descripcionController.text.isEmpty,
  'Zona': _zonaSeleccionada == null,
  'Tipo': _tipoSeleccionado == null,
  'Dirección': _direccionController.text.isEmpty,
  'Fecha': _fechaController.text.isEmpty,
  'Contacto': _contactoController.text.isEmpty,
};

final missingField = requiredFields.entries.firstWhere(
  (entry) => entry.value,
  orElse: () => MapEntry('', false),
);

if (missingField.value) {
  _showErrorSnackBar('${missingField.key} es requerido');
  return;
}
      await FirebaseFirestore.instance.collection('eventos').add(eventData);

      _showSuccessSnackBar('Evento enviado para aprobación');
      if (mounted) Navigator.pop(context);
      
    } on FormatException {
      _showErrorSnackBar('Formato de fecha inválido');
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
      debugPrint('Error submitting event: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _capacidadController.dispose();
    _costoController.dispose();
    _direccionController.dispose();
    _horaController.dispose();
    _contactoController.dispose();
    _etiquetasController.dispose();
    _politicasController.dispose();
    _fechaController.dispose();
    _cuentaBancariaController.dispose();
    _nequiController.dispose();
    _daviplataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Crear Evento',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6A11CB),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildImageSection(),
                    SizedBox(height: 25),
                    _buildSection(
                      title: 'Información Básica',
                      child: _buildBasicInfoSection(),
                    ),
                    SizedBox(height: 20),
                    _buildSection(
                      title: 'Detalles del Evento',
                      child: _buildDetailsSection(),
                    ),
                    SizedBox(height: 20),
                    _buildSection(
                      title: 'Características',
                      child: _buildFeaturesSection(),
                    ),
                    SizedBox(height: 20),
                    _buildSection(
                      title: 'Medios de Pago',
                      child: _buildMediosDePagoSection(),
                    ),
                    SizedBox(height: 20),
                    _buildSection(
                      title: 'Información de Pagos',
                      child: _buildPaymentInfoSection(),
                    ),
                    SizedBox(height: 30),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _submitEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'PUBLICAR EVENTO',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.grey[200]!, Colors.grey[300]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_imageFile!, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 50,
                    color: Colors.grey[600],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Agregar imagen principal',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_tipoSeleccionado != null) ...[
                    SizedBox(height: 8),
                    Text(
                      'Tipo seleccionado: $_tipoSeleccionado',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      children: [
        _buildModernTextField(
          controller: _nombreController,
          label: 'Nombre del evento*',
          icon: Icons.event,
        ),
        SizedBox(height: 16),
        _buildModernTextField(
          controller: _descripcionController,
          label: 'Descripción*',
          icon: Icons.description,
          maxLines: 3,
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: _fechaController,
                label: 'Fecha*',
                icon: Icons.calendar_today,
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(DateTime.now().year + 2),
                  );
                  if (picked != null) {
                    _fechaController.text = DateFormat('yyyy-MM-dd').format(picked);
                  }
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildModernTextField(
                controller: _horaController,
                label: 'Hora',
                icon: Icons.access_time,
                readOnly: true,
                onTap: _selectTime,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernTextField({
  required TextEditingController controller,
  required String label,
  IconData? icon,
  bool readOnly = false,
  int maxLines = 1,
  VoidCallback? onTap,
  TextInputType? keyboardType,
  String? Function(String?)? validator, // ✅ nuevo parámetro opcional
}) {
  return TextFormField(
    controller: controller,
    readOnly: readOnly,
    onTap: onTap,
    maxLines: maxLines,
    keyboardType: keyboardType,
    style: GoogleFonts.poppins(),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
      floatingLabelStyle: GoogleFonts.poppins(color: Color(0xFF6A11CB)),
      prefixIcon: icon != null ? Icon(icon, color: Color(0xFF6A11CB)) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Color(0xFF6A11CB), width: 1.5),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    ),
    validator: validator, // ✅ usa el validador externo si se pasa
  );
}


  Widget _buildDetailsSection() {
    return Column(
      children: [
        _buildModernDropdown(
          value: _zonaSeleccionada,
          items: _zonas,
          label: 'Zona de la ciudad*',
          icon: Icons.location_on,
          onChanged: (val) => setState(() => _zonaSeleccionada = val),
        ),
        SizedBox(height: 16),
        _buildModernDropdown(
          value: _tipoSeleccionado,
          items: _tiposEvento,
          label: 'Tipo de evento*',
          icon: Icons.category,
          onChanged: (val) => setState(() => _tipoSeleccionado = val),
        ),
        SizedBox(height: 16),
        _buildModernTextField(
          controller: _direccionController,
          label: 'Dirección exacta*',
          icon: Icons.map,
          readOnly: true,
          onTap: _selectLocation,
        ),
        if (_ubicacionEvento != null) ...[
          SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: FlutterMap(
                options: MapOptions(
                  center: _ubicacionEvento,
                  zoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _ubicacionEvento!,
                        builder: (ctx) => Icon(Icons.location_pin, 
                            color: Colors.red, size: 40),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        SizedBox(height: 16),
        // Nuevo switch para evento gratis
        _buildModernSwitch(
          value: _esGratis,
          onChanged: (val) {
            setState(() {
              _esGratis = val;
              if (val) {
                _costoController.text = '0';
              } else {
                _costoController.text = '';
              }
            });
          },
          label: 'Evento gratuito',
          icon: Icons.money_off,
        ),
        SizedBox(height: 8),
        if (_esGratis)
          Text(
            'Los eventos gratuitos no requieren especificar capacidad exacta',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AbsorbPointer(
                absorbing: _esGratis,
                child: Opacity(
                  opacity: _esGratis ? 0.5 : 1.0,
                  child: _buildModernTextField(
                    controller: _capacidadController,
                    label: 'Capacidad*',
                    icon: Icons.people,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: AbsorbPointer(
                absorbing: _esGratis,
                child: Opacity(
                  opacity: _esGratis ? 0.5 : 1.0,
                  child: _buildModernTextField(
                    controller: _costoController,
                    label: 'Costo entrada*',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
        floatingLabelStyle: GoogleFonts.poppins(color: Color(0xFF6A11CB)),
        prefixIcon: Icon(icon, color: Color(0xFF6A11CB)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF6A11CB), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          isExpanded: true,
          style: GoogleFonts.poppins(color: Colors.black87),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
          hint: Text('Selecciona', style: GoogleFonts.poppins()),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      children: [
        _buildModernSwitch(
          value: _accesibilidad,
          onChanged: (val) => setState(() => _accesibilidad = val),
          label: 'Accesibilidad para personas con discapacidad',
          icon: Icons.accessible,
        ),
        SizedBox(height: 12),
        _buildModernSwitch(
          value: _parqueadero,
          onChanged: (val) => setState(() => _parqueadero = val),
          label: 'Disponibilidad de parqueadero',
          icon: Icons.local_parking,
        ),
        SizedBox(height: 16),
        _buildModernTextField(
          controller: _contactoController,
          label: 'Contacto (teléfono/email)*',
          icon: Icons.contact_phone,
        ),
        SizedBox(height: 16),
        _buildModernTextField(
          controller: _etiquetasController,
          label: 'Etiquetas (separadas por coma)',
          icon: Icons.tag,
        ),
        SizedBox(height: 16),
        _buildModernTextField(
          controller: _politicasController,
          label: 'Políticas del evento',
          icon: Icons.policy,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildModernSwitch({
    required bool value,
    required Function(bool) onChanged,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF6A11CB)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFF6A11CB),
            activeTrackColor: Color(0xFF6A11CB).withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildMediosDePagoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona los medios de pago aceptados:',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _mediosDePagoDisponibles.map((medio) {
            final isSelected = _mediosSeleccionados.contains(medio);
            return ChoiceChip(
              label: Text(medio),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _mediosSeleccionados.add(medio);
                  } else {
                    _mediosSeleccionados.remove(medio);
                  }
                });
              },
              labelStyle: GoogleFonts.poppins(
                color: isSelected ? Colors.white : Colors.black87,
              ),
              selectedColor: Color(0xFF6A11CB),
              backgroundColor: Colors.grey[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        ),
        if (_mediosSeleccionados.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Selecciona al menos un medio de pago',
              style: GoogleFonts.poppins(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentInfoSection() {
    return Column(
      children: [
        if (_mediosSeleccionados.contains('Transferencia bancaria'))
          _buildModernTextField(
            controller: _cuentaBancariaController,
            label: 'Número de cuenta bancaria*',
            icon: Icons.account_balance,
            keyboardType: TextInputType.number,
          ),
        if (_mediosSeleccionados.contains('Nequi'))
          _buildModernTextField(
            controller: _nequiController,
            label: 'Número de Nequi*',
            icon: Icons.phone_android,
            keyboardType: TextInputType.phone,
          ),
        if (_mediosSeleccionados.contains('Daviplata'))
          _buildModernTextField(
            controller: _daviplataController,
            label: 'Número de Daviplata*',
            icon: Icons.phone_android,
            keyboardType: TextInputType.phone,
          ),
      ],
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}