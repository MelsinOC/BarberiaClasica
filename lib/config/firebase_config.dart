// 🔑 CONFIGURACIÓN FIREBASE FCM
//
// Para obtener tu Server Key:
// 1. Ve a Firebase Console: https://console.firebase.google.com/
// 2. Selecciona tu proyecto 'flutter-application-1-74969'
// 3. Ve a Project Settings (ícono de engranaje)
// 4. Pestaña 'Cloud Messaging'
// 5. Copia el 'Server key' de la sección 'Project credentials'
//
// Ejemplo del Server Key:
// AAAAxxxxxxx:APA91bGxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

class FirebaseConfig {
  // 🔥 REEMPLAZA ESTE STRING CON TU SERVER KEY REAL
  static const String serverKey = 'YOUR_FIREBASE_SERVER_KEY_HERE';

  // URL de Firebase Cloud Messaging
  static const String fcmUrl = 'https://fcm.googleapis.com/fcm/send';

  // Verificar si la configuración es válida
  static bool isConfigured() {
    return serverKey != 'YOUR_FIREBASE_SERVER_KEY_HERE' && serverKey.isNotEmpty;
  }

  // Obtener configuración de notificaciones
  static Map<String, dynamic> getNotificationConfig() {
    return {
      'android': {
        'notification': {
          'channel_id': 'barberia_notifications',
          'icon': '@mipmap/ic_launcher',
          'color': '#D4AF37',
          'sound': 'default',
        },
      },
      'apns': {
        'payload': {
          'aps': {'sound': 'default', 'badge': 1},
        },
      },
      'priority': 'high',
    };
  }
}
