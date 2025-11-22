import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/database_service.dart';
import 'package:flutter_application_1/models/servicios.dart';

class DatabaseInitializer {
  static final DatabaseService _databaseService = DatabaseService();

  static Future<void> inicializarServicios() async {
    // Lista de servicios predefinidos para la barbería masculina
    List<Servicio> serviciosIniciales = [
      Servicio(
        id: '',
        nombre: 'Corte Clásico',
        descripcion:
            'Corte de cabello tradicional con tijeras y máquina. Estilo atemporal y elegante.',
        precio: 150.0, // Q150
        duracionMinutos: 30,
      ),
      Servicio(
        id: '',
        nombre: 'Corte + Barba',
        descripcion:
            'Corte de cabello completo más arreglo de barba con delineado perfecto.',
        precio: 250.0, // Q250
        duracionMinutos: 45,
      ),
      Servicio(
        id: '',
        nombre: 'Afeitado Clásico',
        descripcion:
            'Afeitado tradicional con navaja y toallas calientes. Experiencia relajante.',
        precio: 180.0, // Q180
        duracionMinutos: 30,
      ),
      Servicio(
        id: '',
        nombre: 'Corte de Niños',
        descripcion:
            'Corte especial para niños menores de 12 años. Ambiente divertido y seguro.',
        precio: 60.0, // Q60
        duracionMinutos: 25,
      ),
      Servicio(
        id: '',
        nombre: 'Fade Moderno',
        descripcion:
            'Degradado profesional (high, mid, low fade). Cortes actuales y precisos.',
        precio: 220.0, // Q220
        duracionMinutos: 40,
      ),
      Servicio(
        id: '',
        nombre: 'Undercut Premium',
        descripcion:
            'Corte undercut con diseños y acabados profesionales. Estilo urbano.',
        precio: 280.0, // Q280
        duracionMinutos: 45,
      ),
      Servicio(
        id: '',
        nombre: 'Barba Completa',
        descripcion:
            'Arreglo completo de barba: recorte, delineado, aceites y bálsamos.',
        precio: 200.0, // Q200
        duracionMinutos: 35,
      ),
      Servicio(
        id: '',
        nombre: 'Bigote + Perilla',
        descripcion:
            'Diseño y mantenimiento de bigote y perilla con técnicas especializadas.',
        precio: 120.0, // Q120
        duracionMinutos: 20,
      ),
      Servicio(
        id: '',
        nombre: 'Lavado + Masaje Capilar',
        descripcion:
            'Lavado profundo con masaje relajante del cuero cabelludo.',
        precio: 140.0, // Q140
        duracionMinutos: 25,
      ),
      Servicio(
        id: '',
        nombre: 'Corte Ejecutivo',
        descripcion:
            'Corte profesional para hombres de negocios. Elegante y sofisticado.',
        precio: 300.0, // Q300
        duracionMinutos: 40,
      ),
      Servicio(
        id: '',
        nombre: 'Rapado Completo',
        descripcion:
            'Rapado profesional con máquina. Acabado perfecto y uniforme.',
        precio: 100.0, // Q100
        duracionMinutos: 20,
      ),
      Servicio(
        id: '',
        nombre: 'Diseños en Cabello',
        descripcion:
            'Diseños creativos y líneas artísticas en cabello con máquina de precisión.',
        precio: 180.0, // Q180
        duracionMinutos: 30,
      ),
      Servicio(
        id: '',
        nombre: 'Cejas Masculinas',
        descripcion:
            'Arreglo y diseño de cejas para hombres. Natural y masculino.',
        precio: 80.0, // Q80
        duracionMinutos: 15,
      ),
      Servicio(
        id: '',
        nombre: 'Tratamiento Anti-Caspa',
        descripcion:
            'Tratamiento especializado para eliminar caspa y cuidar el cuero cabelludo.',
        precio: 250.0, // Q250
        duracionMinutos: 30,
      ),
      Servicio(
        id: '',
        nombre: 'Paquete Completo',
        descripcion:
            'Corte + barba + lavado + styling + tratamiento. La experiencia total.',
        precio: 500.0, // Q500
        duracionMinutos: 90,
      ),
      Servicio(
        id: '',
        nombre: 'Corte + Styling Premium',
        descripcion:
            'Corte personalizado con peinado y productos de fijación de lujo.',
        precio: 350.0, // Q350
        duracionMinutos: 50,
      ),
      Servicio(
        id: '',
        nombre: 'Afeitado + Hidratación',
        descripcion:
            'Afeitado clásico seguido de tratamiento hidratante facial masculino.',
        precio: 260.0, // Q260
        duracionMinutos: 40,
      ),
      Servicio(
        id: '',
        nombre: 'Corte Militar',
        descripcion: 'Corte estilo militar con precisión y acabado impecable.',
        precio: 130.0, // Q130
        duracionMinutos: 25,
      ),
      Servicio(
        id: '',
        nombre: 'Pompadour Clásico',
        descripcion:
            'Corte estilo pompadour vintage con técnicas tradicionales.',
        precio: 320.0, // Q320
        duracionMinutos: 55,
      ),
      Servicio(
        id: '',
        nombre: 'Mantenimiento Semanal',
        descripcion:
            'Retoque de corte y barba para mantener el estilo perfecto.',
        precio: 80.0, // Q80
        duracionMinutos: 20,
      ),
    ];

    // Agregar cada servicio SOLO si no existe ya
    for (Servicio servicio in serviciosIniciales) {
      try {
        // Verificar si el servicio ya existe
        bool existe = await _existeServicio(servicio.nombre);
        if (!existe) {
          await _databaseService.crearServicio(servicio);
          print('✅ Servicio agregado: ${servicio.nombre}');
        } else {
          print('⚠️  Servicio ya existe, omitiendo: ${servicio.nombre}');
        }
      } catch (e) {
        print('❌ Error al agregar servicio ${servicio.nombre}: $e');
      }
    }
  }

