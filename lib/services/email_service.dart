import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';

class EmailService {
  // Configuración del servidor SMTP (usando Gmail como ejemplo)
  static const String _username = 'tu-email@gmail.com'; // Cambiar por tu email
  static const String _password =
      'tu-contraseña-app'; // Usar contraseña de aplicación
  static const String _smtpServer = 'smtp.gmail.com';
  static const int _port = 587;

  /// Enviar email de confirmación de cita
  static Future<bool> enviarConfirmacionCita({
    required String emailCliente,
    required String nombreCliente,
    required String nombreServicio,
    required String fecha,
    required String hora,
    required double precio,
  }) async {
    try {
      // Configurar servidor SMTP
      final smtpServer = SmtpServer(
        _smtpServer,
        port: _port,
        username: _username,
        password: _password,
        allowInsecure: false,
        ssl: false,
      );

      // Crear el mensaje
      final message = Message()
        ..from = Address(_username, 'Barbería Clásica')
        ..recipients.add(emailCliente)
        ..subject = 'Confirmación de Cita - Barbería Clásica'
        ..html = _generarHtmlConfirmacion(
          nombreCliente: nombreCliente,
          nombreServicio: nombreServicio,
          fecha: fecha,
          hora: hora,
          precio: precio,
        );

      // Enviar email
      await send(message, smtpServer);

      if (kDebugMode) {
        print('Email de confirmación enviado exitosamente a $emailCliente');
      }

      return true;
    } catch (e) {
      // En lugar de solo imprimir el error, manejarlo más graciosamente
      print('⚠️ Error al enviar email de confirmación: $e');
      print('📧 El servicio continuará funcionando sin email');
      // No falla la operación principal, solo el email
      return false;
    }
  }

  /// Enviar recordatorio de cita por email
  static Future<bool> enviarRecordatorioCita({
    required String emailCliente,
    required String nombreCliente,
    required String nombreServicio,
    required String fecha,
    required String hora,
  }) async {
    try {
      // Configurar servidor SMTP
      final smtpServer = SmtpServer(
        _smtpServer,
        port: _port,
        username: _username,
        password: _password,
        allowInsecure: false,
        ssl: false,
      );

      // Crear el mensaje
      final message = Message()
        ..from = Address(_username, 'Barbería Clásica')
        ..recipients.add(emailCliente)
        ..subject = 'Recordatorio de Cita - Barbería Clásica'
        ..html = _generarHtmlRecordatorio(
          nombreCliente: nombreCliente,
          nombreServicio: nombreServicio,
          fecha: fecha,
          hora: hora,
        );

      // Enviar email
      await send(message, smtpServer);

      if (kDebugMode) {
        print('Email de recordatorio enviado exitosamente a $emailCliente');
      }

      return true;
    } catch (e) {
      // Manejar error sin afectar la funcionalidad principal
      print('⚠️ Error al enviar email de recordatorio: $e');
      print('📧 Las notificaciones push siguen funcionando');
      return false;
    }
  }

