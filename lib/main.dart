import 'package:flutter/material.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/services/database_initializer.dart';
import 'package:flutter_application_1/services/servicios_verificador.dart';
import 'package:flutter_application_1/services/notification_service.dart';
import 'package:flutter_application_1/services/caja_service.dart';
import 'screens/login.dart';
import 'screens/menu_screen.dart';
import 'screens/Registrar.dart';

// Key global para navegación desde FCM
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializar base de datos con servicios predefinidos
  await DatabaseInitializer.inicializarBaseDatos();

  // 🔧 Verificar y reparar servicios faltantes
  await ServiciosVerificador.verificarYAgregarServiciosFaltantes();

  // Inicializar servicio de notificaciones locales
  await NotificationService.initialize();

  // Sistema FCM simplificado
  print('📱 Notificaciones locales iniciadas');

  // Inicializar servicio de caja con horarios automáticos
  await CajaService.inicializar();

  // 🔄 Migrar registros de ingresos existentes (una sola vez)
  await CajaService.migrarRegistrosExistentes();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // 🔢 Cuando el usuario abre la app, reset badge count
      NotificationService.resetBadgeCount();
      print('📱 App en primer plano - badges reseteados');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Para FCM
      title: 'Barbería Clásica',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFF1a1a1a),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2a2a2a),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
      home:
          const BarbershopLoadingScreen(), // Mostrar siempre la pantalla de carga primero
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrarScreen(),
        '/menu': (context) => const MenuScreen(),
      },
    );
  }
}

class BarbershopLoadingScreen extends StatefulWidget {
  const BarbershopLoadingScreen({Key? key}) : super(key: key);

  @override
  State<BarbershopLoadingScreen> createState() =>
      _BarbershopLoadingScreenState();
}

class _BarbershopLoadingScreenState extends State<BarbershopLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Verificar estado de autenticación después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        // Verificar si el usuario está autenticado
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          // Usuario autenticado - ir al menú principal
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MenuScreen()),
          );
        } else {
          // Usuario no autenticado - ir al login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1a1a1a),
              const Color(0xFF2d2d2d),
              const Color(0xFF1a1a1a),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icono animado
              RotationTransition(
                turns: _rotationController,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD4AF37),
                      width: 3,
                    ),
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF2d2d2d),
                        const Color(0xFF1a1a1a),
                      ],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Tijeras estilizadas
                      Transform.rotate(
                        angle: -0.5,
                        child: Icon(
                          Icons.content_cut,
                          size: 50,
                          color: const Color(0xFFD4AF37),
                        ),
                      ),
                      // Navaja
                      Positioned(
                        right: 25,
                        bottom: 25,
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Nombre de la barbería
              const Text(
                'BARBERÍA',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'CLÁSICA',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 8,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 50),

              // Indicador de carga personalizado
              SizedBox(
                width: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Barra de fondo
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Barra animada
                    AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return Align(
                          alignment: Alignment(
                            -1 + (_rotationController.value * 2),
                            0,
                          ),
                          child: Container(
                            width: 60,
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(
                                    0xFFD4AF37,
                                  ).withValues(alpha: 0.3),
                                  const Color(0xFFD4AF37),
                                  const Color(
                                    0xFFD4AF37,
                                  ).withValues(alpha: 0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFD4AF37,
                                  ).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Texto animado
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Preparando tu experiencia...',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
