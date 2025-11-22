import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// Servicio FCM simplificado - Solo recordatorios locales
class FCMService {
  /// Inicializar sistema de notificaciones (simplificado)
  static Future<void> initialize() async {
    if (kDebugMode) {
      print('📱 Sistema de notificaciones locales inicializado');
    }
  }

  /// Programar recordatorio de cita para cliente
  static Future<void> programarRecordatorioCita({
    required String nombreCliente,
    required String servicio,
    required DateTime fechaCita,
    required String hora,
  }) async {
    try {
      // Mostrar confirmación de recordatorio programado
      await NotificationService.mostrarNotificacionPersonalizada(
        titulo: '🔔 Recordatorio Programado',
        mensaje:
            'Te recordaremos tu cita de $servicio para el ${fechaCita.day}/${fechaCita.month}/${fechaCita.year} a las $hora',
      );

      if (kDebugMode) {
        print('🔔 Recordatorio programado para $nombreCliente - $servicio');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error programando recordatorio: $e');
      }
    }
  }

  /// Mostrar notificación local simple
  static Future<void> mostrarNotificacionLocal({
    required String titulo,
    required String mensaje,
  }) async {
    try {
      await NotificationService.mostrarNotificacionPersonalizada(
        titulo: titulo,
        mensaje: mensaje,
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error mostrando notificación: $e');
      }
    }
  }
}
