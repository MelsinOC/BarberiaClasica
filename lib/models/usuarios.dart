class Usuario {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final DateTime fechaRegistro;

  Usuario({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.fechaRegistro,
  });

  // Convertir de Map (Firestore) a Usuario
  factory Usuario.fromMap(Map<String, dynamic> map, String id) {
    return Usuario(
      id: id,
      nombre: map['nombre'] ?? '',
      apellido: map['apellido'] ?? '',
      email: map['email'] ?? '',
      telefono: map['telefono'] ?? '',
      fechaRegistro: map['fechaRegistro']?.toDate() ?? DateTime.now(),
    );
  }

  // Convertir de Usuario a Map (para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'fechaRegistro': fechaRegistro,
    };
  }

  String get nombreCompleto => '$nombre $apellido';
}
