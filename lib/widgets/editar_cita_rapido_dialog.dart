import 'package:flutter/material.dart';
import '../models/citas.dart';
import '../models/servicios.dart';
import '../services/database_service.dart';

class EditarCitaRapidoDialog extends StatefulWidget {
  final Cita cita;
  final Servicio servicio;

  const EditarCitaRapidoDialog({
    super.key,
    required this.cita,
    required this.servicio,
  });

  @override
  State<EditarCitaRapidoDialog> createState() => _EditarCitaRapidoDialogState();
}

class _EditarCitaRapidoDialogState extends State<EditarCitaRapidoDialog> {
  final DatabaseService _databaseService = DatabaseService();

  DateTime? _nuevaFecha;
  TimeOfDay? _nuevaHora;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nuevaFecha = widget.cita.fecha;
    // Parsear la hora actual
    final horaPartes = widget.cita.hora.split(':');
    _nuevaHora = TimeOfDay(
      hour: int.parse(horaPartes[0]),
      minute: int.parse(horaPartes[1]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2a2a2a),
      title: const Text(
        'Editar Fecha y Hora',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Información del servicio
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3a3a3a),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.cut, color: const Color(0xFFD4AF37)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.servicio.nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: const Color(0xFFD4AF37),
                        size: 16,
                      ),
                      Text(
                        'Q${widget.servicio.precio.toStringAsFixed(0)}',
                        style: TextStyle(color: Colors.grey[300], fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        color: const Color(0xFFD4AF37),
                        size: 16,
                      ),
                      Text(
                        '${widget.servicio.duracionMinutos} min',
                        style: TextStyle(color: Colors.grey[300], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Selector de fecha
            _buildDateSelector(),
            const SizedBox(height: 16),

            // Selector de hora
            _buildTimeSelector(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: TextStyle(color: Colors.grey[400])),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _guardarCambios,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
            foregroundColor: Colors.black,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3a3a3a),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: Color(0xFFD4AF37)),
        title: const Text(
          'Fecha de la cita',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        subtitle: Text(
          _nuevaFecha != null
              ? '${_nuevaFecha!.day}/${_nuevaFecha!.month}/${_nuevaFecha!.year}'
              : 'Seleccionar fecha',
          style: TextStyle(color: Colors.grey[300]),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 16,
        ),
        onTap: _seleccionarFecha,
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3a3a3a),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: ListTile(
        leading: const Icon(Icons.access_time, color: Color(0xFFD4AF37)),
        title: const Text(
          'Hora de la cita',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        subtitle: Text(
          _nuevaHora != null ? _formatearHora(_nuevaHora!) : 'Seleccionar hora',
          style: TextStyle(color: Colors.grey[300]),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 16,
        ),
        onTap: _seleccionarHora,
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _nuevaFecha ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD4AF37),
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _nuevaFecha = fechaSeleccionada;
      });
    }
  }

  Future<void> _seleccionarHora() async {
    final horaSeleccionada = await showTimePicker(
      context: context,
      initialTime: _nuevaHora ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD4AF37),
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (horaSeleccionada != null) {
      setState(() {
        _nuevaHora = horaSeleccionada;
      });
    }
  }

  String _formatearHora(TimeOfDay hora) {
    return '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _guardarCambios() async {
    if (_nuevaFecha == null || _nuevaHora == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona fecha y hora'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verificar disponibilidad del nuevo horario
      final nuevaFechaHora = DateTime(
        _nuevaFecha!.year,
        _nuevaFecha!.month,
        _nuevaFecha!.day,
        _nuevaHora!.hour,
        _nuevaHora!.minute,
      );

      final estaDisponible = await _databaseService.estaDisponible(
        nuevaFechaHora,
        widget.servicio.duracionMinutos,
      );

      if (!estaDisponible) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Lo siento, ese horario ya está ocupado. Por favor selecciona otro.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Crear cita actualizada
      final citaActualizada = Cita(
        id: widget.cita.id,
        usuarioId: widget.cita.usuarioId,
        servicio: widget.cita.servicio,
        fecha: _nuevaFecha!,
        hora: _formatearHora(_nuevaHora!),
        estado: widget.cita.estado,
        notas: widget.cita.notas,
        fechaCreacion: widget.cita.fechaCreacion,
        nombreCliente: widget.cita.nombreCliente,
        telefonoCliente: widget.cita.telefonoCliente,
        emailCliente: widget.cita.emailCliente,
      );

      // Actualizar en la base de datos
      final resultado = await _databaseService.actualizarCita(citaActualizada);

      if (resultado == null && mounted) {
        Navigator.of(context).pop(true); // Retornar true para indicar éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita actualizada exitosamente'),
            backgroundColor: Color(0xFFD4AF37),
            duration: Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $resultado'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
