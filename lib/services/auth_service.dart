import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/models/usuarios.dart';
// FCM simplificado - no se requiere token management

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream para escuchar cambios en la autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  // Verificar si un email corresponde a un administrador
  /*bool _esEmailAdmin(String email) {
    const emailsAdmin = [
      'admin@barberiaclasica.com',
      'barbero@barberiaclasica.com',
      'dueno@barberiaclasica.com',
    ];

    return emailsAdmin.contains(email.toLowerCase());
  }*/

  // Registrar nuevo usuario
  Future<String?> registrarUsuario({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String telefono,
  }) async {
    try {
      // Crear usuario en Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // Crear perfil de usuario en Firestore
        Usuario usuario = Usuario(
          id: userCredential.user!.uid,
          nombre: nombre,
          apellido: apellido,
          email: email,
          telefono: telefono,
          fechaRegistro: DateTime.now(),
        );

        await _firestore
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .set(usuario.toMap());

        // Actualizar nombre en Firebase Auth
        await userCredential.user!.updateDisplayName('$nombre $apellido');

        // Token FCM no requerido en versión simplificada
        print('📱 Usuario registrado exitosamente: $email');

        return null; // Éxito
      } else {
        return 'Error al crear la cuenta';
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          return 'La contraseña es muy débil';
        case 'email-already-in-use':
          return 'Ya existe una cuenta con este email';
        case 'invalid-email':
          return 'El email no es válido';
        case 'network-request-failed':
          return 'Error de conexión. Verifica tu internet';
        default:
          return 'Error al registrar usuario. Intenta nuevamente';
      }
    } catch (e) {
      return 'Error de conexión. Intenta nuevamente';
    }
  }

  // Iniciar sesión
  Future<String?> iniciarSesion({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Login exitoso - versión simplificada
      print('📱 Inicio de sesión exitoso: $email');

      return null; // Éxito
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No se encontró una cuenta con este email';
        case 'wrong-password':
          return 'Contraseña incorrecta';
        case 'invalid-email':
          return 'El email no es válido';
        case 'user-disabled':
          return 'Esta cuenta ha sido deshabilitada';
        case 'too-many-requests':
          return 'Demasiados intentos fallidos. Intenta más tarde';
        case 'invalid-credential':
          return 'Las credenciales proporcionadas no son válidas';
        case 'network-request-failed':
          return 'Error de conexión. Verifica tu internet';
        default:
          return 'Error al iniciar sesión. Verifica tus datos';
      }
    } catch (e) {
      return 'Error de conexión. Intenta nuevamente';
    }
  }

  // Cerrar sesión
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }

  // Obtener datos del usuario actual
  Future<Usuario?> obtenerUsuarioActual() async {
    if (currentUser == null) return null;

    try {
      DocumentSnapshot doc = await _firestore
          .collection('usuarios')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        return Usuario.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print('Error al obtener usuario: $e');
    }
    return null;
  }

  // Actualizar datos del usuario
  Future<String?> actualizarUsuario(Usuario usuario) async {
    try {
      await _firestore
          .collection('usuarios')
          .doc(usuario.id)
          .update(usuario.toMap());
      return null; // Éxito
    } catch (e) {
      return 'Error al actualizar usuario: $e';
    }
  }

  // Enviar email de recuperación de contraseña
  Future<String?> enviarRecuperacionPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Éxito
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No se encontró una cuenta con este email';
        case 'invalid-email':
          return 'El email no es válido';
        case 'network-request-failed':
          return 'Error de conexión. Verifica tu internet';
        default:
          return 'Error al enviar el email de recuperación';
      }
    } catch (e) {
      return 'Error de conexión. Intenta nuevamente';
    }
  }
}
