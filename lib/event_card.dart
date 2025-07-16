import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:math';


class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isFavorite;
  final Function(Map<String, dynamic>) onToggleFavorite;

  const EventCard({
    super.key,
    required this.event,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  // Mapa de imágenes predeterminadas por tipo de evento
  static const Map<String, List<String>> _defaultImages = {
  'Gastrobar': [
    'assets/gastrobar_1.jpg',
    'assets/gastrobar_2.jpg',
    'assets/gastrobar_3.jpg',
  ],
  'Discotecas': [
    'assets/discoteca_1.jpg',
    'assets/discoteca_2.jpg',
    'assets/discoteca_3.jpg',
  ],
  'Cultural': [
    'assets/cultural_1.jpg',
    'assets/cultural_2.jpg',
    'assets/cultural_3.jpg',
  ],
  'Deportivo': [
    'assets/deportivo_1.jpg',
    'assets/deportivo_2.jpg',
    'assets/deportivo_3.jpg',
  ],
};

  // 1. Actualiza el método _getField
String _getField(String key, [String defaultValue = 'No especificado']) {
  // Mapeo actualizado con los nombres EXACTOS de Firestore
  final fieldMap = {
    'name': 'eventName',       // Para compatibilidad con código que use 'name'
    'eventName': 'eventName',  // Nombre real en Firestore
    'localidad': 'zona',       // 'localidad' en código -> 'zona' en Firestore
    'zona': 'zona',            // Acceso directo
    'direccion': 'direccion',
    'hora': 'hora',
    'tipo': 'tipo',
    'descripcion': 'descripcion',
    'contacto': 'contacto',
  };
  
  final actualKey = fieldMap[key] ?? key;
  
  if (!event.containsKey(actualKey)) return defaultValue;
  
  final value = event[actualKey];
  if (value == null || (value is String && value.trim().isEmpty)) {
    return defaultValue;
  }
  
  return value.toString();
}

// 2. Asegura que _getImageUrl() maneje imágenes correctamente
String _getImageUrl() {
  final image = event['image'];

  // 1. Si es una URL válida
  if (image != null && image.toString().startsWith('http')) {
    return image;
  }

  // 2. Si es un asset local (ej: "assets/...")
  if (image != null && image.toString().startsWith('assets/')) {
    return image;
  }

  // 3. Imagen aleatoria predeterminada por tipo de evento
  final tipoEvento = _getField('tipo');
  final defaultList = _defaultImages[tipoEvento];

  if (defaultList != null && defaultList.isNotEmpty) {
    final random = Random();
    return defaultList[random.nextInt(defaultList.length)];
  }

  // 4. Fallback general
  return 'assets/default_discotecas.jpg';
}


  String _getFormattedDate() {
    try {
      // Intenta primero con fechaTimestamp si existe
      if (event['fechaTimestamp'] != null) {
        final date = (event['fechaTimestamp'] as Timestamp).toDate();
        return DateFormat('EEE d MMM y', 'es_ES').format(date);
      }
      
      // Luego intenta con el campo fecha
      final fecha = _getField('fecha');
      if (fecha == 'No especificado') return fecha;
      
      // Intenta parsear diferentes formatos
      try {
        return DateFormat('EEE d MMM y', 'es_ES').format(DateFormat('dd/MM/yyyy').parse(fecha));
      } catch (e) {
        try {
          return DateFormat('EEE d MMM y', 'es_ES').format(DateFormat('yyyy-MM-dd').parse(fecha));
        } catch (e) {
          return fecha; // Devuelve el formato original si no se puede parsear
        }
      }
    } catch (e) {
      debugPrint('Error formateando fecha: $e');
      return 'Fecha no especificada';
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    if (text == 'No especificado') return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _getPrice() {
    if (_getField('esGratis') == 'true') return 'GRATIS';

    final costo = event['costo'];
    if (costo == null) return 'Consultar precio';

    try {
      final costoNum = costo is num ? costo.toDouble() : double.parse(costo.toString());
      return costoNum <= 0 ? 'GRATIS' : '\$${costoNum.toStringAsFixed(0)}';
    } catch (e) {
      debugPrint('Error parseando costo: $e');
      return 'Consultar precio';
    }
  }

  String _getCapacity() {
    if (_getField('esGratis') == 'true') return 'Entrada libre';

    final capacidad = event['capacidad'];
    if (capacidad == null) return 'Capacidad limitada';

    final capacidadNum = capacidad is num ? capacidad.toInt() : int.tryParse(capacidad.toString());
    return capacidadNum == null || capacidadNum <= 0 
      ? 'Capacidad limitada' 
      : '$capacidadNum personas';
  }

  @override
Widget build(BuildContext context) {
  return Card(
    margin: const EdgeInsets.all(8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: InkWell( // <-- Añade InkWell aquí
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showEventDetails(context), // <-- Llama al método aquí
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagen del evento (parte superior)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: _getImageUrl(),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 40),
                    ),
                  ),
                ),
              ),
              // Contenido textual (parte inferior)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getField('eventName', 'Evento sin nombre'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.location_on, _getField('zona')),
                    _buildInfoRow(Icons.calendar_today, _getFormattedDate()),
                    _buildInfoRow(Icons.access_time, _getField('hora')),
                    const SizedBox(height: 4),
                    Text(
                      _getPrice(),
                      style: TextStyle(
                        color: _getPrice() == 'GRATIS' ? Colors.green : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Botón de favoritos
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque, // <-- Importante para evitar conflictos
              onTap: () {
                HapticFeedback.lightImpact();
                onToggleFavorite(event);
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey[600],
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
  void _showEventDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;
        
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              minWidth: 280.0,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getField('eventName', 'Evento sin nombre'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Imagen del evento
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                      ),
                      child: _buildDialogImage(),
                    ),
                    const SizedBox(height: 20),
                    // Detalles del evento
                    _buildDetailRow('Tipo:', _getField('tipo')),
                    _buildDetailRow('Zona:', _getField('zona')),
                    _buildDetailRow('Dirección:', _getField('direccion')),
                    _buildDetailRow('Fecha:', _getFormattedDate()),
                    _buildDetailRow('Hora:', _getField('hora')),
                    _buildDetailRow('Precio:', _getPrice()),
                    _buildDetailRow('Capacidad:', _getCapacity()),
                    const SizedBox(height: 16),
                    const Text(
                      'Descripción:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_getField('descripcion', 'Sin descripción')),
                    if (_getField('politicas') != 'No especificado') ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Políticas:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(_getField('politicas')),
                    ],
                    if (_getField('contacto') != 'No especificado') ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Contacto:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(_getField('contacto')),
                    ],
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogImage() {
    final imageUrl = _getImageUrl();
    if (imageUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.image, size: 50),
        ),
      );
    } else {
      return const Icon(Icons.event, size: 50, color: Colors.grey);
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}