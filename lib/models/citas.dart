import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoCita { pendiente, confirmada, completada, cancelada }

class Cita {
  final String id;
  final String usuarioId;
  final String servicio;
  final List<String> servicios;
  final double precio;
  final DateTime fecha;
  final String hora;
  final EstadoCita estado;
  final String notas;
  final DateTime fechaCreacion;
  final String nombreCliente;
  final String telefonoCliente;
  final String emailCliente;

  Cita({
    required this.id,
    required this.usuarioId,
    required this.servicio,
    this.servicios = const [],
    this.precio = 0.0,
    required this.fecha,
    required this.hora,
    required this.estado,
    this.notas = '',
    required this.fechaCreacion,
    required this.nombreCliente,
    required this.telefonoCliente,
    required this.emailCliente,
  });

  factory Cita.fromMap(Map<String, dynamic> map, String id) {
    final servicioMain = map['servicio'] ?? '';
    return Cita(
      id: id,
      usuarioId:
          map['usuarioId'] ??
          map['userId'] ??
          '', // Para compatibilidad con datos existentes
      servicio: servicioMain,
      servicios: servicioMain.isNotEmpty
          ? [servicioMain]
          : [], // Solo un servicio, no duplicar
      precio: (map['precio'] ?? 0.0).toDouble(),
      fecha: map['fecha']?.toDate() ?? DateTime.now(),
      hora: map['hora'] ?? '',
      estado: EstadoCita.values[map['estado'] ?? 0],
      notas: map['notas'] ?? '',
      fechaCreacion: map['fechaCreacion']?.toDate() ?? DateTime.now(),
      nombreCliente: map['nombreCliente'] ?? '',
      telefonoCliente: map['telefonoCliente'] ?? '',
      emailCliente: map['emailCliente'] ?? '',
    );
  }

  factory Cita.fromFirestore(dynamic doc) {
    return Cita.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'usuarioId': usuarioId,
      'servicio': servicio,
      'servicios': [servicio], // Solo el servicio principal, sin duplicados
      'precio': precio,
      'fecha': fecha,
      'hora': hora,
      'estado': estado.index,
      'notas': notas,
      'fechaCreacion': fechaCreacion,
      'nombreCliente': nombreCliente,
      'telefonoCliente': telefonoCliente,
      'emailCliente': emailCliente,
    };
  }

  Cita copyWith({
    String? id,
    String? usuarioId,
    String? servicio,
    List<String>? servicios,
    double? precio,
    DateTime? fecha,
    String? hora,
    EstadoCita? estado,
    String? notas,
    DateTime? fechaCreacion,
    String? nombreCliente,
    String? telefonoCliente,
    String? emailCliente,
  }) {
    return Cita(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      servicio: servicio ?? this.servicio,
      servicios: servicios ?? this.servicios,
      precio: precio ?? this.precio,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      estado: estado ?? this.estado,
      notas: notas ?? this.notas,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      telefonoCliente: telefonoCliente ?? this.telefonoCliente,
      emailCliente: emailCliente ?? this.emailCliente,
    );
  }

  // Getter para calcular precio automáticamente si es 0.0
  double get precioCalculado {
    if (precio > 0.0) return precio;
    return 0.0; // Será calculado dinámicamente
  }

  // Método para obtener precio del servicio desde la base de datos
  static Future<double> obtenerPrecioServicio(String nombreServicio) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('servicios')
          .where('nombre', isEqualTo: nombreServicio)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final servicioData = querySnapshot.docs.first.data();
        return (servicioData['precio'] ?? 0.0).toDouble();
      }

      // Si no encuentra el servicio, devolver precio por defecto
      return _getPrecioDefault(nombreServicio);
    } catch (e) {
      print('Error al obtener precio del servicio: $e');
      return _getPrecioDefault(nombreServicio);
    }
  }

  // Precios por defecto como fallback
  static double _getPrecioDefault(String nombreServicio) {
    switch (nombreServicio) {
      case 'Corte Clásico':
        return 150.0;
      case 'Corte + Barba':
        return 250.0;
      case 'Afeitado Tradicional':
        return 120.0;
      case 'Lavado + Peinado':
        return 100.0;
      case 'Corte + Lavado':
        return 180.0;
      case 'Arreglo de Barba':
        return 80.0;
      case 'Corte Moderno':
        return 170.0;
      case 'Masaje Capilar':
        return 90.0;
      case 'Tratamiento Anticaspa':
        return 200.0;
      case 'Paquete Completo':
        return 350.0;
      default:
        return 150.0;
    }
  }

  String get estadoTexto {
    switch (estado) {
      case EstadoCita.pendiente:
        return 'Pendiente';
      case EstadoCita.confirmada:
        return 'Confirmada';
      case EstadoCita.completada:
        return 'Completada';
      case EstadoCita.cancelada:
        return 'Cancelada';
    }
  }
}