  // Método para actualizar precios de servicios existentes
  static Future<void> actualizarPreciosServicios() async {
    // Mapeo de nombres de servicios con sus precios correctos
    Map<String, double> preciosCorrectos = {
      'Corte Clásico': 150.0,
      'Corte + Barba': 250.0,
      'Afeitado Clásico': 180.0,
      'Corte de Niños': 60.0,
      'Corte Moderno': 220.0,
      'Lavado + Peinado': 120.0,
      'Corte + Lavado + Barba': 400.0,
      'Cejas': 80.0,
      'Tratamiento Capilar': 600.0,
      'Corte + Styling': 350.0,
      'Servicio Completo': 400.0,
      'Barba Deluxe': 250.0,
    };

    try {
      // Obtener todos los servicios actuales
      List<Servicio> servicios = await _databaseService
          .obtenerServicios()
          .first;

      for (Servicio servicio in servicios) {
        // Si el servicio tiene un precio incorrecto, actualizarlo
        if (preciosCorrectos.containsKey(servicio.nombre)) {
          double precioCorrectoValue = preciosCorrectos[servicio.nombre]!;

          if (servicio.precio != precioCorrectoValue) {
            // Crear servicio actualizado
            Servicio servicioActualizado = Servicio(
              id: servicio.id,
              nombre: servicio.nombre,
              descripcion: servicio.descripcion,
              precio: precioCorrectoValue,
              duracionMinutos: servicio.duracionMinutos,
            );

            // Actualizar en la base de datos
            await _databaseService.actualizarServicio(servicioActualizado);
            print(
              'Precio actualizado para ${servicio.nombre}: Q${precioCorrectoValue}',
            );
          }
        }
      }
      print('Actualización de precios completada.');
    } catch (e) {
      print('Error al actualizar precios: $e');
    }
  }

  // Método para verificar si ya existen servicios
  static Future<bool> tieneServicios() async {
    try {
      // Obtener la primera emisión del stream
      List<Servicio> servicios = await _databaseService
          .obtenerServicios()
          .first;
      return servicios.isNotEmpty;
    } catch (e) {
      print('Error al verificar servicios: $e');
      return false;
    }
  }

  // Método para verificar si un servicio específico ya existe
  static Future<bool> _existeServicio(String nombreServicio) async {
    try {
      List<Servicio> servicios = await _databaseService
          .obtenerServicios()
          .first;
      return servicios.any(
        (s) => s.nombre.toLowerCase() == nombreServicio.toLowerCase(),
      );
    } catch (e) {
      print('Error al verificar servicio $nombreServicio: $e');
      return false;
    }
  }

  // Método para limpiar automáticamente servicios duplicados
  static Future<void> limpiarDuplicadosAutomatico() async {
    try {
      print('🔍 Verificando servicios duplicados...');

      final snapshot = await FirebaseFirestore.instance
          .collection('servicios')
          .get();
      final servicios = snapshot.docs;

      // Agrupar por nombre
      Map<String, List<QueryDocumentSnapshot>> serviciosPorNombre = {};

      for (var doc in servicios) {
        final data = doc.data();
        final nombre = data['nombre'] ?? 'Sin nombre';

        if (!serviciosPorNombre.containsKey(nombre)) {
          serviciosPorNombre[nombre] = [];
        }
        serviciosPorNombre[nombre]!.add(doc);
      }

      int eliminados = 0;

      for (String nombre in serviciosPorNombre.keys) {
        final documentos = serviciosPorNombre[nombre]!;

        if (documentos.length > 1) {
          print(
            '🧹 Limpiando duplicados de: "$nombre" (${documentos.length} copias)',
          );

          // Mantener el primero, eliminar el resto
          for (int i = 1; i < documentos.length; i++) {
            await documentos[i].reference.delete();
            eliminados++;
          }
        }
      }

      if (eliminados > 0) {
        print(
          '✅ Limpieza automática completada: $eliminados duplicados eliminados',
        );
      } else {
        print('✅ No se encontraron servicios duplicados');
      }
    } catch (e) {
      print('❌ Error en limpieza automática: $e');
    }
  }

  // Método principal para inicializar la base de datos
  static Future<void> inicializarBaseDatos() async {
    try {
      print('🚀 Verificando servicios en la base de datos...');

      // PRIMERO: Limpiar duplicados automáticamente
      await limpiarDuplicadosAutomatico();

      bool yaExistenServicios = await tieneServicios();

      if (!yaExistenServicios) {
        print('📝 No se encontraron servicios. Inicializando...');
        await inicializarServicios();
        print('✅ Base de datos inicializada con servicios predefinidos.');
      } else {
        print('✅ La base de datos ya contiene servicios.');
        // Actualizar precios si hay discrepancias
        await actualizarPreciosServicios();
      }

      // FINAL: Verificar que no quedaron duplicados
      await limpiarDuplicadosAutomatico();
    } catch (e) {
      print('❌ Error al inicializar la base de datos: $e');
    }
  }
}
