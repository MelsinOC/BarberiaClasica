import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // 🔢 CONTADOR DE BADGES COMO WHATSAPP
  static int _badgeCount = 0;

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Manejar cuando el usuario toca la notificación
        debugPrint('Notificación tocada: ${response.payload}');
      },
    );

    // Crear canal de notificaciones de alta prioridad
    await _createNotificationChannel();

    // Solicitar permisos para Android 13+
    await _requestPermissions();
  }

  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'barberia_notifications_high', // ID debe coincidir con FCM
      'Barbería Clásica', // Nombre visible
      description: 'Notificaciones de citas y servicios de barbería',
      importance: Importance.max, // Máxima importancia
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFFD4AF37), // Color dorado
      showBadge: true, // 🔢 HABILITAR BADGES
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
      print('✅ Canal de notificaciones creado: ${channel.id}');
    }
  }

  static Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// 🔢 INCREMENTAR BADGE COUNT (como WhatsApp)
  static Future<void> _incrementBadgeCount() async {
    _badgeCount++;
    print('🔢 Badge count incrementado: $_badgeCount');
    // En Android, los badges se manejan automáticamente con las notificaciones
    // En iOS necesitarías flutter_app_badger para badges manuales
  }

  /// 🔢 RESET BADGE COUNT
  static Future<void> resetBadgeCount() async {
    _badgeCount = 0;
    print('🔢 Badge count reseteado');
    // Opcional: limpiar todas las notificaciones activas
    await _notifications.cancelAll();
  }

  /// 🔢 OBTENER BADGE COUNT ACTUAL
  static int getBadgeCount() => _badgeCount;

  /// Mostrar notificación inmediata de confirmación de cita
  static Future<void> mostrarNotificacionConfirmacion({
    required String nombreServicio,
    required String fecha,
    required String hora,
  }) async {
    // 🔢 INCREMENTAR CONTADOR ANTES DE MOSTRAR
    await _incrementBadgeCount();

    final androidDetails = AndroidNotificationDetails(
      'barberia_notifications_high', // Usar canal principal
      'Barbería Clásica',
      channelDescription: 'Notificaciones de confirmación de citas',
      importance: Importance.max, // Máxima prioridad
      priority: Priority.high,
      showWhen: true,
      styleInformation: const BigTextStyleInformation(''),
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      enableLights: true,
      ledColor: const Color(0xFFD4AF37),
      number: _badgeCount, // 🔢 MOSTRAR CONTADOR EN NOTIFICACIÓN
      autoCancel: true, // Se oculta al tocarla
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: null, // iOS usará incremento automático
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _badgeCount, // ID único basado en contador
      '✅ Cita Confirmada',
      'Tu cita de $nombreServicio está programada para el $fecha a las $hora en Barbería Clásica.',
      notificationDetails,
      payload: 'cita_confirmada',
    );

    print('🔔 Notificación enviada con badge count: $_badgeCount');
  }

  /// Programar recordatorio de cita (versión simplificada)
  static Future<void> programarRecordatorio({
    required String nombreServicio,
    required String fecha,
    required String hora,
    required DateTime fechaCita,
  }) async {
    // Por ahora solo mostrar notificación inmediata de recordatorio programado
    const androidDetails = AndroidNotificationDetails(
      'recordatorios_cita',
      'Recordatorios de Citas',
      channelDescription: 'Recordatorios de próximas citas',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      2, // ID único
      'Recordatorio Programado',
      'Te recordaremos sobre tu cita de $nombreServicio el día $fecha.',
      notificationDetails,
      payload: 'recordatorio_programado',
    );
  }

  /// Mostrar notificación inmediata de cancelación de cita
  static Future<void> mostrarNotificacionCancelacion({
    required String nombreServicio,
    required String fecha,
    required String hora,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'citas_cancelacion',
      'Cancelación de Citas',
      channelDescription: 'Notificaciones de cancelación de citas',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Colors.orange,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      3, // ID único para cancelaciones
      '❌ Cita Cancelada',
      'Tu cita de $nombreServicio del $fecha a las $hora ha sido cancelada',
      notificationDetails,
      payload: 'cita_cancelada',
    );
  }

  /// Mostrar notificación inmediata de cita completada
  static Future<void> mostrarNotificacionCompletada({
    required String nombreServicio,
    required String fecha,
    required String hora,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'citas_completadas',
      'Citas Completadas',
      channelDescription: 'Notificaciones de citas completadas',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Colors.green,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      4, // ID único para completadas
      '✅ Servicio Completado',
      'Tu servicio de $nombreServicio del $fecha ha sido completado. ¡Gracias por visitarnos!',
      notificationDetails,
      payload: 'cita_completada',
    );
  }

  /// Mostrar notificación al administrador sobre nueva cita
  static Future<void> mostrarNotificacionNuevaCitaAdmin({
    required String nombreCliente,
    required String nombreServicio,
    required String fecha,
    required String hora,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'admin_nuevas_citas',
      'Nuevas Citas - Admin',
      channelDescription:
          'Notificaciones de nuevas citas para el administrador',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFD4AF37), // Color dorado de la barbería
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFFD4AF37),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      5, // ID único para notificaciones admin
      '🔔 Nueva Cita Agendada',
      '$nombreCliente agendó $nombreServicio para el $fecha a las $hora',
      notificationDetails,
      payload: 'nueva_cita_admin',
    );
  }

  /// Mostrar notificación personalizada
  static Future<void> mostrarNotificacionPersonalizada({
    required String titulo,
    required String mensaje,
    String? payload,
  }) async {
    // 🔢 INCREMENTAR CONTADOR ANTES DE MOSTRAR
    await _incrementBadgeCount();

    final androidDetails = AndroidNotificationDetails(
      'barberia_notifications_high', // Usar el mismo canal que FCM
      'Barbería Clásica',
      channelDescription: 'Notificaciones de citas y servicios de barbería',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher', // Usar icono de la app
      color: const Color(0xFFD4AF37), // Color dorado
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: const Color(0xFFD4AF37),
      showWhen: true,
      when: null, // Usar hora actual
      usesChronometer: false,
      autoCancel: true, // Se oculta al tocarla
      ongoing: false,
      silent: false,
      channelShowBadge: true,
      number: _badgeCount, // 🔢 MOSTRAR CONTADOR EN NOTIFICACIÓN
      styleInformation: BigTextStyleInformation(
        mensaje,
        contentTitle: titulo,
        summaryText: 'Barbería Clásica',
      ),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: _badgeCount, // 🔢 BADGE COUNT PARA iOS
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
      100000,
    );

    print('📱 ===== MOSTRANDO NOTIFICACIÓN LOCAL =====');
    print('📋 ID: $notificationId');
    print('📋 Título: $titulo');
    print('📋 Mensaje: $mensaje');
    print('🔢 Badge Count: $_badgeCount');
    print('📱 ========================================');

    await _notifications.show(
      notificationId,
      titulo,
      mensaje,
      notificationDetails,
      payload: payload ?? 'personalizada',
    );
  }

  /// Cancelar todas las notificaciones programadas
  static Future<void> cancelarTodasLasNotificaciones() async {
    await _notifications.cancelAll();
  }

  /// Cancelar notificación específica
  static Future<void> cancelarNotificacion(int id) async {
    await _notifications.cancel(id);
  }
}
