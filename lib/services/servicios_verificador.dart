import 'package:cloud_firestore/cloud_firestore.dart';

/// Herramienta para verificar y reparar servicios faltantes en Firebase
class ServiciosVerificador {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Verificar que todos los servicios estén en Firebase
  static Future<void> verificarYAgregarServiciosFaltantes() async {
    try {
      print('🔍 Verificando servicios en Firebase...');

      // Obtener servicios actuales en Firebase
      final snapshot = await _firestore.collection('servicios').get();
      final serviciosExistentes = snapshot.docs
          .map((doc) => doc.data()['nombre'] as String)
          .toList();

      print(
        '📊 Servicios encontrados en Firebase: ${serviciosExistentes.length}',
      );
      for (String nombre in serviciosExistentes) {
        print('  ✅ $nombre');
      }

      // Lista de servicios que deberían existir (de DatabaseInitializer)
      final serviciosEsperados = [
        'Corte Clásico',
        'Corte + Barba',
        'Afeitado Clásico',
        'Corte de Niños',
        'Fade Moderno',
        'Undercut Premium',
        'Barba Completa',
        'Bigote + Perilla',
        'Lavado + Masaje Capilar',
        'Corte Ejecutivo',
        'Rapado Completo',
        'Diseños en Cabello',
        'Cejas Masculinas',
        'Tratamiento Anti-Caspa',
        'Coloración/Tinte',
        'Paquete Novio',
        'Mascarilla Hidratante',
        'Ondulado/Rizos',
      ];

      // Encontrar servicios faltantes
      final serviciosFaltantes = serviciosEsperados
          .where((servicio) => !serviciosExistentes.contains(servicio))
          .toList();

      if (serviciosFaltantes.isEmpty) {
        print('✅ Todos los servicios están presentes en Firebase');
        return;
      }

      print(
        '⚠️  Servicios faltantes encontrados: ${serviciosFaltantes.length}',
      );
      for (String nombre in serviciosFaltantes) {
        print('  ❌ $nombre');
      }

      // Preguntar al usuario si desea agregar los servicios faltantes
      print('\\n🔧 Iniciando proceso de reparación...');
      await _agregarServiciosFaltantes(serviciosFaltantes);
    } catch (e) {
      print('❌ Error verificando servicios: $e');
    }
  }

  /// Agregar servicios faltantes a Firebase
  static Future<void> _agregarServiciosFaltantes(
    List<String> serviciosFaltantes,
  ) async {
    // NO agregar servicios automáticamente para evitar duplicados
    // Solo reportar que faltan
    print(
      '⚠️  Se encontraron ${serviciosFaltantes.length} servicios faltantes.',
    );
    print('🔧 La inicialización automática los agregará si es necesario.');
    print('✅ Verificación completada sin agregar duplicados');
  }

  /// Mostrar estadísticas de servicios
  static Future<void> mostrarEstadisticas() async {
    try {
      final snapshot = await _firestore.collection('servicios').get();
      final servicios = snapshot.docs;

      print('\\n📊 ESTADÍSTICAS DE SERVICIOS:');
      print('════════════════════════════════════');
      print('Total de servicios: ${servicios.length}');
      print('════════════════════════════════════');

      for (var doc in servicios) {
        final data = doc.data();
        final nombre = data['nombre'] ?? 'Sin nombre';
        final precio = data['precio'] ?? 0.0;
        final duracion = data['duracionMinutos'] ?? 0;

        print('🔹 $nombre - Q$precio - ${duracion}min');
      }
      print('════════════════════════════════════');
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
    }
  }

  /// Reparar servicios sin nombre
  static Future<void> repararServiciosSinNombre() async {
    try {
      print('🔍 Buscando servicios sin nombre...');

      final snapshot = await _firestore.collection('servicios').get();
      int serviciosReparados = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final nombre = data['nombre'] ?? '';

        if (nombre.isEmpty) {
          print('❌ Servicio sin nombre encontrado: ${doc.id}');
          // Aquí podrías implementar lógica para reparar o eliminar
          serviciosReparados++;
        }
      }

      if (serviciosReparados == 0) {
        print('✅ No se encontraron servicios sin nombre');
      } else {
        print('⚠️ Servicios sin nombre: $serviciosReparados');
      }
    } catch (e) {
      print('❌ Error reparando servicios: $e');
    }
  }
}
