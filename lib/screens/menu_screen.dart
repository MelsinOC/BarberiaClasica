import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/auth_service.dart';
import 'login.dart';
import 'servicios_screen.dart';
import 'historial_citas_screen_fixed.dart';
import 'admin_dashboard_screen.dart';
import 'reportes_screen.dart';

class MenuScreen extends StatefulWidget {
  final bool esInvitado;

  const MenuScreen({super.key, this.esInvitado = false});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final AuthService authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  String nombreUsuario = '';
  bool get esInvitado => widget.esInvitado;

  // Variables para sugerencias de búsqueda rotativas
  int _currentHintIndex = 0;
  Timer? _hintTimer;
  final List<String> _searchHints = [
    'Buscar: corte, barba, fade...',
    'Prueba: clásico, moderno...',
    'Encuentra: servicio completo...',
    'Busca: corte de niños...',
    'Escribe: arreglo de barba...',
  ];

  @override
  void initState() {
    super.initState();
    _obtenerNombreUsuario();
    _startHintRotation();
  }

  void _startHintRotation() {
    _hintTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _currentHintIndex = (_currentHintIndex + 1) % _searchHints.length;
      });
    });
  }

  void _obtenerNombreUsuario() async {
    if (!esInvitado) {
      final usuario = authService.currentUser;
      if (usuario != null) {
        try {
          // Obtener datos del usuario desde Firestore
          final docSnapshot = await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(usuario.uid)
              .get();

          if (docSnapshot.exists) {
            final data = docSnapshot.data()!;
            final nombre = data['nombre'] ?? '';
            final apellido = data['apellido'] ?? '';
            final nombreCompleto = '$nombre $apellido'.trim();

            setState(() {
              nombreUsuario = nombreCompleto.toUpperCase();
            });
          } else {
            // Si no hay datos en Firestore, usar displayName o email
            final displayName = usuario.displayName;
            if (displayName != null && displayName.isNotEmpty) {
              setState(() {
                nombreUsuario = displayName.toUpperCase();
              });
            } else if (usuario.email != null) {
              final nombre = usuario.email!.split('@')[0];
              setState(() {
                nombreUsuario = nombre.toUpperCase();
              });
            }
          }
        } catch (e) {
          // En caso de error, usar email como fallback
          if (usuario.email != null) {
            final nombre = usuario.email!.split('@')[0];
            setState(() {
              nombreUsuario = nombre.toUpperCase();
            });
          }
        }
      }
    }
  }

  bool _esAdministrador() {
    // Lista de emails de administradores
    const emailsAdmin = [
      'admin@barberiaclasica.com',
      'barbero@barberiaclasica.com',
      'dueno@barberiaclasica.com',
    ];

    if (esInvitado) return false;

    final usuario = authService.currentUser;
    if (usuario?.email != null) {
      return emailsAdmin.contains(usuario!.email!.toLowerCase());
    }
    return false;
  }

  void _realizarBusqueda(String termino) {
    if (termino.trim().isNotEmpty) {
      // Navegar a la pantalla de servicios con el término de búsqueda
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiciosScreen(busqueda: termino.trim()),
        ),
      );
      // Limpiar el campo de búsqueda
      _searchController.clear();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Configuración del tema del sistema
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2a2a2a),
        elevation: 0,
        title: const Text(
          'Barbería Clásica',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              if (esInvitado) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              } else {
                await authService.cerrarSesion();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              }
            },
            icon: Icon(
              esInvitado ? Icons.login : Icons.logout,
              color: const Color(0xFFD4AF37),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabecera dorada como en la imagen
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFD4AF37), Color(0xFFB8941F)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Stack(
                children: [
                  // Elementos decorativos de fondo - Solo 2 círculos
                  // CÍRCULO GRANDE en esquina superior derecha
                  Positioned(
                    top: 10,
                    right: 20,
                    child: Container(
                      width: 80, // Círculo grande
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: 0.12,
                        ), // Más intensidad
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // CÍRCULO MEDIANO en esquina inferior izquierda
                  Positioned(
                    bottom: 15,
                    left: 15,
                    child: Container(
                      width: 50, // Círculo mediano
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: 0.06,
                        ), // Menos intensidad
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Contenido principal de la cabecera
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Saludo con avatar y email
                          Row(
                            children: [
                              // Avatar circular
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color.fromARGB(
                                      255,
                                      0,
                                      0,
                                      0,
                                    ).withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons
                                      .face_retouching_natural, // Icono de hombre con barba
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 15),
                              // Textos de saludo
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      esInvitado
                                          ? '¡Bienvenido!'
                                          : '¡Bienvenido!',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      esInvitado
                                          ? 'INVITADO'
                                          : nombreUsuario.isEmpty
                                          ? 'USUARIO'
                                          : nombreUsuario,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color.fromARGB(
                                          255,
                                          0,
                                          0,
                                          0,
                                        ).withValues(alpha: 0.8),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Barra de búsqueda
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(
                                alpha: 0.15,
                              ), // Gris translúcido elegante
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.black, // Borde negro
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: _realizarBusqueda,
                              style: TextStyle(
                                color: Colors.black.withValues(
                                  alpha: 0.8,
                                ), // Texto con opacidad
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: _searchHints[_currentHintIndex],
                                hintStyle: TextStyle(
                                  color: Colors.black.withValues(
                                    alpha: 0.5,
                                  ), // Hint con opacidad baja
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.black.withValues(
                                    alpha: 0.5,
                                  ), // Icono con opacidad baja
                                ),
                                filled: false, // Sin relleno
                                fillColor: Colors
                                    .transparent, // Color transparente por si acaso
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical:
                                      10, // Reducido de 15 a 10 para menos altura
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido principal
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Sección Servicios Populares
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Servicios Populares',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ServiciosScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Ver todos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Grid de servicios populares - Con flechas indicadoras
                  SizedBox(
                    height: 140, // Altura fija para las tarjetas
                    child: Stack(
                      children: [
                        // ListView scrolleable
                        ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 35),
                          children: [
                            _ServicioCard(
                              icon: Icons.content_cut,
                              title: 'Peinados',
                              backgroundImage:
                                  'assets/images/servicios/corte_clasico.jpg',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ServiciosScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 15),
                            _ServicioCard(
                              icon: Icons.face_retouching_natural,
                              title: 'Corte de Barba',
                              backgroundImage:
                                  'assets/images/servicios/corte_barba.jpg',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ServiciosScreen(
                                      categoriaInicial:
                                          'Barba', // Navegar directamente a la sección Barba
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 15),
                            _ServicioCard(
                              icon: Icons.star,
                              title: 'Servicios Completos',
                              backgroundImage:
                                  'assets/images/servicios/corte_clasico.jpg',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ServiciosScreen(
                                      categoriaInicial:
                                          'Servicio Comp', // Navegar directamente a servicios completos
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 20), // Espacio final
                          ],
                        ),
                        // Flecha izquierda
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 30,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 1.0],
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back_ios,
                                color: Color(0xFFD4AF37),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        // Flecha derecha
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 30,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.1),
                                ],
                                stops: const [0.0, 1.0],
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFFD4AF37),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Sección Acciones Rápidas
                  const Text(
                    'Acciones Rápidas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Grid de acciones rápidas
                  Row(
                    children: [
                      Expanded(
                        child: _AccionCard(
                          icon: Icons.visibility,
                          title: 'Ver Servicios',
                          subtitle: 'Explorar todo',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ServiciosScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _AccionCard(
                          icon: esInvitado
                              ? Icons.login
                              : Icons.access_time_rounded,
                          title: esInvitado ? 'Iniciar Sesión' : 'Historial',
                          subtitle: esInvitado ? 'Mi cuenta' : 'Mis Citas',
                          onTap: () {
                            if (esInvitado) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HistorialCitasScreen(),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  // Botones de Administración (solo para admin)
                  if (_esAdministrador()) ...[
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _AccionCard(
                            icon: Icons.dashboard,
                            title: 'Panel Admin',
                            subtitle: 'Gestionar citas',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminDashboardScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _AccionCard(
                            icon: Icons.analytics,
                            title: 'Reportes',
                            subtitle: 'Estadísticas',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ReportesScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 30),

                  // Sección Contacto
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                            'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80',
                          ),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2a2a2a).withValues(
                            alpha: 0.85,
                          ), // Overlay oscuro semitransparente
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Contacto',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD4AF37),
                              ),
                            ),
                            const SizedBox(height: 25),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _ContactoIcono(
                                  icon: Icons.location_on_rounded,
                                  title: 'Ubicación',
                                  subtitle: 'Guatemala',
                                ),
                                _ContactoIcono(
                                  icon: Icons.phone_rounded,
                                  title: 'Teléfono',
                                  subtitle: '+502 4283-5421',
                                ),
                                _ContactoIcono(
                                  icon: Icons.access_time_rounded,
                                  title: 'Horarios',
                                  subtitle: 'Lun-Sáb 8-8',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para tarjetas de servicios populares
class _ServicioCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? backgroundImage; // Nueva propiedad para imagen de fondo
  final VoidCallback onTap;

  const _ServicioCard({
    required this.icon,
    required this.title,
    this.backgroundImage, // Parámetro opcional
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160, // Ancho fijo para scroll horizontal
        height: 120, // ALTO un poco más grande
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF2a2a2a),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFFD4AF37), // BORDE DORADO
            width: 1, // Grosor de 1px
          ),
          image: backgroundImage != null
              ? DecorationImage(
                  image: AssetImage(backgroundImage!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.75),
                    BlendMode.overlay,
                  ),
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment:
              CrossAxisAlignment.start, // ALINEADO A LA IZQUIERDA
          children: [
            Container(
              padding: const EdgeInsets.all(
                10,
              ), // Reducido para que se ajuste al nuevo tamaño
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(
                  alpha: 0.4,
                ), // Aumentar opacidad para mejor visibilidad
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 6,
                    offset: Offset(2, 2),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: const Color(
                  0xFFD4AF37,
                ).withValues(alpha: 1.0), // Opacidad completa para el icono
                size: 22, // Ligeramente más grande
              ),
            ),
            const SizedBox(height: 8), // Reducido el espaciado
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3,
                      color: Colors.black,
                    ),
                  ],
                ),
                textAlign: TextAlign.left, // TEXTO ALINEADO A LA IZQUIERDA
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para tarjetas de acciones rápidas
class _AccionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AccionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isVerServicios = title == 'Ver Servicios';
    bool isHistorial = title == 'Historial';

    // Determinar el color del borde y fondo
    Color borderColor;
    Color backgroundColor;
    Color defaultIconColor;

    if (isVerServicios) {
      borderColor = const Color(0xFFD4AF37).withValues(alpha: 0.6);
      backgroundColor = const Color(0xFFD4AF37).withValues(alpha: 0.2);
      defaultIconColor = const Color(0xFFD4AF37).withValues(alpha: 0.7);
    } else if (isHistorial) {
      borderColor = Colors.green.withValues(alpha: 0.6);
      backgroundColor = Colors.green.withValues(alpha: 0.2);
      defaultIconColor = Colors.green.withValues(alpha: 0.7);
    } else {
      // Para "Iniciar Sesión" y otros
      borderColor = const Color(0xFF25D366).withValues(alpha: 0.6);
      backgroundColor = const Color(0xFF25D366).withValues(alpha: 0.2);
      defaultIconColor = const Color(0xFF25D366).withValues(alpha: 0.7);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120, // Aumentado de 100 a 120 para más espacio
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF2a2a2a),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: defaultIconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(
              height: 2,
            ), // Pequeño espacio entre título y subtítulo
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13, // Reducido ligeramente para que quepa mejor
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para iconos de contacto
class _ContactoIcono extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ContactoIcono({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFFD4AF37).withValues(alpha: 0.7),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD4AF37),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
