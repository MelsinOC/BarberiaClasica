import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/citas.dart';
import '../services/database_service.dart';
import '../services/caja_service.dart';
import '../services/email_service.dart';
import '../services/fcm_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String _filtroEstado =
      'todas'; // todas, notificaciones, pendientes, completadas, canceladas

  // Variables para notificaciones
  bool _primeraVez = true;
  List<String> _citasNotificadas = [];
  bool _alertaVisible = true; // Control de visibilidad de la alerta

  @override
  void initState() {
    super.initState();
    _inicializarNotificaciones();
  }

  void _inicializarNotificaciones() {
    // Escuchar cambios en tiempo real
    _databaseService.obtenerTodasLasCitas().listen((citas) {
      final citasPendientes = citas
          .where((c) => c.estado == EstadoCita.pendiente)
          .toList();

      if (_primeraVez) {
        // Primera carga, solo inicializar contador
        _citasNotificadas = citasPendientes.map((c) => c.id).toList();
        _primeraVez = false;
      } else {
        // Verificar si hay nuevas citas
        final nuevasCitas = citasPendientes
            .where((cita) => !_citasNotificadas.contains(cita.id))
            .toList();

        if (nuevasCitas.isNotEmpty) {
          _mostrarNotificacionNuevaCita(nuevasCitas);
          _citasNotificadas.addAll(nuevasCitas.map((c) => c.id));
        }
      }
    });
  }

  void _mostrarNotificacionNuevaCita(List<Cita> nuevasCitas) {
    if (mounted) {
      if (nuevasCitas.length > 1) {
        // Múltiples citas nuevas
        _mostrarDialogMultiplesCitas(nuevasCitas);
      } else {
        // Una sola cita nueva
        final cita = nuevasCitas.first;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notification_important, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔔 Nueva cita de ${cita.nombreCliente}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${cita.servicio} - ${cita.fecha.day}/${cita.fecha.month} a las ${cita.hora}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFD4AF37),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Ver',
              textColor: Colors.white,
              onPressed: () => _verDetallesCita(cita),
            ),
          ),
        );
      }
    }
  }

  void _mostrarDialogMultiplesCitas(List<Cita> nuevasCitas) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🔔 ${nuevasCitas.length} nuevas citas recibidas',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFD4AF37),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Ver todas',
            textColor: Colors.white,
            onPressed: () {
              setState(() {
                _filtroEstado = 'notificaciones';
              });
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Panel de Administración',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFD4AF37),
        elevation: 0,
        actions: [
          // Indicador de notificaciones
          StreamBuilder<List<Cita>>(
            stream: _databaseService.obtenerTodasLasCitas(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final citasPendientes = snapshot.data!
                  .where((c) => c.estado == EstadoCita.pendiente)
                  .length;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _filtroEstado = 'notificaciones';
                      });
                    },
                  ),
                  if (citasPendientes > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$citasPendientes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Alerta de nuevas citas con botón cerrar
          _buildAlertaNuevasCitas(),

          // Estado de la caja
          _buildEstadoCaja(),

          // Cards de estadísticas
          _buildStatsCards(),

          // Filtros
          _buildFiltros(),

          // Lista de citas
          Expanded(
            child: StreamBuilder<List<Cita>>(
              stream: _databaseService.obtenerTodasLasCitas(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final todasLasCitas = snapshot.data ?? [];
                final citasFiltradas = _filtrarCitas(todasLasCitas);

                if (citasFiltradas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _obtenerMensajeVacio(),
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: citasFiltradas.length,
                  itemBuilder: (context, index) {
                    final cita = citasFiltradas[index];
                    return _buildCitaCard(cita);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _obtenerMensajeVacio() {
    switch (_filtroEstado) {
      case 'notificaciones':
        return 'No hay notificaciones nuevas';
      case 'pendientes':
        return 'No hay citas por completar';
      case 'completadas':
        return 'No hay citas completadas';
      case 'canceladas':
        return 'No hay citas canceladas';
      case 'todas':
      default:
        return 'No hay historial de citas';
    }
  }

  Widget _buildStatsCards() {
    return StreamBuilder<List<Cita>>(
      stream: _databaseService.obtenerTodasLasCitas(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(child: CircularProgressIndicator()),
                Expanded(child: CircularProgressIndicator()),
                Expanded(child: CircularProgressIndicator()),
              ],
            ),
          );
        }

        final citas = snapshot.data!;
        final hoy = DateTime.now();
        final citasHoy = citas
            .where(
              (c) =>
                  c.fecha.year == hoy.year &&
                  c.fecha.month == hoy.month &&
                  c.fecha.day == hoy.day,
            )
            .toList();

        final citasPendientes = citas
            .where((c) => c.estado == EstadoCita.pendiente)
            .length;

        return _buildStatsCardsConIngresosDinamicos(citasHoy, citasPendientes);
      },
    );
  }

  Widget _buildStatsCardsConIngresosDinamicos(
    List<Cita> citasHoy,
    int citasPendientes,
  ) {
    return FutureBuilder<double>(
      future: _calcularIngresosDinamicos(citasHoy),
      builder: (context, snapshot) {
        final ingresos = snapshot.hasData ? snapshot.data! : 0.0;

        return Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Citas Hoy',
                  '${citasHoy.length}',
                  Icons.today,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Pendientes',
                  '$citasPendientes',
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCardCustomIcon(
                  'Ingresos Hoy',
                  'Q${ingresos.toStringAsFixed(2)}',
                  'Q', // Letra Q como icono personalizado para Quetzal
                  Colors.green,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<double> _calcularIngresosDinamicos(List<Cita> citasHoy) async {
    try {
      // Obtener fecha de hoy en formato YYYY-MM-DD
      final fechaHoy = DateTime.now().toIso8601String().substring(0, 10);

      // Consultar ingresos registrados en la colección ingresos_diarios
      // Solo contar los que NO han sido transferidos a reportes
      final ingresosSnapshot = await FirebaseFirestore.instance
          .collection('ingresos_diarios')
          .where('fecha', isEqualTo: fechaHoy)
          .where('transferido_a_reporte', isEqualTo: false)
          .get();

      double totalIngresos = 0.0;

      // Sumar ingresos de la colección ingresos_diarios (registros automáticos)
      for (final doc in ingresosSnapshot.docs) {
        final data = doc.data();
        final precio = (data['precio'] as num?)?.toDouble() ?? 0.0;
        totalIngresos += precio;
      }

      // También incluir citas confirmadas que podrían no estar registradas aún
      final citasConfirmadas = citasHoy
          .where((c) => c.estado == EstadoCita.confirmada)
          .toList();

      for (Cita cita in citasConfirmadas) {
        if (cita.precio > 0.0) {
          totalIngresos += cita.precio;
        } else {
          final precioServicio = await Cita.obtenerPrecioServicio(
            cita.servicio,
          );
          totalIngresos += precioServicio;
        }
      }

      return totalIngresos;
    } catch (e) {
      print('Error calculando ingresos dinámicos: $e');
      // Fallback al método anterior si hay error
      double totalIngresos = 0.0;
      final citasCompletadas = citasHoy
          .where(
            (c) =>
                c.estado == EstadoCita.completada ||
                c.estado == EstadoCita.confirmada,
          )
          .toList();

      for (Cita cita in citasCompletadas) {
        if (cita.precio > 0.0) {
          totalIngresos += cita.precio;
        } else {
          final precioServicio = await Cita.obtenerPrecioServicio(
            cita.servicio,
          );
          totalIngresos += precioServicio;
        }
      }

      return totalIngresos;
    }
  }

  Widget _buildStatCard(
    String titulo,
    String valor,
    IconData icono,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icono,
            color: color,
            size: 28,
            shadows: [
              Shadow(color: color, blurRadius: 4, offset: const Offset(0, 0)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              shadows: [
                Shadow(color: color, blurRadius: 2, offset: const Offset(0, 0)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardCustomIcon(
    String titulo,
    String valor,
    String iconText,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Text(
                iconText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                  shadows: [
                    Shadow(
                      color: color,
                      blurRadius: 4,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              shadows: [
                Shadow(color: color, blurRadius: 2, offset: const Offset(0, 0)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFiltroChip('todas', 'Todas'),
            _buildFiltroChip('notificaciones', 'Notificaciones'),
            _buildFiltroChip('pendientes', 'Pendientes'),
            _buildFiltroChip('completadas', 'Completadas'),
            _buildFiltroChip('canceladas', 'Canceladas'),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroChip(String value, String label) {
    final isSelected = _filtroEstado == value;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          setState(() {
            _filtroEstado = value;
          });
        },
        selectedColor: const Color(0xFFD4AF37).withOpacity(0.2),
        checkmarkColor: const Color(0xFFD4AF37),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildCitaCard(Cita cita) {
    Color estadoColor;
    IconData estadoIcon;

    switch (cita.estado) {
      case EstadoCita.pendiente:
        estadoColor = Colors.orange;
        estadoIcon = Icons.schedule;
        break;
      case EstadoCita.confirmada:
        estadoColor = const Color(0xFFD4AF37);
        estadoIcon = Icons.check_circle;
        break;
      case EstadoCita.completada:
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle_outline;
        break;
      case EstadoCita.cancelada:
        estadoColor = Colors.red;
        estadoIcon = Icons.cancel;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      color: const Color(0xFF2a2a2a), // Fondo gris oscuro
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: estadoColor, // Color del borde según el estado
          width: 1, // Borde más delgado
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cita.nombreCliente,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${cita.fecha.day}/${cita.fecha.month}/${cita.fecha.year} - ${cita.hora}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: estadoColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(estadoIcon, color: estadoColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        cita.estado.toString().split('.').last.toUpperCase(),
                        style: TextStyle(
                          color: estadoColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Mostrar el servicio principal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.content_cut,
                    color: Color(0xFFD4AF37),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Servicio: ${cita.servicio}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            FutureBuilder<double>(
              future: Cita.obtenerPrecioServicio(cita.servicio),
              builder: (context, snapshot) {
                final precioMostrar = snapshot.hasData
                    ? snapshot.data!
                    : (cita.precio > 0.0 ? cita.precio : 150.0);

                return Text(
                  'Precio: Q${precioMostrar.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                  ),
                );
              },
            ),
            if (cita.notas.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notas: ${cita.notas}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Botones para citas en Notificaciones (estado pendiente)
                if (cita.estado == EstadoCita.pendiente) ...[
                  ElevatedButton.icon(
                    onPressed: () => _confirmarCita(cita.id),
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text(
                      'Confirmar',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _cancelarCita(cita.id),
                    icon: const Icon(Icons.close, size: 14),
                    label: const Text(
                      'Cancelar',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ],
                // Botones para citas en Pendientes (estado confirmada)
                if (cita.estado == EstadoCita.confirmada) ...[
                  ElevatedButton.icon(
                    onPressed: () => _completarCita(cita.id),
                    icon: const Icon(Icons.done_all, size: 14),
                    label: const Text(
                      'Completar',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _cancelarCita(cita.id),
                    icon: const Icon(Icons.close, size: 14),
                    label: const Text(
                      'Cancelar',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ],
                ElevatedButton.icon(
                  onPressed: () => _verDetallesCita(cita),
                  icon: const Icon(Icons.visibility, size: 14),
                  label: const Text(
                    'Ver Detalles',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Cita> _filtrarCitas(List<Cita> citas) {
    switch (_filtroEstado) {
      case 'notificaciones':
        // Notificaciones: citas recién llegadas (pendientes sin confirmar)
        return citas.where((c) => c.estado == EstadoCita.pendiente).toList();
      case 'pendientes':
        // Pendientes: citas ya confirmadas pero no completadas
        return citas.where((c) => c.estado == EstadoCita.confirmada).toList();
      case 'completadas':
        // Completadas: citas finalizadas
        return citas.where((c) => c.estado == EstadoCita.completada).toList();
      case 'canceladas':
        return citas.where((c) => c.estado == EstadoCita.cancelada).toList();
      case 'todas':
      default:
        // Todas: solo mostrar completadas y canceladas
        return citas
            .where(
              (c) =>
                  c.estado == EstadoCita.completada ||
                  c.estado == EstadoCita.cancelada,
            )
            .toList();
    }
  }

  Future<void> _confirmarCita(String citaId) async {
    try {
      final cita = await _databaseService.obtenerCitaPorId(citaId);
      if (cita != null) {
        final citaActualizada = cita.copyWith(estado: EstadoCita.confirmada);
        await _databaseService.actualizarCita(citaActualizada);

        // Enviar notificación FCM SOLO al cliente (no al admin)
        try {
          await FCMService.enviarNotificacionCliente(
            cita.usuarioId,
            'Cita confirmada',
            'Tu cita para ${cita.servicio} del ${cita.fecha.day}/${cita.fecha.month}/${cita.fecha.year} a las ${cita.hora} ha sido confirmada.',
            {
              'tipo': 'cita_confirmada',
              'citaId': citaId,
              'servicio': cita.servicio,
              'fecha': cita.fecha.toIso8601String(),
              'hora': cita.hora,
            },
          );

          print(
            '✅ Notificación de confirmación enviada al cliente: ${cita.emailCliente}',
          );
        } catch (notificationError) {
          print(
            'Error enviando notificación de confirmación: $notificationError',
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Cita confirmada - Cliente notificado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al confirmar cita: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelarCita(String citaId) async {
    try {
      final cita = await _databaseService.obtenerCitaPorId(citaId);
      if (cita != null) {
        final citaActualizada = cita.copyWith(estado: EstadoCita.cancelada);
        await _databaseService.actualizarCita(citaActualizada);

        // Enviar notificaciones al cliente
        try {
          // Notificación FCM específica de cancelación por barbero
          await FCMService.enviarNotificacionCliente(
            cita.usuarioId,
            'Cita cancelada',
            'Tu cita para ${cita.servicio} del ${cita.fecha.day}/${cita.fecha.month}/${cita.fecha.year} a las ${cita.hora} ha sido cancelada por el barbero.',
            {
              'tipo': 'cita_cancelada',
              'citaId': citaId,
              'servicio': cita.servicio,
              'fecha': cita.fecha.toIso8601String(),
              'hora': cita.hora,
              'motivo': 'Cancelada por el barbero',
            },
          );

          // Email de cancelación con detalles
          final emailEnviado = await EmailService.enviarCancelacionCita(
            emailCliente: cita.emailCliente,
            nombreCliente: cita.nombreCliente,
            nombreServicio: cita.servicio,
            fecha: '${cita.fecha.day}/${cita.fecha.month}/${cita.fecha.year}',
            hora: cita.hora,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  emailEnviado
                      ? '✅ Cita cancelada - Cliente notificado por push y email'
                      : '✅ Cita cancelada - Cliente notificado por push (error en email)',
                ),
                backgroundColor: emailEnviado
                    ? Colors.orange
                    : Colors.deepOrange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } catch (notificationError) {
          print('Error enviando notificaciones: $notificationError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '⚠️ Cita cancelada (error enviando notificaciones)',
                ),
                backgroundColor: Colors.deepOrange,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar cita: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completarCita(String citaId) async {
    try {
      // Verificar si la caja está abierta
      final estadoCaja = await CajaService.escucharEstadoCaja().first;
      if (estadoCaja != EstadoCaja.abierta) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ No se puede completar la cita: La caja está cerrada',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final cita = await _databaseService.obtenerCitaPorId(citaId);
      if (cita != null) {
        final citaActualizada = cita.copyWith(estado: EstadoCita.completada);
        await _databaseService.actualizarCita(citaActualizada);

        // Registrar ingreso en la caja (solo si está abierta)
        await _registrarIngresoCita(cita);

        // Enviar notificación FCM específica de servicio completado
        try {
          await FCMService.enviarNotificacionCliente(
            cita.usuarioId,
            'Servicio completado',
            'Tu servicio ${cita.servicio} ha sido completado. ¡Gracias por visitarnos!',
            {
              'tipo': 'cita_completada',
              'citaId': citaId,
              'servicio': cita.servicio,
              'fecha': cita.fecha.toIso8601String(),
              'hora': cita.hora,
            },
          );
        } catch (notificationError) {
          print(
            'Error enviando notificación de completado: $notificationError',
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '✅ Servicio completado, ingreso registrado y cliente notificado',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al completar cita: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _registrarIngresoCita(Cita cita) async {
    try {
      // Obtener el precio real del servicio
      final precio = cita.precio > 0.0
          ? cita.precio
          : await Cita.obtenerPrecioServicio(cita.servicio);

      // Registrar el ingreso en la colección de ingresos
      await FirebaseFirestore.instance.collection('ingresos_diarios').add({
        'fecha': DateTime.now().toIso8601String().substring(0, 10),
        'citaId': cita.id,
        'servicio': cita.servicio,
        'cliente': cita.nombreCliente,
        'precio': precio,
        'timestamp': FieldValue.serverTimestamp(),
        'hora_completada': DateTime.now().toIso8601String(),
        'transferido_a_reporte':
            false, // Nuevo campo para control de transferencias
      });

      print(
        '💰 Ingreso registrado: Q${precio.toStringAsFixed(2)} - ${cita.servicio}',
      );
    } catch (e) {
      print('Error al registrar ingreso: $e');
    }
  }

  void _verDetallesCita(Cita cita) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Detalles de la Cita',
            style: TextStyle(
              color: const Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetalleRow('Cliente:', cita.nombreCliente),
                _buildDetalleRow('Email:', cita.emailCliente),
                _buildDetalleRow('Teléfono:', cita.telefonoCliente),
                _buildDetalleRow(
                  'Fecha:',
                  '${cita.fecha.day}/${cita.fecha.month}/${cita.fecha.year}',
                ),
                _buildDetalleRow('Hora:', cita.hora),
                _buildDetalleRow('Servicios:', cita.servicios.join(', ')),
                FutureBuilder<double>(
                  future: Cita.obtenerPrecioServicio(cita.servicio),
                  builder: (context, snapshot) {
                    final precioMostrar = snapshot.hasData
                        ? snapshot.data!
                        : (cita.precio > 0.0 ? cita.precio : 150.0);

                    return _buildDetalleRow(
                      'Precio:',
                      'Q${precioMostrar.toStringAsFixed(2)}',
                    );
                  },
                ),
                _buildDetalleRow(
                  'Estado:',
                  cita.estado.toString().split('.').last.toUpperCase(),
                ),
                if (cita.notas.isNotEmpty)
                  _buildDetalleRow('Notas:', cita.notas),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cerrar',
                style: TextStyle(color: const Color(0xFFD4AF37)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertaNuevasCitas() {
    if (!_alertaVisible) return const SizedBox.shrink();

    return StreamBuilder<List<Cita>>(
      stream: _databaseService.obtenerTodasLasCitas(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final citasPendientes = snapshot.data!
            .where((c) => c.estado == EstadoCita.pendiente)
            .toList();

        if (citasPendientes.isEmpty) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withOpacity(0.1),
            border: Border.all(color: const Color(0xFFD4AF37)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.notifications_active,
                color: Color(0xFFD4AF37),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tienes ${citasPendientes.length} cita${citasPendientes.length == 1 ? '' : 's'} pendiente${citasPendientes.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _alertaVisible = false;
                  });
                },
                icon: const Icon(
                  Icons.close,
                  color: Color(0xFFD4AF37),
                  size: 18,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstadoCaja() {
    return StreamBuilder<EstadoCaja>(
      stream: CajaService.escucharEstadoCaja(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final estadoCaja = snapshot.data!;
        final estaAbierta = estadoCaja == EstadoCaja.abierta;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: estaAbierta
                  ? [
                      const Color(0xFFD4AF37).withOpacity(0.1),
                      const Color(0xFFD4AF37).withOpacity(0.05),
                    ]
                  : [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: estaAbierta ? const Color(0xFFD4AF37) : Colors.red,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: (estaAbierta ? const Color(0xFFD4AF37) : Colors.red)
                    .withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: estaAbierta ? const Color(0xFFD4AF37) : Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (estaAbierta ? const Color(0xFFD4AF37) : Colors.red)
                              .withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  estaAbierta ? Icons.store : Icons.store_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado de la Caja',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: estaAbierta
                            ? const Color(0xFFD4AF37)
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      estaAbierta ? 'ABIERTA' : 'CERRADA',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: estaAbierta
                            ? const Color(0xFFD4AF37)
                            : Colors.red,
                        shadows: [
                          Shadow(
                            color:
                                (estaAbierta
                                        ? const Color(0xFFD4AF37)
                                        : Colors.red)
                                    .withOpacity(0.5),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      estaAbierta
                          ? '🕐 Horario: 8:00 AM - 8:14 PM'
                          : '🕐 Abre automáticamente a las 8:00 AM',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: estaAbierta
                        ? () async {
                            await CajaService.cerrarCajaManual();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Caja cerrada manualmente'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        : () async {
                            await CajaService.abrirCajaManual();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Caja abierta manualmente'),
                                backgroundColor: Color(0xFFD4AF37),
                              ),
                            );
                          },
                    icon: Icon(
                      estaAbierta ? Icons.lock : Icons.lock_open,
                      size: 18,
                    ),
                    label: Text(estaAbierta ? 'Cerrar' : 'Abrir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: estaAbierta
                          ? Colors.red
                          : const Color(0xFFD4AF37),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
