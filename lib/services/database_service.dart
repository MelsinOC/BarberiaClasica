import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/citas.dart';
import 'package:flutter_application_1/models/servicios.dart';
import 'package:flutter_application_1/models/usuarios.dart';
import 'fcm_service.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== SERVICIOS ====================

  // Obtener todos los servicios
  Stream<List<Servicio>> obtenerServicios() {
    return _firestore.collection('servicios').orderBy('nombre').snapshots().map(
      (snapshot) {
        return snapshot.docs
            .map((doc) => Servicio.fromMap(doc.data(), doc.id))
            .toList();
      },
    );
  }

  // Obtener servicio por ID
  Future<Servicio?> obtenerServicioPorId(String servicioId) async {
    try {
      final doc = await _firestore
          .collection('servicios')
          .doc(servicioId)
          .get();

      if (doc.exists) {
        return Servicio.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error obteniendo servicio por ID: $e');
      return null;
    }
  }

  // Crear nuevo servicio
  Future<String?> crearServicio(Servicio servicio) async {
    try {
      await _firestore.collection('servicios').add(servicio.toMap());
      return null; // Éxito
    } catch (e) {
      return 'Error al crear servicio: $e';
    }
  }

  // Actualizar servicio existente
  Future<String?> actualizarServicio(Servicio servicio) async {
    try {
      await _firestore
          .collection('servicios')
          .doc(servicio.id)
          .update(servicio.toMap());
      return null; // Éxito
    } catch (e) {
      return 'Error al actualizar servicio: $e';
    }
  }

  // ==================== CITAS ====================

  // Crear nueva cita
  Future<String?> crearCita(Cita cita) async {
    try {
      await _firestore.collection('citas').add(cita.toMap());
      print('📅 Nueva cita creada exitosamente');

      // Enviar notificación push al administrador
      await FCMService.enviarNotificacionAdmin(
        'Nueva cita programada',
        '${cita.nombreCliente} ha programado una cita para ${cita.servicio} el ${_formatearFecha(cita.fecha)} a las ${cita.hora}',
        {
          'tipo': 'nueva_cita',
          'citaId': cita.id,
          'clienteId': cita.usuarioId,
          'servicio': cita.servicio,
          'fecha': cita.fecha.toIso8601String(),
          'hora': cita.hora,
        },
      );

      return null; // Éxito
    } catch (e) {
      return 'Error al crear cita: $e';
    }
  }

  // Obtener todas las citas (para administradores)
  Stream<List<Cita>> obtenerTodasLasCitas() {
    return _firestore
        .collection('citas')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            try {
              return Cita.fromMap(doc.data(), doc.id);
            } catch (e) {
              print('Error procesando cita ${doc.id}: $e');
              // Retornar cita por defecto para evitar errores
              return Cita(
                id: doc.id,
                usuarioId: '',
                servicio: 'Error',
                fecha: DateTime.now(),
                hora: '00:00',
                estado: EstadoCita.cancelada,
                notas: 'Error en datos',
                fechaCreacion: DateTime.now(),
                nombreCliente: 'Error',
                telefonoCliente: '',
                emailCliente: '',
              );
            }
          }).toList();
        });
  }

  // Obtener citas por usuario
  Stream<List<Cita>> obtenerCitasPorUsuario(String usuarioId) {
    return _firestore
        .collection('citas')
        .where('usuarioId', isEqualTo: usuarioId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            try {
              return Cita.fromMap(doc.data(), doc.id);
            } catch (e) {
              print('Error procesando cita del usuario: $e');
              return Cita(
                id: doc.id,
                usuarioId: usuarioId,
                servicio: 'Error',
                fecha: DateTime.now(),
                hora: '00:00',
                estado: EstadoCita.cancelada,
                notas: 'Error en datos',
                fechaCreacion: DateTime.now(),
                nombreCliente: 'Error',
                telefonoCliente: '',
                emailCliente: '',
              );
            }
          }).toList();
        });
  }

  // Obtener cita por ID
  Future<Cita?> obtenerCitaPorId(String citaId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('citas')
          .doc(citaId)
          .get();

      if (doc.exists) {
        return Cita.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error obteniendo cita por ID: $e');
      return null;
    }
  }

  // Actualizar cita
  Future<String?> actualizarCita(Cita cita) async {
    try {
      await _firestore.collection('citas').doc(cita.id).update(cita.toMap());
      return null; // Éxito
    } catch (e) {
      return 'Error al actualizar cita: $e';
    }
  }

  // Actualizar estado de cita
  Future<String?> actualizarEstadoCita(String citaId, EstadoCita estado) async {
    try {
      await _firestore.collection('citas').doc(citaId).update({
        'estado': estado.toString().split('.').last,
      });
      return null; // Éxito
    } catch (e) {
      return 'Error al actualizar estado: $e';
    }
  }

  // Cancelar cita
  Future<String?> cancelarCita(String citaId) async {
    try {
      final resultado = await actualizarEstadoCita(
        citaId,
        EstadoCita.cancelada,
      );
      if (resultado == null) {
        // Obtener datos de la cita para la notificación
        final cita = await obtenerCitaPorId(citaId);
        if (cita != null) {
          // Enviar notificación push al cliente
          await FCMService.enviarNotificacionCliente(
            cita.usuarioId,
            'Cita cancelada',
            'Tu cita para ${cita.servicio} del ${_formatearFecha(cita.fecha)} a las ${cita.hora} ha sido cancelada.',
            {
              'tipo': 'cita_cancelada',
              'citaId': citaId,
              'servicio': cita.servicio,
              'fecha': cita.fecha.toIso8601String(),
              'hora': cita.hora,
            },
          );

          // Programar notificación local de recordatorio (sin método específico)
          print(
            '📱 Notificación de cancelación procesada para ${cita.nombreCliente}',
          );
        }
      }
      return resultado;
    } catch (e) {
      return 'Error al cancelar cita: $e';
    }
  }

  // Confirmar cita
  Future<String?> confirmarCita(String citaId) async {
    try {
      final resultado = await actualizarEstadoCita(
        citaId,
        EstadoCita.confirmada,
      );
      if (resultado == null) {
        // Obtener datos de la cita para la notificación
        final cita = await obtenerCitaPorId(citaId);
        if (cita != null) {
          // Enviar notificación push al cliente
          await FCMService.enviarNotificacionCliente(
            cita.usuarioId,
            'Cita confirmada',
            'Tu cita para ${cita.servicio} del ${_formatearFecha(cita.fecha)} a las ${cita.hora} ha sido confirmada.',
            {
              'tipo': 'cita_confirmada',
              'citaId': citaId,
              'servicio': cita.servicio,
              'fecha': cita.fecha.toIso8601String(),
              'hora': cita.hora,
            },
          );

          // Programar notificación local de recordatorio (sin método específico)
          print(
            '📱 Notificación de confirmación procesada para ${cita.nombreCliente}',
          );
        }
      }
      return resultado;
    } catch (e) {
      return 'Error al confirmar cita: $e';
    }
  }

  // Completar cita
  Future<String?> completarCita(String citaId) async {
    try {
      final resultado = await actualizarEstadoCita(
        citaId,
        EstadoCita.completada,
      );
      if (resultado == null) {
        // Obtener datos de la cita para la notificación
        final cita = await obtenerCitaPorId(citaId);
        if (cita != null) {
          // Enviar notificación push al cliente
          await FCMService.enviarNotificacionCliente(
            cita.usuarioId,
            'Cita completada',
            'Tu cita para ${cita.servicio} ha sido completada. ¡Gracias por visitarnos!',
            {
              'tipo': 'cita_completada',
              'citaId': citaId,
              'servicio': cita.servicio,
              'fecha': cita.fecha.toIso8601String(),
              'hora': cita.hora,
            },
          );
        }
      }
      return resultado;
    } catch (e) {
      return 'Error al completar cita: $e';
    }
  }

  // Verificar disponibilidad para una fecha/hora
  Future<bool> verificarDisponibilidad(
    DateTime fechaHora,
    String citaId,
  ) async {
    try {
      QuerySnapshot citasExistentes = await _firestore
          .collection('citas')
          .where(
            'fecha',
            isEqualTo: Timestamp.fromDate(
              DateTime(fechaHora.year, fechaHora.month, fechaHora.day),
            ),
          )
          .get();

      for (QueryDocumentSnapshot doc in citasExistentes.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Omitir la cita actual si estamos actualizando
        if (doc.id == citaId) continue;

        String estado = data['estado'] ?? 'pendiente';
        if (estado == 'cancelada') continue;

        String horaExistente = data['hora'] ?? '';
        if (horaExistente.isNotEmpty) {
          // Comparar las horas (simplificado)
          List<String> partesHora = horaExistente.split(':');
          if (partesHora.length >= 2) {
            int horaExistenteInt = int.tryParse(partesHora[0]) ?? 0;
            int minutoExistenteInt = int.tryParse(partesHora[1]) ?? 0;

            int horaNuevaInt = fechaHora.hour;
            int minutoNuevoInt = fechaHora.minute;

            // Si la diferencia es menor a 60 minutos, no está disponible
            int diferenciaMinutos =
                (horaNuevaInt * 60 + minutoNuevoInt) -
                (horaExistenteInt * 60 + minutoExistenteInt);

            if (diferenciaMinutos.abs() < 60) {
              return false;
            }
          }
        }
      }

      return true;
    } catch (e) {
      print('Error verificando disponibilidad: $e');
      return true; // En caso de error, permitir la cita
    }
  }

  // ==================== ESTADÍSTICAS ====================

  // Obtener total de citas
  Future<int> obtenerTotalCitas() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('citas').get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Obtener citas del mes actual
  Future<int> obtenerCitasDelMes() async {
    try {
      DateTime ahora = DateTime.now();
      DateTime inicioMes = DateTime(ahora.year, ahora.month, 1);
      DateTime finMes = DateTime(ahora.year, ahora.month + 1, 0);

      QuerySnapshot snapshot = await _firestore
          .collection('citas')
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioMes))
          .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(finMes))
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Obtener citas completadas
  Future<List<Cita>> obtenerCitasCompletadas() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('citas')
          .where('estado', isEqualTo: 'completada')
          .orderBy('fecha', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => Cita.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== UTILIDADES ====================

  // Verificar si hora está disponible
  Future<bool> estaDisponible(DateTime fechaHora, int duracionMinutos) async {
    return verificarDisponibilidad(fechaHora, '');
  }

  // Obtener horarios ocupados para una fecha
  Future<List<TimeOfDay>> obtenerHorariosOcupados(DateTime fecha) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('citas')
          .where(
            'fecha',
            isEqualTo: Timestamp.fromDate(
              DateTime(fecha.year, fecha.month, fecha.day),
            ),
          )
          .where('estado', whereIn: ['pendiente', 'confirmada'])
          .get();

      List<TimeOfDay> horariosOcupados = [];

      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String hora = data['hora'] ?? '';

        if (hora.isNotEmpty) {
          List<String> partesHora = hora.split(':');
          if (partesHora.length >= 2) {
            int horaInt = int.tryParse(partesHora[0]) ?? 0;
            int minutoInt = int.tryParse(partesHora[1]) ?? 0;
            horariosOcupados.add(TimeOfDay(hour: horaInt, minute: minutoInt));
          }
        }
      }

      return horariosOcupados;
    } catch (e) {
      print('Error obteniendo horarios ocupados: $e');
      return [];
    }
  }

  // ==================== USUARIOS ====================

  // Obtener usuario por ID
  Future<Usuario?> obtenerUsuario(String usuarioId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('usuarios')
          .doc(usuarioId)
          .get();

      if (doc.exists) {
        return Usuario.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error obteniendo usuario: $e');
      return null;
    }
  }

  // ==================== FUNCIONES AUXILIARES ====================

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  // Sistema de eliminación automática de servicios duplicados
  Future<void> eliminarServiciosDuplicados() async {
    try {
      print('🔍 Iniciando eliminación de servicios duplicados...');

      QuerySnapshot snapshot = await _firestore.collection('servicios').get();
      Map<String, List<QueryDocumentSnapshot>> serviciosPorNombre = {};

      // Agrupar servicios por nombre
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String nombre = data['nombre'] ?? '';

        if (nombre.isNotEmpty) {
          if (!serviciosPorNombre.containsKey(nombre)) {
            serviciosPorNombre[nombre] = [];
          }
          serviciosPorNombre[nombre]!.add(doc);
        }
      }

      int totalEliminados = 0;

      // Eliminar duplicados (mantener solo el primero)
      for (String nombre in serviciosPorNombre.keys) {
        List<QueryDocumentSnapshot> servicios = serviciosPorNombre[nombre]!;

        if (servicios.length > 1) {
          print(
            '📋 Encontrados ${servicios.length} servicios duplicados para: $nombre',
          );

          // Mantener el primero, eliminar el resto
          for (int i = 1; i < servicios.length; i++) {
            await servicios[i].reference.delete();
            totalEliminados++;
            print('🗑️ Eliminado servicio duplicado: ${servicios[i].id}');
          }
        }
      }

      if (totalEliminados > 0) {
        print(
          '✅ Eliminación completada: $totalEliminados servicios duplicados eliminados',
        );
      } else {
        print('✅ No se encontraron servicios duplicados');
      }
    } catch (e) {
      print('❌ Error eliminando servicios duplicados: $e');
    }
  }
}