  /// Generar HTML para email de confirmación
  static String _generarHtmlConfirmacion({
    required String nombreCliente,
    required String nombreServicio,
    required String fecha,
    required String hora,
    required double precio,
  }) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Confirmación de Cita</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                line-height: 1.6;
                color: #333;
                background-color: #f4f4f4;
                margin: 0;
                padding: 20px;
            }
            .container {
                max-width: 600px;
                margin: 0 auto;
                background: white;
                padding: 30px;
                border-radius: 10px;
                box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            }
            .header {
                text-align: center;
                background: linear-gradient(135deg, #D4AF37, #FFE55C);
                color: white;
                padding: 20px;
                border-radius: 8px;
                margin-bottom: 30px;
            }
            .header h1 {
                margin: 0;
                font-size: 28px;
            }
            .content {
                padding: 0 20px;
            }
            .cita-details {
                background: #f8f9fa;
                border-left: 4px solid #D4AF37;
                padding: 20px;
                margin: 20px 0;
                border-radius: 5px;
            }
            .detail-row {
                display: flex;
                justify-content: space-between;
                margin: 10px 0;
                padding: 8px 0;
                border-bottom: 1px solid #eee;
            }
            .detail-label {
                font-weight: bold;
                color: #555;
            }
            .detail-value {
                color: #333;
            }
            .footer {
                text-align: center;
                margin-top: 30px;
                padding-top: 20px;
                border-top: 2px solid #D4AF37;
                color: #666;
            }
            .contact-info {
                background: #e8f4fd;
                padding: 15px;
                border-radius: 5px;
                margin-top: 20px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Barbería Clásica</h1>
                <p>Confirmación de Cita</p>
            </div>
            
            <div class="content">
                <h2>¡Hola $nombreCliente!</h2>
                <p>Tu cita ha sido <strong>confirmada exitosamente</strong>. Aquí tienes todos los detalles:</p>
                
                <div class="cita-details">
                    <div class="detail-row">
                        <span class="detail-label">Servicio:</span>
                        <span class="detail-value">$nombreServicio</span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Fecha:</span>
                        <span class="detail-value">$fecha</span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Hora:</span>
                        <span class="detail-value">$hora</span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Precio:</span>
                        <span class="detail-value">Q${precio.toStringAsFixed(2)}</span>
                    </div>
                </div>
                
                <div class="contact-info">
                    <h3>Información de Contacto</h3>
                    <p><strong>Dirección:</strong> Tu dirección aquí</p>
                    <p><strong>Teléfono:</strong> +1 (555) 123-4567</p>
                    <p><strong>Email:</strong> contacto@barberiaclasica.com</p>
                </div>
                
                <p><strong>Notas importantes:</strong></p>
                <ul>
                    <li>Por favor llega 10 minutos antes de tu cita</li>
                    <li>Si necesitas cancelar o reprogramar, hazlo con al menos 24 horas de anticipación</li>
                    <li>Recuerda traer una identificación válida</li>
                </ul>
            </div>
            
            <div class="footer">
                <p>¡Gracias por elegir Barbería Clásica!</p>
                <p><em>El estilo clásico nunca pasa de moda</em></p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  /// Generar HTML para email de recordatorio
  static String _generarHtmlRecordatorio({
    required String nombreCliente,
    required String nombreServicio,
    required String fecha,
    required String hora,
  }) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Recordatorio de Cita</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                line-height: 1.6;
                color: #333;
                background-color: #f4f4f4;
                margin: 0;
                padding: 20px;
            }
            .container {
                max-width: 600px;
                margin: 0 auto;
                background: white;
                padding: 30px;
                border-radius: 10px;
                box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            }
            .header {
                text-align: center;
                background: linear-gradient(135deg, #FF6B6B, #FFE66D);
                color: white;
                padding: 20px;
                border-radius: 8px;
                margin-bottom: 30px;
            }
            .reminder-icon {
                font-size: 48px;
                margin-bottom: 10px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Recordatorio de Cita</h1>
                <p>Barbería Clásica</p>
            </div>
            
            <div class="content">
                <h2>¡Hola $nombreCliente!</h2>
                <p>Te recordamos que tienes una cita programada:</p>
                
                <div class="cita-details">
                    <div class="detail-row">
                        <span class="detail-label">Servicio:</span>
                        <span class="detail-value">$nombreServicio</span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Fecha:</span>
                        <span class="detail-value">$fecha</span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Hora:</span>
                        <span class="detail-value">$hora</span>
                    </div>
                </div>
                
                <p>¡Te esperamos en Barbería Clásica!</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  /// Enviar email de cancelación de cita
  static Future<bool> enviarCancelacionCita({
    required String emailCliente,
    required String nombreCliente,
    required String nombreServicio,
    required String fecha,
    required String hora,
  }) async {
    try {
      // Configurar servidor SMTP
      final smtpServer = SmtpServer(
        _smtpServer,
        port: _port,
        username: _username,
        password: _password,
        allowInsecure: false,
        ssl: false,
      );

      // Crear el mensaje
      final message = Message()
        ..from = Address(_username, 'Barbería Clásica')
        ..recipients.add(emailCliente)
        ..subject = 'Cita Cancelada - Barbería Clásica'
        ..html = _generarHtmlCancelacion(
          nombreCliente: nombreCliente,
          nombreServicio: nombreServicio,
          fecha: fecha,
          hora: hora,
        );

      // Enviar email
      await send(message, smtpServer);

      if (kDebugMode) {
        print('Email de cancelación enviado exitosamente a $emailCliente');
      }

      return true;
    } catch (e) {
      // Error en email no debe afectar las notificaciones push
      print('⚠️ Error enviando email de cancelación: $e');
      print('📧 Cliente seguirá recibiendo notificación push');
      return false;
    }
  }

  /// Generar HTML para email de cancelación
  static String _generarHtmlCancelacion({
    required String nombreCliente,
    required String nombreServicio,
    required String fecha,
    required String hora,
  }) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <style>
            .email-container {
                max-width: 600px;
                margin: 0 auto;
                font-family: Arial, sans-serif;
                background-color: #f9f9f9;
                border-radius: 10px;
                overflow: hidden;
            }
            .header {
                background: linear-gradient(135deg, #D4AF37, #B8941F);
                color: white;
                padding: 30px;
                text-align: center;
            }
            .content {
                padding: 30px;
                background-color: white;
            }
            .cita-details {
                background-color: #fff3e0;
                border-left: 4px solid #ff9800;
                padding: 20px;
                margin: 20px 0;
                border-radius: 5px;
            }
            .detail-row {
                display: flex;
                justify-content: space-between;
                margin-bottom: 10px;
                padding: 5px 0;
                border-bottom: 1px solid #eee;
            }
            .detail-label {
                font-weight: bold;
                color: #333;
            }
            .detail-value {
                color: #ff9800;
                font-weight: bold;
            }
            .footer {
                background-color: #2a2a2a;
                color: white;
                padding: 20px;
                text-align: center;
                font-size: 12px;
            }
            .icon {
                font-size: 48px;
                margin-bottom: 20px;
            }
        </style>
    </head>
    <body>
        <div class="email-container">
            <div class="header">
                <div class="icon">❌</div>
                <h1>Cita Cancelada</h1>
                <p>Tu cita ha sido cancelada</p>
            </div>
            <div class="content">
                <h2>Hola $nombreCliente,</h2>
                
                <p>Lamentamos informarte que tu cita ha sido <strong>cancelada</strong> por parte de la barbería.</p>
                
                <div class="cita-details">
                    <div class="detail-row">
                        <span class="detail-label">Servicio:</span>
                        <span class="detail-value">$nombreServicio</span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Fecha:</span>
                        <span class="detail-value">$fecha</span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Hora:</span>
                        <span class="detail-value">$hora</span>
                    </div>
                </div>
                
                <p>Disculpa las molestias ocasionadas. Puedes agendar una nueva cita cuando gustes.</p>
                
                <p><strong>Para reagendar:</strong><br>
                📞 Teléfono: +502 1234-5678<br>
                📧 Email: info@barberiaclasica.com</p>
            </div>
            <div class="footer">
                <p>© 2025 Barbería Clásica - Guatemala</p>
                <p>Este es un mensaje automático, no responder a este correo.</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }
}
