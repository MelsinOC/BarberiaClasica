//import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
//import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
//import 'package:http/http.dart' as http;

class FCMService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  // Configuración para admin específico
  static const String ADMIN_TARGET_EMAIL = 'admin@barberiaclasica.com';

  /// Inicializar Firebase Cloud Messaging
  static Future<void> initialize() async {
    // print('🚀 Inicializando FCM Service...');

    try {
      // Solicitar permisos de notificación
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // print('✅ Permisos de notificación concedidos');
      } else {
        // print('❌ Permisos de notificación denegados');
      }
    } catch (e) {
      // print('❌ Error inicializando FCM: $e');
    }
  }

  /// Obtener token FCM del dispositivo actual
  static Future<String?> getDeviceToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      // print('📱 FCM Token obtenido: ${token?.substring(0, 20)}...');
      return token;
    } catch (e) {
      // print('❌ Error obteniendo FCM token: $e');
      return null;
    }
  }

  /// Guardar token FCM del usuario en Firestore
  static Future<void> saveUserToken(String userId, bool isAdmin) async {
    try {
      String? token = await getDeviceToken();
      final user = FirebaseAuth.instance.currentUser;

      if (token != null && user != null) {
        // print('💾 Guardando token FCM para ${user.email}');

        await FirebaseFirestore.instance
            .collection('user_tokens')
            .doc(userId)
            .set({
              'token': token,
              'isAdmin': isAdmin,
              'email': user.email?.toLowerCase() ?? '',
              'userId': userId,
              'lastUpdated': FieldValue.serverTimestamp(),
              'deviceInfo': {
                'platform': Platform.isAndroid ? 'android' : 'ios',
                'appVersion': '1.0.0',
              },
            }, SetOptions(merge: true));

        // print('✅ Token FCM guardado exitosamente');
      }
    } catch (e) {
      // print('❌ Error guardando token FCM: $e');
    }
  }

  /// Enviar notificación a administradores (solo admin@barberiaclasica.com)
  static Future<void> enviarNotificacionAdmin(
    String titulo,
    String cuerpo,
    Map<String, dynamic> datos,
  ) async {
    try {
      // print('📤 Enviando notificación a admin: $titulo');

      // Buscar token del admin específico
      QuerySnapshot adminTokens = await FirebaseFirestore.instance
          .collection('user_tokens')
          .where('email', isEqualTo: ADMIN_TARGET_EMAIL)
          .where('isAdmin', isEqualTo: true)
          .get();

      if (adminTokens.docs.isEmpty) {
        // print('⚠️ No se encontró token para el admin: $ADMIN_TARGET_EMAIL');
        return;
      }

      // Procesar tokens encontrados
      for (QueryDocumentSnapshot doc in adminTokens.docs) {
        Map<String, dynamic> tokenData = doc.data() as Map<String, dynamic>;
        String token = tokenData['token'] ?? '';

        if (token.isNotEmpty) {
          // print('📱 Token admin encontrado: ${token.substring(0, 20)}...');
          // En una implementación real, aquí enviarías la notificación push
        }
      }
    } catch (e) {
      // print('❌ Error enviando notificación a admin: $e');
    }
  }

  /// Enviar notificación a cliente específico
  static Future<void> enviarNotificacionCliente(
    String usuarioId,
    String titulo,
    String cuerpo,
    Map<String, dynamic> datos,
  ) async {
    try {
      // print('📤 Enviando notificación a cliente: $titulo');

      // Buscar token del cliente
      DocumentSnapshot tokenDoc = await FirebaseFirestore.instance
          .collection('user_tokens')
          .doc(usuarioId)
          .get();

      if (!tokenDoc.exists) {
        // print('⚠️ No se encontró token para el usuario: $usuarioId');
        return;
      }

      Map<String, dynamic> tokenData = tokenDoc.data() as Map<String, dynamic>;
      String token = tokenData['token'] ?? '';

      if (token.isNotEmpty) {
        // print('📱 Token cliente encontrado: ${token.substring(0, 20)}...');
        // En una implementación real, aquí enviarías la notificación push
      }
    } catch (e) {
      // print('❌ Error enviando notificación a cliente: $e');
    }
  }

  /// Limpiar token FCM cuando el usuario cierra sesión
  static Future<void> clearUserToken(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('user_tokens')
          .doc(userId)
          .delete();

      // print('🗑️ Token FCM limpiado para usuario: $userId');
    } catch (e) {
      // print('❌ Error limpiando token FCM: $e');
    }
  }

  /// Diagnosticar configuración FCM
  static Future<Map<String, dynamic>> diagnosticar() async {
    Map<String, dynamic> diagnostico = {};

    try {
      // Verificar permisos
      NotificationSettings settings = await _firebaseMessaging
          .getNotificationSettings();
      diagnostico['permisos'] = settings.authorizationStatus.toString();

      // Verificar token
      String? token = await getDeviceToken();
      diagnostico['token_disponible'] = token != null;
      diagnostico['token_longitud'] = token?.length ?? 0;

      // Verificar tokens en Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot tokenDoc = await FirebaseFirestore.instance
            .collection('user_tokens')
            .doc(user.uid)
            .get();
        diagnostico['token_guardado'] = tokenDoc.exists;
      }

      // print('🔍 Diagnóstico FCM: $diagnostico');
      return diagnostico;
    } catch (e) {
      diagnostico['error'] = e.toString();
      return diagnostico;
    }
  }
}
