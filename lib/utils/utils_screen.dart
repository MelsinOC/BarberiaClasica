import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/citas.dart';

class UtilsScreen extends StatefulWidget {
  const UtilsScreen({super.key});

  @override
  State<UtilsScreen> createState() => _UtilsScreenState();
}

class _UtilsScreenState extends State<UtilsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
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
          'Herramientas de Administración',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 22,
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUtilCard(
                    'Limpiar Citas Antiguas',
                    'Eliminar citas canceladas de más de 30 días',
                    Icons.cleaning_services,
                    Colors.orange,
                    () => _limpiarCitasAntiguas(),
                  ),
                  const SizedBox(height: 16),
                  _buildUtilCard(
                    'Actualizar Estados',
                    'Marcar citas pasadas como completadas',
                    Icons.update,
                    Colors.blue,
                    () => _actualizarEstadosCitas(),
                  ),
                  const SizedBox(height: 16),
                  _buildUtilCard(
                    'Backup de Datos',
                    'Exportar información de citas (simulado)',
                    Icons.backup,
                    Colors.green,
                    () => _simularBackup(),
                  ),
                  const SizedBox(height: 16),
                  _buildUtilCard(
                    'Verificar Integridad',
                    'Revisar consistencia de datos',
                    Icons.verified,
                    Colors.purple,
                    () => _verificarIntegridad(),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Estadísticas Rápidas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatsWidget(),
                ],
              ),
            ),
    );
  }

  Widget _buildUtilCard(
    String titulo,
    String descripcion,
    IconData icono,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      descripcion,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Ejecutar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsWidget() {
    return StreamBuilder<List<Cita>>(
      stream: _databaseService.obtenerTodasLasCitas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a2a),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
              ),
            ),
          );
        }

        final citas = snapshot.data ?? [];
        final citasAntiguas = _contarCitasAntiguas(citas);
        final citasPasadas = _contarCitasPasadas(citas);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2a2a2a),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              _buildStatRow('Total de Citas', citas.length.toString()),
              _buildStatRow(
                'Citas Antiguas Canceladas',
                citasAntiguas.toString(),
              ),
              _buildStatRow(
                'Citas Pasadas Pendientes',
                citasPasadas.toString(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: TextStyle(color: Colors.grey[300])),
          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _limpiarCitasAntiguas() async {
    setState(() => _isLoading = true);

    try {
      final citas = await _databaseService.obtenerTodasLasCitas().first;
      final fechaLimite = DateTime.now().subtract(const Duration(days: 30));

      int citasEliminadas = 0;
      for (final cita in citas) {
        if (cita.estado == EstadoCita.cancelada &&
            cita.fecha.isBefore(fechaLimite)) {
          // Aquí eliminarías la cita de la base de datos
          // await _databaseService.eliminarCita(cita.id);
          citasEliminadas++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Limpieza simulada: $citasEliminadas citas antiguas encontradas',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _actualizarEstadosCitas() async {
    setState(() => _isLoading = true);

    try {
      final citas = await _databaseService.obtenerTodasLasCitas().first;
      final ahora = DateTime.now();

      int citasActualizadas = 0;
      for (final cita in citas) {
        final fechaCita = DateTime(
          cita.fecha.year,
          cita.fecha.month,
          cita.fecha.day,
        );

        if (fechaCita.isBefore(ahora) && cita.estado == EstadoCita.pendiente) {
          // Aquí actualizarías el estado de la cita
          citasActualizadas++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Actualización simulada: $citasActualizadas citas pendientes pasadas encontradas',
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _simularBackup() async {
    setState(() => _isLoading = true);

    try {
      // Simular tiempo de backup
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup simulado completado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verificarIntegridad() async {
    setState(() => _isLoading = true);

    try {
      final citas = await _databaseService.obtenerTodasLasCitas().first;

      int problemas = 0;
      for (final cita in citas) {
        // Verificar problemas comunes
        if (cita.nombreCliente.isEmpty ||
            cita.servicio.isEmpty ||
            cita.hora.isEmpty) {
          problemas++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              problemas == 0
                  ? 'Verificación completada: No se encontraron problemas'
                  : 'Verificación completada: $problemas registros con problemas encontrados',
            ),
            backgroundColor: problemas == 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en verificación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int _contarCitasAntiguas(List<Cita> citas) {
    final fechaLimite = DateTime.now().subtract(const Duration(days: 30));
    return citas
        .where(
          (cita) =>
              cita.estado == EstadoCita.cancelada &&
              cita.fecha.isBefore(fechaLimite),
        )
        .length;
  }

  int _contarCitasPasadas(List<Cita> citas) {
    final ahora = DateTime.now();
    return citas
        .where(
          (cita) =>
              cita.estado == EstadoCita.pendiente &&
              DateTime(
                cita.fecha.year,
                cita.fecha.month,
                cita.fecha.day,
              ).isBefore(ahora),
        )
        .length;
  }
}
