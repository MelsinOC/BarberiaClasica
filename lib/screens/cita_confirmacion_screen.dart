import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/models/servicios.dart';
import 'package:flutter_application_1/models/citas.dart';
import 'package:flutter_application_1/services/database_service.dart';
import 'package:flutter_application_1/services/notification_service.dart';
import 'package:flutter_application_1/services/email_service.dart';
import 'package:flutter_application_1/utils/imagen_utils.dart';
import '../widgets/animated_widgets.dart';

class CitaConfirmacionScreen extends StatefulWidget {
  final Servicio servicio;
  final Cita? citaExistente; // Para editar citas existentes

  const CitaConfirmacionScreen({
    super.key,
    required this.servicio,
    this.citaExistente,
  });

  @override
  State<CitaConfirmacionScreen> createState() => _CitaConfirmacionScreenState();
}

class _CitaConfirmacionScreenState extends State<CitaConfirmacionScreen> {
  final DatabaseService _databaseService = DatabaseService();

  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  bool _isLoading = false;

  final _observacionesController = TextEditingController();

  // Controladores para datos del cliente
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _inicializarDatosUsuario();
    _cargarDatosCitaExistente();
  }

  void _cargarDatosCitaExistente() {
    if (widget.citaExistente != null) {
      setState(() {
        _fechaSeleccionada = DateTime(
          widget.citaExistente!.fecha.year,
          widget.citaExistente!.fecha.month,
          widget.citaExistente!.fecha.day,
        );
        // Parse hora string to TimeOfDay
        final horaPartes = widget.citaExistente!.hora.split(':');
        _horaSeleccionada = TimeOfDay(
          hour: int.parse(horaPartes[0]),
          minute: int.parse(horaPartes[1]),
        );
        _observacionesController.text = widget.citaExistente!.notas;
      });
    }
  }

  Future<void> _inicializarDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final usuario = await _databaseService.obtenerUsuario(user.uid);
        if (usuario != null) {
          // Concatenar nombre y apellido
          _nombreController.text = '${usuario.nombre} ${usuario.apellido}';
          _telefonoController.text = usuario.telefono;
          _emailController.text = usuario.email;
        } else {
          // Si no hay datos del usuario, usar email de Firebase
          _emailController.text = user.email ?? '';
        }
      } catch (e) {
        print('Error al cargar datos del usuario: $e');
        // Usar email de Firebase como fallback
        _emailController.text = user.email ?? '';
      }
    }
  }

  Future<void> _confirmarCita() async {
    // 🔒 VALIDAR QUE EL USUARIO ESTÉ AUTENTICADO
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _mostrarNotificacionPersonalizada(
        context,
        mensaje:
            'Debes iniciar sesión para poder agendar una cita.\n\nPor favor inicia sesión con tu cuenta.',
        tipo: TipoNotificacion.advertencia,
      );
      return;
    }

    if (_fechaSeleccionada == null || _horaSeleccionada == null) {
      _mostrarNotificacionPersonalizada(
        context,
        mensaje: 'Por favor selecciona fecha y hora',
        tipo: TipoNotificacion.advertencia,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String usuarioId = user.uid;

      // Combinar fecha y hora
      final fechaHora = DateTime(
        _fechaSeleccionada!.year,
        _fechaSeleccionada!.month,
        _fechaSeleccionada!.day,
        _horaSeleccionada!.hour,
        _horaSeleccionada!.minute,
      );

      // 🔒 VALIDAR DISPONIBILIDAD DEL HORARIO (solo si no es la misma cita)
      if (widget.citaExistente == null ||
          _fechaSeleccionada != widget.citaExistente!.fecha ||
          _formatearHora(_horaSeleccionada!) != widget.citaExistente!.hora) {
        // Comparación temporal simplificada
        bool estaDisponible = await _databaseService.estaDisponible(
          fechaHora,
          widget.servicio.duracionMinutos,
        );

        if (!estaDisponible) {
          setState(() => _isLoading = false);
          if (mounted) {
            _mostrarNotificacionPersonalizada(
              context,
              mensaje:
                  'Lo siento, este horario ya fue reservado por otro cliente.\n\nPor favor selecciona otra hora disponible.',
              tipo: TipoNotificacion.advertencia,
            );
          }
          return;
        }
      }

      if (widget.citaExistente != null) {
        // ACTUALIZAR cita existente
        final citaActualizada = Cita(
          id: widget.citaExistente!.id,
          usuarioId: widget.citaExistente!.usuarioId,
          servicio: widget.servicio.nombre,
          fecha: _fechaSeleccionada!,
          hora: _formatearHora(_horaSeleccionada!), // Usar hora seleccionada
          estado: widget.citaExistente!.estado,
          notas: _observacionesController.text.trim(),
          fechaCreacion: widget.citaExistente!.fechaCreacion,
          nombreCliente: _nombreController.text.trim(),
          telefonoCliente: _telefonoController.text.trim(),
          emailCliente: _emailController.text.trim(),
        );

        String? resultado = await _databaseService.actualizarCita(
          citaActualizada,
        );

        if (resultado == null && mounted) {
          // Mostrar notificación local
          await NotificationService.mostrarNotificacionConfirmacion(
            nombreServicio: widget.servicio.nombre,
            fecha: _formatearFecha(_fechaSeleccionada!),
            hora: _formatearHora(_horaSeleccionada!),
          );

          // Enviar email de confirmación si el email no está vacío
          if (_emailController.text.trim().isNotEmpty) {
            await EmailService.enviarConfirmacionCita(
              emailCliente: _emailController.text.trim(),
              nombreCliente: _nombreController.text.trim(),
              nombreServicio: widget.servicio.nombre,
              fecha: _formatearFecha(_fechaSeleccionada!),
              hora: _formatearHora(_horaSeleccionada!),
              precio: widget.servicio.precio,
            );
          }

          _mostrarNotificacionPersonalizada(
            context,
            mensaje:
                'Tu cita ha sido actualizada exitosamente.\n\n¡Nos vemos pronto en Barbería Clásica!',
            tipo: TipoNotificacion.exito,
          );
          // Esperar un poco antes de cerrar para que se vea la notificación
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) Navigator.of(context).pop(true);
          });
        }
      } else {
        // CREAR nueva cita
        final cita = Cita(
          id: '',
          usuarioId: usuarioId,
          servicio: widget.servicio.nombre,
          fecha: _fechaSeleccionada!,
          hora: _formatearHora(_horaSeleccionada!), // Usar hora seleccionada
          estado: EstadoCita.pendiente,
          notas: _observacionesController.text.trim(),
          fechaCreacion: DateTime.now(),
          nombreCliente: _nombreController.text.trim(),
          telefonoCliente: _telefonoController.text.trim(),
          emailCliente: _emailController.text.trim(),
        );

        await _databaseService.crearCita(cita);

        if (mounted) {
          // Mostrar notificación local de solicitud enviada (NO de confirmación)
          await NotificationService.mostrarNotificacionPersonalizada(
            titulo: '📋 Solicitud Enviada',
            mensaje:
                'Tu solicitud de ${widget.servicio.nombre} para el ${_formatearFecha(_fechaSeleccionada!)} a las ${_formatearHora(_horaSeleccionada!)} ha sido enviada. El barbero la revisará y confirmará pronto.',
          );

          // NO programar recordatorio hasta que esté confirmada
          // El recordatorio se programará cuando el barbero confirme

          // NO enviar email de confirmación, solo de solicitud recibida
          if (_emailController.text.trim().isNotEmpty) {
            // Email de solicitud recibida (no de confirmación)
            // Este email se enviará cuando el barbero confirme la cita
          }

          Navigator.of(context).pop();
          _mostrarNotificacionPersonalizada(
            context,
            mensaje:
                'Tu solicitud se genero exitosamente.\n\nGracias por preferir. \nBARBERIA CLASICA.',
            tipo: TipoNotificacion.exito,
          );

          // Esperar un poco antes de cerrar para que se vea la notificación
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) Navigator.of(context).pop();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _mostrarNotificacionPersonalizada(
          context,
          mensaje:
              'Cita solicitada correctamente.\n\n'
              'Se le notificará cuando sea confirmada.\n\n'
              'Gracias por elegir Barbería Clásica.',
          tipo: TipoNotificacion.exito,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    try {
      final DateTime? fechaElegida = await showDatePicker(
        context: context,
        initialDate:
            _fechaSeleccionada ?? DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFD4AF37),
                onPrimary: Colors.black,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (fechaElegida != null) {
        setState(() {
          _fechaSeleccionada = fechaElegida;
          _horaSeleccionada = null; // Reset hora cuando cambia la fecha
        });
      }
    } catch (e) {
      print('Error al seleccionar fecha: $e');
      // Mostrar selector alternativo simple
      _mostrarSelectorFechaAlternativo();
    }
  }

  void _mostrarSelectorFechaAlternativo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        title: const Text(
          'Seleccionar Fecha',
          style: TextStyle(color: Color(0xFFD4AF37)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selecciona una fecha para tu cita:',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            // Lista de fechas disponibles
            for (int i = 1; i <= 7; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  onPressed: () {
                    final fecha = DateTime.now().add(Duration(days: i));
                    setState(() {
                      _fechaSeleccionada = fecha;
                      _horaSeleccionada = null;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    '${_formatearFecha(DateTime.now().add(Duration(days: i)))}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final dias = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
    ];
    final meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    return '${dias[fecha.weekday % 7]} ${fecha.day} de ${meses[fecha.month - 1]}';
  }

  String _formatearHora(TimeOfDay hora) {
    final int hour12 = hora.hour == 0
        ? 12
        : (hora.hour > 12 ? hora.hour - 12 : hora.hour);
    final String period = hora.hour < 12 ? 'AM' : 'PM';
    return '${hour12.toString()}:${hora.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _seleccionarHora() async {
    if (_fechaSeleccionada == null) {
      _mostrarNotificacionPersonalizada(
        context,
        mensaje:
            'Primero selecciona una fecha para poder elegir el horario disponible.',
        tipo: TipoNotificacion.info,
      );
      return;
    }

    final TimeOfDay? horaElegida = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) => _SelectorHorarios(
        fechaSeleccionada: _fechaSeleccionada!,
        databaseService: _databaseService,
        duracionServicio: widget.servicio.duracionMinutos,
      ),
    );

    if (horaElegida != null) {
      setState(() {
        _horaSeleccionada = horaElegida;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esEdicion = widget.citaExistente != null;

    // 🔒 VALIDAR USUARIO AUTENTICADO
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1a1a1a),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2a2a2a),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFFD4AF37),
              size: 28,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Acceso Restringido',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Color(0xFFD4AF37)),
              SizedBox(height: 20),
              Text(
                "Inicia Sesión para Agendar",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "Debes tener una cuenta registrada para poder agendar citas en nuestra barbería",
                  style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  "Regresar",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2a2a2a),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFFD4AF37),
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          esEdicion ? 'Modificar Cita' : 'Solicitar Cita',
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del servicio
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ), // Bordes redondeados solo abajo
                  border: const Border(
                    bottom: BorderSide(color: Color(0xFFD4AF37), width: 3),
                    left: BorderSide(color: Color(0xFFD4AF37), width: 2),
                    right: BorderSide(color: Color(0xFFD4AF37), width: 2),
                  ), // Borde dorado solo en inferior y laterales
                  image: DecorationImage(
                    image: NetworkImage(
                      ImagenUtils.getImagenServicio(widget.servicio.nombre),
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ), // Un poco menor para que se vea el borde
                    color: const Color(
                      0xFF2a2a2a,
                    ).withOpacity(0.85), // Overlay oscuro semitransparente
                  ),
                  padding: const EdgeInsets.all(
                    25,
                  ), // Padding para el contenido
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFD4AF37).withOpacity(0.3),
                            ),
                            child: const Icon(
                              Icons.content_cut,
                              color: Color(0xFFD4AF37),
                              size: 25,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.servicio.nombre,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  widget.servicio.descripcion,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Q${widget.servicio.precio.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.servicio.duracionMinutos} minutos',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // El resto del contenido con padding lateral
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Datos del cliente (solo lectura)
                    const Text(
                      'Datos del Cliente',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Nombre completo (solo lectura)
                    TextFormField(
                      controller: _nombreController,
                      enabled: false,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nombre Completo',
                        labelStyle: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                        ),
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Color(0xFFD4AF37),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2a2a2a),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Teléfono (solo lectura)
                    TextFormField(
                      controller: _telefonoController,
                      enabled: false,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Teléfono',
                        labelStyle: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                        ),
                        prefixIcon: const Icon(
                          Icons.phone,
                          color: Color(0xFFD4AF37),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2a2a2a),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Email (solo lectura)
                    TextFormField(
                      controller: _emailController,
                      enabled: false,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                        ),
                        prefixIcon: const Icon(
                          Icons.email,
                          color: Color(0xFFD4AF37),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2a2a2a),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Selección de fecha y hora
                    const Text(
                      'Fecha y Hora',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _seleccionarFecha,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _fechaSeleccionada == null
                                  ? 'Seleccionar Fecha'
                                  : 'Fecha: ${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2a2a2a),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFD4AF37)),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _seleccionarHora,
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              _horaSeleccionada == null
                                  ? 'Seleccionar Hora'
                                  : 'Hora: ${_horaSeleccionada!.format(context)}',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2a2a2a),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFD4AF37)),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Observaciones/Notas
                    const Text(
                      'Notas Adicionales (Opcional)',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: _observacionesController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Comentarios especiales para tu cita...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2a2a2a),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Botón de confirmación
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedButton(
                        onPressed: _isLoading ? null : _confirmarCita,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFD4AF37,
                                ).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black,
                                    ),
                                  )
                                : Text(
                                    esEdicion
                                        ? 'ACTUALIZAR CITA'
                                        : 'SOLICITAR CITA',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ), // Cierre del Padding
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Método para mostrar notificaciones personalizadas con branding de barbería
  void _mostrarNotificacionPersonalizada(
    BuildContext context, {
    required String mensaje,
    required TipoNotificacion tipo,
  }) {
    Color colorPrincipal;
    IconData icono;
    String titulo;

    switch (tipo) {
      case TipoNotificacion.exito:
        colorPrincipal = Color(0xFFD4AF37);
        icono = Icons.check_circle;
        titulo = "¡Perfecto!";
        break;
      case TipoNotificacion.error:
        colorPrincipal = Color(0xFFD4AF37);
        icono = Icons.check_circle;
        titulo = "¡Perfecto!";
        break;
      case TipoNotificacion.advertencia:
        colorPrincipal = Color(0xFFD4AF37);
        icono = Icons.warning;
        titulo = "Atención";
        break;
      case TipoNotificacion.info:
        colorPrincipal = Color(0xFFD4AF37);
        icono = Icons.info;
        titulo = "Información";
        break;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorPrincipal, width: 2),
              boxShadow: [
                BoxShadow(
                  color: colorPrincipal.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo/Icono de la barbería
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colorPrincipal,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    icono,
                    color:
                        tipo == TipoNotificacion.exito ||
                            tipo == TipoNotificacion.info
                        ? Colors.black
                        : Colors.white,
                    size: 30,
                  ),
                ),

                SizedBox(height: 20),

                // Nombre de la barbería
                Text(
                  "BARBERÍA CLÁSICA",
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),

                SizedBox(height: 15),

                // Título del mensaje
                Text(
                  titulo,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 10),

                // Mensaje
                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),

                SizedBox(height: 25),

                // Botón de cerrar
                Container(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrincipal,
                      foregroundColor:
                          tipo == TipoNotificacion.exito ||
                              tipo == TipoNotificacion.info
                          ? Colors.black
                          : Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Entendido",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum TipoNotificacion { exito, error, advertencia, info }

// Widget para seleccionar horarios disponibles
class _SelectorHorarios extends StatefulWidget {
  final DateTime fechaSeleccionada;
  final DatabaseService databaseService;
  final int duracionServicio;

  const _SelectorHorarios({
    required this.fechaSeleccionada,
    required this.databaseService,
    required this.duracionServicio,
  });

  @override
  State<_SelectorHorarios> createState() => _SelectorHorariosState();
}

class _SelectorHorariosState extends State<_SelectorHorarios> {
  List<TimeOfDay> horariosOcupados = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarHorariosOcupados();
  }

  Future<void> _cargarHorariosOcupados() async {
    try {
      final horarios = await widget.databaseService.obtenerHorariosOcupados(
        widget.fechaSeleccionada,
      );
      setState(() {
        horariosOcupados = horarios;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  bool _estaOcupado(TimeOfDay horario) {
    return horariosOcupados.any(
      (ocupado) =>
          ocupado.hour == horario.hour && ocupado.minute == horario.minute,
    );
  }

  List<TimeOfDay> _generarHorariosTrabajo() {
    List<TimeOfDay> horarios = [];

    // Horarios de trabajo: 8:00 AM a 8:00 PM
    for (int hora = 8; hora < 20; hora++) {
      for (int minuto = 0; minuto < 60; minuto += 30) {
        horarios.add(TimeOfDay(hour: hora, minute: minuto));
      }
    }

    return horarios;
  }

  String _formatearHora(TimeOfDay hora) {
    final int hour12 = hora.hour == 0
        ? 12
        : (hora.hour > 12 ? hora.hour - 12 : hora.hour);
    final String period = hora.hour < 12 ? 'AM' : 'PM';
    return '${hour12.toString()}:${hora.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2a2a2a),
      title: const Text(
        'Seleccionar Horario',
        style: TextStyle(color: Color(0xFFD4AF37)),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 480, // Aumentado para incluir la leyenda
        child: Column(
          children: [
            // Leyenda de colores
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(0xFFD4AF37).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(0xFF3a3a3a),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: Color(0xFFD4AF37).withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Disponible',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: Colors.red, width: 1),
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Ocupado',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 15),

            // Grid de horarios
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD4AF37),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: _generarHorariosTrabajo().length,
                      itemBuilder: (context, index) {
                        final horario = _generarHorariosTrabajo()[index];
                        final estaOcupado = _estaOcupado(horario);

                        return AnimatedButton(
                          onPressed: estaOcupado
                              ? () {
                                  // Mostrar mensaje cuando toca un horario ocupado
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(
                                            Icons.info,
                                            color: Colors.orange,
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Este horario ya está reservado por otro cliente',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Color(0xFF2A2A2A),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      margin: EdgeInsets.all(10),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              : () {
                                  Navigator.of(context).pop(horario);
                                },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: estaOcupado
                                  ? Colors.red.withValues(alpha: 0.4)
                                  : const Color(0xFF3a3a3a),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: estaOcupado
                                    ? Colors.red
                                    : const Color(
                                        0xFFD4AF37,
                                      ).withValues(alpha: 0.5),
                                width: estaOcupado ? 2 : 1,
                              ),
                              boxShadow: estaOcupado
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Color(
                                          0xFFD4AF37,
                                        ).withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  estaOcupado ? Icons.block : Icons.access_time,
                                  color: estaOcupado
                                      ? Colors.red
                                      : const Color(0xFFD4AF37),
                                  size: estaOcupado ? 18 : 16,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatearHora(horario),
                                  style: TextStyle(
                                    color: estaOcupado
                                        ? Colors.red
                                        : Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
