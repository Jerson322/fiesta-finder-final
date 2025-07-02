import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

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
  static const Map<String, String> _defaultImages = {
    'Gastrobar': 'assets/eventos/gastrobar.jpg',
    'Discotecas': 'assets/default_discotecas.jpg',
    'Cultural': 'assets/eventos/cultural.jpg',
    'Deportivo': 'assets/eventos/deportivo.jpg',
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
  // 1. Si es una URL válida
  if (event['image'] != null && event['image'].toString().startsWith('http')) {
    return event['image'];
  }
  
  // 2. Si es un asset local (ej: "assets/...")
  if (event['image'] != null && event['image'].toString().startsWith('assets/')) {
    return event['image'];
  }
  
  // 3. Imagen predeterminada por tipo de evento
  final tipoEvento = _getField('tipo');
  return _defaultImages[tipoEvento] ?? 'assets/default_discotecas.jpg';
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
    debugPrint('\nConstruyendo tarjeta para evento: ${event['id'] ?? 'sin ID'}');
    debugPrint('Datos completos: $event');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Stack(
        children: [
          // Gestor de toques para toda la tarjeta (EXCLUYENDO el botón de favoritos)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showEventDetails(context),
                excludeFromSemantics: true,
              ),
            ),
          ),
          
          // Contenido principal
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Imagen del evento
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: _getImageUrl(),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) {
                      debugPrint('Error cargando imagen: $error');
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 40),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Información del evento
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getField('eventName', 'Evento sin nombre'),
                        style: const TextStyle(
                          fontSize: 18,
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
          ),
          
          // Botón de favoritos - CON prioridad de gestos
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.lightImpact();
                onToggleFavorite(event);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey[600],
                  size: 24,
                ),
              ),
            ),
          ),
        ],
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