import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/servicios.dart';
import 'package:flutter_application_1/services/database_service.dart';
import 'package:flutter_application_1/utils/imagen_utils.dart';
import 'cita_confirmacion_screen.dart';
import 'login.dart';
import '../utils/page_transitions.dart';
import '../widgets/animated_widgets.dart';

class ServiciosScreen extends StatefulWidget {
  final bool soloLectura;
  final String? categoriaInicial; // Nueva propiedad para navegación directa
  final String? busqueda; // Nueva propiedad para términos de búsqueda

  const ServiciosScreen({
    super.key,
    this.soloLectura = false,
    this.categoriaInicial,
    this.busqueda,
  });

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Servicio> _servicios = [];
  List<Servicio> _serviciosFiltrados = [];
  bool _isLoading = true;
  String? _error;
  String _categoriaSeleccionada = 'Todos';

  final ScrollController _scrollController = ScrollController();

  // Categorías de servicios (eliminado ya que ahora usamos botones fijos)
  final Map<String, GlobalKey> _categoryKeys = {};

  @override
  void initState() {
    super.initState();
    // Inicializar las keys para cada categoría
    for (String categoria in ['Peinados', 'Barba', 'Servicio Comp']) {
      _categoryKeys[categoria] = GlobalKey();
    }

    // Establecer categoría inicial si se especifica
    if (widget.categoriaInicial != null &&
        widget.categoriaInicial!.isNotEmpty) {
      _categoriaSeleccionada = widget.categoriaInicial!;
    }

    // Si hay una búsqueda, cambiar a 'Todos' para mostrar resultados filtrados
    if (widget.busqueda != null && widget.busqueda!.isNotEmpty) {
      _categoriaSeleccionada = 'Todos';
    }

    _cargarServicios();
  }

