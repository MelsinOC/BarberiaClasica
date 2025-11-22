import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Estados de la caja
enum EstadoCaja { cerrada, abierta }

/// Servicio para manejar el estado de caja de la barbería
class CajaService {
  static const String _cajaCollection = 'caja_estado';
  static const String _cajaDocId = 'estado_actual';

  static Timer? _timer;
  static bool _isInitialized = false;

  /// Inicializar el servicio de caja con horarios automáticos
  static Future<void> inicializar() async {
    if (_isInitialized) return;

    // Verificar estado inicial
    await _verificarYActualizarEstado();

    // Configurar timer para verificar cada minuto
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _verificarYActualizarEstado();
    });

    _isInitialized = true;
  }

  /// Verificar y actualizar estado según horario
  static Future<void> _verificarYActualizarEstado() async {
    final ahora = DateTime.now();
    final horaActual = TimeOfDay.fromDateTime(ahora);

    // Horarios de apertura y cierre
    final horaApertura = const TimeOfDay(hour: 8, minute: 0); // 8:00 AM
    final horaCierre = const TimeOfDay(hour: 20, minute: 14); // 8:14 PM

    final estadoActual = await obtenerEstadoCaja();

    // Convertir a minutos para comparación fácil
    final minutosActuales = horaActual.hour * 60 + horaActual.minute;
    final minutosApertura = horaApertura.hour * 60 + horaApertura.minute;
    final minutosCierre = horaCierre.hour * 60 + horaCierre.minute;

    // Determinar si debería estar abierta
    final deberiaEstarAbierta =
        minutosActuales >= minutosApertura && minutosActuales < minutosCierre;

    if (deberiaEstarAbierta && estadoActual == EstadoCaja.cerrada) {
      await _abrirCaja(automatico: true);
    } else if (!deberiaEstarAbierta && estadoActual == EstadoCaja.abierta) {
      await _cerrarCaja(automatico: true);
    }
  }

  /// Obtener estado actual de la caja
  static Future<EstadoCaja> obtenerEstadoCaja() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_cajaCollection)
          .doc(_cajaDocId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final estado = data['estado'] as String? ?? 'cerrada';
        return estado == 'abierta' ? EstadoCaja.abierta : EstadoCaja.cerrada;
      }

      // Si no existe, crear con estado cerrado
      await _actualizarEstado(EstadoCaja.cerrada, automatico: true);
      return EstadoCaja.cerrada;
    } catch (e) {
      print('Error obteniendo estado de caja: $e');
      return EstadoCaja.cerrada;
    }
  }

  /// Stream para escuchar cambios en el estado de caja
  static Stream<EstadoCaja> escucharEstadoCaja() {
    return FirebaseFirestore.instance
        .collection(_cajaCollection)
        .doc(_cajaDocId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            final data = doc.data()!;
            final estado = data['estado'] as String? ?? 'cerrada';
            return estado == 'abierta'
                ? EstadoCaja.abierta
                : EstadoCaja.cerrada;
          }
          return EstadoCaja.cerrada;
        });
  }

  /// Abrir caja manualmente
  static Future<void> abrirCajaManual() async {
    await _abrirCaja(automatico: false);
  }

  /// Cerrar caja manualmente
  static Future<void> cerrarCajaManual() async {
    await _cerrarCaja(automatico: false);
  }

  /// Método interno para abrir caja
  static Future<void> _abrirCaja({required bool automatico}) async {
    await _actualizarEstado(EstadoCaja.abierta, automatico: automatico);
    final ahora = DateTime.now();
    print(
      '🟢 Caja ABIERTA ${automatico ? "automáticamente" : "manualmente"} a las ${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}',
    );
  }

  /// Método interno para cerrar caja
  static Future<void> _cerrarCaja({required bool automatico}) async {
    try {
      // Generar reporte diario antes de cerrar
      await _generarReporteDiario(automatico: automatico);

      // SIEMPRE reiniciar el contador de ingresos del día (tanto automático como manual)
      await _reiniciarIngresosDia();

      await _actualizarEstado(EstadoCaja.cerrada, automatico: automatico);
      final ahora = DateTime.now();
      print(
        '🔴 Caja CERRADA ${automatico ? "automáticamente" : "manualmente"} a las ${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}',
      );
      print('💰 Ingresos del día reiniciados a Q0.00 para nuevo conteo');
    } catch (e) {
      print('Error al cerrar caja: $e');
    }
  }

  /// Actualizar estado en Firestore
  static Future<void> _actualizarEstado(
    EstadoCaja estado, {
    required bool automatico,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection(_cajaCollection)
          .doc(_cajaDocId)
          .set({
            'estado': estado == EstadoCaja.abierta ? 'abierta' : 'cerrada',
            'ultima_actualizacion': FieldValue.serverTimestamp(),
            'tipo_cambio': automatico ? 'automatico' : 'manual',
            'fecha': DateTime.now().toIso8601String().substring(
              0,
              10,
            ), // Solo fecha
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error actualizando estado de caja: $e');
    }
  }

  /// Obtener historial de movimientos de caja
  static Future<List<Map<String, dynamic>>> obtenerHistorialCaja() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_cajaCollection)
          .orderBy('ultima_actualizacion', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error obteniendo historial de caja: $e');
      return [];
    }
  }

  /// Obtener información del día actual
  static Future<Map<String, dynamic>> obtenerResumenDia() async {
    final ahora = DateTime.now();
    final inicioDelDia = DateTime(ahora.year, ahora.month, ahora.day);
    final finDelDia = inicioDelDia.add(const Duration(days: 1));

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_cajaCollection)
          .where('ultima_actualizacion', isGreaterThanOrEqualTo: inicioDelDia)
          .where('ultima_actualizacion', isLessThan: finDelDia)
          .get();

      final movimientos = querySnapshot.docs.length;
      final estado = await obtenerEstadoCaja();

      return {
        'estado': estado,
        'movimientos_hoy': movimientos,
        'ultima_apertura': null, // Se puede implementar si se necesita
        'ultimo_cierre': null, // Se puede implementar si se necesita
      };
    } catch (e) {
      print('Error obteniendo resumen del día: $e');
      return {
        'estado': EstadoCaja.cerrada,
        'movimientos_hoy': 0,
        'ultima_apertura': null,
        'ultimo_cierre': null,
      };
    }
  }

  /// Limpiar recursos
  static void dispose() {
    _timer?.cancel();
    _timer = null;
    _isInitialized = false;
  }

  /// Reiniciar ingresos del día (marcarlos como transferidos a reportes)
  static Future<void> _reiniciarIngresosDia() async {
    try {
      final hoy = DateTime.now();
      final fechaHoy =
          '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
      final horaCorte =
          '${hoy.hour.toString().padLeft(2, '0')}:${hoy.minute.toString().padLeft(2, '0')}';

      // Obtener todos los ingresos del día que no han sido transferidos
      final ingresosSnapshot = await FirebaseFirestore.instance
          .collection('ingresos_diarios')
          .where('fecha', isEqualTo: fechaHoy)
          .where('transferido_a_reporte', isEqualTo: false)
          .get();

      // Crear un lote para actualizar todos los documentos
      final batch = FirebaseFirestore.instance.batch();

      double totalTransferido = 0.0;

      // Marcar cada ingreso como transferido
      for (final doc in ingresosSnapshot.docs) {
        final data = doc.data();
        final precio = (data['precio'] as num?)?.toDouble() ?? 0.0;
        totalTransferido += precio;

        batch.update(doc.reference, {
          'transferido_a_reporte': true,
          'fecha_transferencia': FieldValue.serverTimestamp(),
          'hora_corte': horaCorte,
        });
      }

      // Ejecutar todas las actualizaciones
      await batch.commit();

      print(
        '📊 ${ingresosSnapshot.docs.length} ingresos transferidos a reportes',
      );
      print('💰 Total transferido: Q${totalTransferido.toStringAsFixed(2)}');
      print('✨ Contador de ingresos del día reiniciado');
    } catch (e) {
      print('Error reiniciando ingresos del día: $e');
    }
  }

  /// Generar reporte diario automáticamente al cerrar caja
  static Future<void> _generarReporteDiario({required bool automatico}) async {
    try {
      final hoy = DateTime.now();
      final fechaHoy =
          '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
      final horaCorte =
          '${hoy.hour.toString().padLeft(2, '0')}:${hoy.minute.toString().padLeft(2, '0')}';

      // Obtener ingresos del día
      final ingresosDiarios = await _obtenerIngresosDia(fechaHoy);
      final totalIngresos = ingresosDiarios.fold(
        0.0,
        (sum, ingreso) => sum + (ingreso['precio'] ?? 0.0),
      );

      // Obtener estadísticas de citas del día
      final estadisticasCitas = await _obtenerEstadisticasCitas(hoy);

      // Crear reporte de cierre con información detallada
      await FirebaseFirestore.instance.collection('reportes_cierre').add({
        'fecha': fechaHoy,
        'timestamp_cierre': FieldValue.serverTimestamp(),
        'hora_cierre': horaCorte,
        'ingresos': {
          'total': totalIngresos,
          'cantidad_servicios': ingresosDiarios.length,
        },
        'citas': {
          'total': estadisticasCitas['total'],
          'completadas': estadisticasCitas['completadas'],
          'canceladas': estadisticasCitas['canceladas'],
          'pendientes': estadisticasCitas['pendientes'],
          'confirmadas': estadisticasCitas['confirmadas'],
        },
        'servicios_realizados': estadisticasCitas['servicios'],
        'tipo_cierre': automatico ? 'automatico' : 'manual',
        'resumen': automatico
            ? 'Caja cerrada automáticamente - Ingresos transferidos a reportes'
            : 'Caja cerrada manualmente - Ingresos transferidos a reportes',
        'accion_posterior': 'ingresos_reiniciados_a_cero',
      });

      print('📊 REPORTE DE CIERRE COMPLETO GENERADO');
      print('═══════════════════════════════════════════════════');
      print('📅 Fecha: $fechaHoy | ⏰ Hora: $horaCorte');
      print('💰 Ingresos totales: Q${totalIngresos.toStringAsFixed(2)}');
      print('🎯 Servicios realizados: ${ingresosDiarios.length}');
      print('📋 Citas del día: ${estadisticasCitas['total']} total');
      print('   ✅ Completadas: ${estadisticasCitas['completadas']}');
      print('   ❌ Canceladas: ${estadisticasCitas['canceladas']}');
      print('   ⏳ Pendientes: ${estadisticasCitas['pendientes']}');
      print('🔄 Próximo paso: Contador de ingresos reiniciado a Q0.00');
      print('═══════════════════════════════════════════════════');
    } catch (e) {
      print('Error generando reporte diario: $e');
    }
  }

  /// Migrar registros existentes para agregar campo transferido_a_reporte
  static Future<void> migrarRegistrosExistentes() async {
    try {
      // Obtener todos los ingresos que no tienen el campo transferido_a_reporte
      final snapshot = await FirebaseFirestore.instance
          .collection('ingresos_diarios')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      int registrosActualizados = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Si el documento no tiene el campo transferido_a_reporte, agregarlo
        if (!data.containsKey('transferido_a_reporte')) {
          batch.update(doc.reference, {
            'transferido_a_reporte':
                false, // Marcar como no transferido por defecto
          });
          registrosActualizados++;
        }
      }

      if (registrosActualizados > 0) {
        await batch.commit();
        print(
          '🔄 Migración completada: $registrosActualizados registros actualizados',
        );
      } else {
        print('✅ No hay registros que necesiten migración');
      }
    } catch (e) {
      print('Error en migración: $e');
    }
  }

  /// Obtener resumen del estado actual de ingresos y reportes
  static Future<Map<String, dynamic>> obtenerResumenCaja() async {
    try {
      final hoy = DateTime.now();
      final fechaHoy =
          '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';

      // Ingresos del día (no transferidos)
      final ingresosActivos = await _obtenerIngresosDia(fechaHoy);
      final totalActivos = ingresosActivos.fold(
        0.0,
        (sum, ing) => sum + (ing['precio'] ?? 0.0),
      );

      // Ingresos ya transferidos hoy
      final ingresosTransferidosSnapshot = await FirebaseFirestore.instance
          .collection('ingresos_diarios')
          .where('fecha', isEqualTo: fechaHoy)
          .where('transferido_a_reporte', isEqualTo: true)
          .get();

      final totalTransferidos = ingresosTransferidosSnapshot.docs.fold(
        0.0,
        (sum, doc) => sum + ((doc.data()['precio'] as num?)?.toDouble() ?? 0.0),
      );

      // Reportes de cierre de hoy
      final reportesSnapshot = await FirebaseFirestore.instance
          .collection('reportes_cierre')
          .where('fecha', isEqualTo: fechaHoy)
          .get();

      return {
        'fecha': fechaHoy,
        'ingresos_activos': totalActivos,
        'cantidad_activos': ingresosActivos.length,
        'ingresos_transferidos': totalTransferidos,
        'cantidad_transferidos': ingresosTransferidosSnapshot.docs.length,
        'reportes_generados': reportesSnapshot.docs.length,
        'total_del_dia': totalActivos + totalTransferidos,
      };
    } catch (e) {
      print('Error obteniendo resumen de caja: $e');
      return {};
    }
  }

  /// Obtener ingresos del día específico (solo los no transferidos)
  static Future<List<Map<String, dynamic>>> _obtenerIngresosDia(
    String fecha,
  ) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('ingresos_diarios')
          .where('fecha', isEqualTo: fecha)
          .where('transferido_a_reporte', isEqualTo: false)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error obteniendo ingresos del día: $e');
      return [];
    }
  }

  /// Obtener estadísticas de citas del día
  static Future<Map<String, dynamic>> _obtenerEstadisticasCitas(
    DateTime fecha,
  ) async {
    try {
      final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
      final finDia = inicioDia.add(const Duration(days: 1));

      final querySnapshot = await FirebaseFirestore.instance
          .collection('citas')
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
          .where('fecha', isLessThan: Timestamp.fromDate(finDia))
          .get();

      int completadas = 0;
      int canceladas = 0;
      int pendientes = 0;
      Map<String, int> servicios = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final estado = data['estado'] as String?;
        final servicio = data['servicio'] as String? ?? '';

        switch (estado) {
          case 'completada':
            completadas++;
            break;
          case 'cancelada':
            canceladas++;
            break;
          case 'pendiente':
          case 'confirmada':
            pendientes++;
            break;
        }

        if (servicio.isNotEmpty) {
          servicios[servicio] = (servicios[servicio] ?? 0) + 1;
        }
      }

      return {
        'total': querySnapshot.docs.length,
        'completadas': completadas,
        'canceladas': canceladas,
        'pendientes': pendientes,
        'servicios': servicios,
      };
    } catch (e) {
      print('Error obteniendo estadísticas de citas: $e');
      return {
        'total': 0,
        'completadas': 0,
        'canceladas': 0,
        'pendientes': 0,
        'servicios': <String, int>{},
      };
    }
  }
}
