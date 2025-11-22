class Servicio {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int duracionMinutos;

  Servicio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.duracionMinutos,
  });

  // Convertir de Map (Firestore) a Servicio
  factory Servicio.fromMap(Map<String, dynamic> map, String id) {
    return Servicio(
      id: id,
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      precio: (map['precio'] ?? 0.0).toDouble(),
      duracionMinutos: map['duracionMinutos'] ?? 30,
    );
  }

  // Convertir de Servicio a Map (para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'duracionMinutos': duracionMinutos,
    };
  }

  String get duracionTexto {
    if (duracionMinutos < 60) {
      return '$duracionMinutos min';
    } else {
      final horas = duracionMinutos ~/ 60;
      final minutos = duracionMinutos % 60;
      if (minutos == 0) {
        return '$horas h';
      } else {
        return '$horas h $minutos min';
      }
    }
  }

  String get precioTexto => 'Q${precio.toStringAsFixed(0)}';
}