  void _cargarServicios() {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _databaseService.obtenerServicios().listen(
        (servicios) {
          setState(() {
            _servicios = servicios;
            _serviciosFiltrados = _aplicarFiltros(servicios);
            _isLoading = false;
          });

          // Navegar automáticamente a la categoría si se especificó una
          if (widget.categoriaInicial != null &&
              widget.categoriaInicial!.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navegarACategoria(widget.categoriaInicial!);
            });
          }
        },
        onError: (e) {
          setState(() {
            _error = 'Error al cargar servicios: $e';
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Error al cargar servicios: $e';
        _isLoading = false;
      });
    }
  }

  void _filtrarPorCategoria(String categoria) {
    setState(() {
      _categoriaSeleccionada = categoria;
    });

    if (categoria == 'Todos') {
      setState(() {
        _serviciosFiltrados = _aplicarFiltros(_servicios);
      });
    } else {
      // Navegar a la sección correspondiente
      _navegarACategoria(categoria);
    }
  }

  List<Servicio> _aplicarFiltros(List<Servicio> servicios) {
    List<Servicio> resultado = servicios;

    // Aplicar filtro de búsqueda si existe
    if (widget.busqueda != null && widget.busqueda!.isNotEmpty) {
      String terminoBusqueda = widget.busqueda!.toLowerCase();
      resultado = resultado.where((servicio) {
        return servicio.nombre.toLowerCase().contains(terminoBusqueda) ||
            servicio.descripcion.toLowerCase().contains(terminoBusqueda);
      }).toList();
    }

    return resultado;
  }

  void _navegarACategoria(String categoria) {
    final key = _categoryKeys[categoria];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  List<Servicio> _obtenerServiciosPorCategoria(String categoria) {
    // Usar servicios filtrados si hay una búsqueda activa, sino usar todos los servicios
    List<Servicio> serviciosBase =
        (widget.busqueda != null && widget.busqueda!.isNotEmpty)
        ? _serviciosFiltrados
        : _servicios;

    return serviciosBase.where((servicio) {
      final nombreLower = servicio.nombre.toLowerCase();
      final descripcionLower = servicio.descripcion.toLowerCase();

      switch (categoria) {
        case 'Peinados':
          return nombreLower.contains('corte') ||
              nombreLower.contains('peinado') ||
              nombreLower.contains('clásico') ||
              nombreLower.contains('moderno') ||
              nombreLower.contains('niños');
        case 'Barba':
          return nombreLower.contains('barba') ||
              descripcionLower.contains('barba');
        case 'Servicio Comp':
          return nombreLower.contains('completo') ||
              descripcionLower.contains('completo');
        default:
          return true;
      }
    }).toList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  IconData _getIconForCategory(String categoria) {
    switch (categoria) {
      case 'Peinados':
        return Icons.content_cut;
      case 'Barba':
        return Icons.face_retouching_natural;
      case 'Servicio Comp':
        return Icons.star;
      default:
        return Icons.grid_view;
    }
  }

  Future<void> _refrescarServicios() async {
    _cargarServicios();
    // Esperar un poco para la animación
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2a2a2a),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37)),
        ),
        title: Text(
          widget.busqueda != null && widget.busqueda!.isNotEmpty
              ? 'Resultados: "${widget.busqueda}"'
              : widget.soloLectura
              ? 'Catálogo de Servicios'
              : 'Nuestros Servicios',
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _cargarServicios(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : _servicios.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.content_cut_outlined,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay servicios disponibles',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _cargarServicios(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Actualizar'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refrescarServicios,
              color: const Color(0xFFD4AF37),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado principal
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2a2a2a),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.content_cut,
                                color: Color(0xFFD4AF37),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Elige tu estilo',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD4AF37),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Selecciona el servicio que más te guste y agenda tu cita',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Botones de categoría con flechas indicadoras
                    SizedBox(
                      height: 60,
                      child: Stack(
                        children: [
                          // ListView con los botones
                          ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              SizedBox(
                                width: 120,
                                child: _buildCategoryButton(
                                  'Peinados',
                                  Icons.content_cut,
                                  _categoriaSeleccionada == 'Peinados',
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 120,
                                child: _buildCategoryButton(
                                  'Barba',
                                  Icons.face,
                                  _categoriaSeleccionada == 'Barba',
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 140,
                                child: _buildCategoryButton(
                                  'Servicio Comp',
                                  Icons.star,
                                  _categoriaSeleccionada == 'Servicio Comp',
                                ),
                              ),
                              const SizedBox(width: 20),
                            ],
                          ),

                          // Flecha izquierda
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 24,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF1a1a1a),
                                    const Color(
                                      0xFF1a1a1a,
                                    ).withValues(alpha: 0),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  color: Color(0xFFD4AF37),
                                  size: 16,
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
                              width: 24,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(
                                      0xFF1a1a1a,
                                    ).withValues(alpha: 0),
                                    const Color(0xFF1a1a1a),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Color(0xFFD4AF37),
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Sección de servicios con diseño de la imagen
                    _buildServicesSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildServicesSection() {
    if (_categoriaSeleccionada == 'Todos') {
      // Mostrar servicios filtrados de búsqueda
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _serviciosFiltrados
            .map(
              (servicio) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ModernServiceCard(
                  servicio: servicio,
                  onTap: () => _seleccionarServicio(servicio),
                ),
              ),
            )
            .toList(),
      );
    } else {
      // Mostrar servicios por categoría específica
      final serviciosCategoria = _obtenerServiciosPorCategoria(
        _categoriaSeleccionada,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la categoría con el estilo de la imagen
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Icon(
                  _getIconForCategory(_categoriaSeleccionada),
                  color: Colors.black,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  _categoriaSeleccionada.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Lista de servicios con el diseño moderno
          ...serviciosCategoria
              .map(
                (servicio) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ModernServiceCard(
                    servicio: servicio,
                    onTap: () => _seleccionarServicio(servicio),
                  ),
                ),
              )
              .toList(),
        ],
      );
    }
  }

  void _seleccionarServicio(Servicio servicio) {
    if (widget.soloLectura) {
      // Si es modo solo lectura, mostrar mensaje para registrarse
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2a2a2a),
          title: const Text(
            'Iniciar Sesión Requerido',
            style: TextStyle(color: Color(0xFFD4AF37)),
          ),
          content: Text(
            'Para reservar citas necesitas crear una cuenta o iniciar sesión.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.of(context).pushReplacement(
                  PageTransitions.fadeTransition(const LoginScreen()),
                );
              },
              child: const Text(
                'Iniciar Sesión',
                style: TextStyle(color: Color(0xFFD4AF37)),
              ),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).push(
        PageTransitions.slideFromRight(
          CitaConfirmacionScreen(servicio: servicio),
        ),
      );
    }
  }

  Widget _buildCategoryButton(String title, IconData icon, bool isSelected) {
    return AnimatedButton(
      onPressed: () => _filtrarPorCategoria(title),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF2a2a2a),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD4AF37)
                : const Color(0xFFD4AF37).withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : const Color(0xFFD4AF37),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Nueva clase para tarjetas de servicio con diseño moderno
class _ModernServiceCard extends StatelessWidget {
  final Servicio servicio;
  final VoidCallback onTap;

  const _ModernServiceCard({required this.servicio, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2a2a2a),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Imagen del servicio
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    ImagenUtils.getImagenServicio(servicio.nombre),
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      // Indicador de carga
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFD4AF37),
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback a icono si la imagen no carga
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _getIconoServicio(servicio.nombre),
                          size: 30,
                          color: const Color(0xFFD4AF37),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Información del servicio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      servicio.nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      servicio.descripcion,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: const Color(0xFFD4AF37),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${servicio.duracionMinutos} min',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFD4AF37),
                          ),
                          child: const Center(
                            child: Text(
                              'Q',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Q${servicio.precio.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Flecha para indicar que es seleccionable
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFFD4AF37),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconoServicio(String nombre) {
    final nombreLower = nombre.toLowerCase();

    // Iconos para servicios de corte
    if (nombreLower.contains('fade') ||
        nombreLower.contains('undercut') ||
        nombreLower.contains('moderno')) {
      return Icons.content_cut_outlined;
    } else if (nombreLower.contains('ejecutivo') ||
        nombreLower.contains('pompadour')) {
      return Icons.business_center;
    } else if (nombreLower.contains('militar')) {
      return Icons.star;
    } else if (nombreLower.contains('rapado')) {
      return Icons.hdr_strong;
    } else if (nombreLower.contains('diseños')) {
      return Icons.auto_fix_high;
    } else if (nombreLower.contains('niños')) {
      return Icons.child_friendly;
    } else if (nombreLower.contains('corte')) {
      return Icons.content_cut;
    }
    // Iconos para servicios de barba
    else if (nombreLower.contains('afeitado')) {
      return Icons.face_6;
    } else if (nombreLower.contains('barba')) {
      return Icons.face_retouching_natural;
    } else if (nombreLower.contains('bigote') ||
        nombreLower.contains('perilla')) {
      return Icons.face;
    }
    // Iconos para servicios de cuidado
    else if (nombreLower.contains('lavado') || nombreLower.contains('masaje')) {
      return Icons.water_drop;
    } else if (nombreLower.contains('tratamiento') ||
        nombreLower.contains('hidratación')) {
      return Icons.spa;
    } else if (nombreLower.contains('styling') ||
        nombreLower.contains('peinado')) {
      return Icons.brush;
    }
    // Iconos específicos
    else if (nombreLower.contains('cejas')) {
      return Icons.remove_red_eye;
    } else if (nombreLower.contains('paquete') ||
        nombreLower.contains('completo')) {
      return Icons.star;
    } else if (nombreLower.contains('mantenimiento')) {
      return Icons.build_circle;
    }
    // Icono por defecto
    else {
      return Icons.content_cut;
    }
  }
}
