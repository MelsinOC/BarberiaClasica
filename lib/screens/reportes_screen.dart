import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/citas.dart';
import '../services/database_service.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();

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
          'Reportes y Estadísticas',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de fechas
            _buildDateSelector(),
            const SizedBox(height: 24),

            // Reportes
            StreamBuilder<List<Cita>>(
              stream: _databaseService.obtenerTodasLasCitas(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFD4AF37),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar datos: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final todasLasCitas = snapshot.data ?? [];
                final citasPeriodo = _filtrarCitasPorPeriodo(todasLasCitas);

                return Column(
                  children: [
                    _buildResumenGeneral(citasPeriodo),
                    const SizedBox(height: 24),
                    _buildReportesCierre(),
                    const SizedBox(height: 24),
                    _buildIngresosPorMes(citasPeriodo),
                    const SizedBox(height: 24),
                    _buildServiciosMasPopulares(citasPeriodo),
                    const SizedBox(height: 24),
                    _buildEstadisticasEstados(citasPeriodo),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Período de Análisis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  'Desde: ${DateFormat('dd/MM/yyyy').format(_fechaInicio)}',
                  () => _seleccionarFecha(true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateButton(
                  'Hasta: ${DateFormat('dd/MM/yyyy').format(_fechaFin)}',
                  () => _seleccionarFecha(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3a3a3a),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildResumenGeneral(List<Cita> citas) {
    final totalCitas = citas.length;
    final citasCompletadas = citas
        .where((c) => c.estado == EstadoCita.completada)
        .length;
    final citasCanceladas = citas
        .where((c) => c.estado == EstadoCita.cancelada)
        .length;
    final ingresoTotal = _calcularIngresoTotal(
      citas.where((c) => c.estado == EstadoCita.completada).toList(),
    );

    return _buildReportCard('Resumen General', Icons.analytics, [
      _buildStatRow('Total de Citas', totalCitas.toString()),
      _buildStatRow('Citas Completadas', citasCompletadas.toString()),
      _buildStatRow('Citas Canceladas', citasCanceladas.toString()),
      _buildStatRow(
        'Tasa de Éxito',
        '${totalCitas > 0 ? (citasCompletadas * 100 / totalCitas).toStringAsFixed(1) : 0}%',
      ),
      _buildStatRow('Ingreso Total', 'Q${ingresoTotal.toStringAsFixed(2)}'),
    ]);
  }

  Widget _buildIngresosPorMes(List<Cita> citas) {
    final citasCompletadas = citas
        .where((c) => c.estado == EstadoCita.completada)
        .toList();
    final ingresosPorMes = <String, double>{};

    for (final cita in citasCompletadas) {
      final mes = DateFormat('MM/yyyy').format(cita.fecha);
      ingresosPorMes[mes] =
          (ingresosPorMes[mes] ?? 0) + _obtenerPrecioServicio(cita.servicio);
    }

    final entradas = ingresosPorMes.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return _buildReportCard(
      'Ingresos por Mes',
      Icons.trending_up,
      entradas
          .map(
            (entry) =>
                _buildStatRow(entry.key, 'Q${entry.value.toStringAsFixed(2)}'),
          )
          .toList(),
    );
  }

  Widget _buildReportesCierre() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reportes_cierre')
          .where(
            'fecha',
            isGreaterThanOrEqualTo: DateFormat(
              'yyyy-MM-dd',
            ).format(_fechaInicio),
          )
          .where(
            'fecha',
            isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(_fechaFin),
          )
          .orderBy('fecha', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildReportCard('Cierres de Caja', Icons.point_of_sale, [
            const Text(
              'No hay reportes de cierre en este período',
              style: TextStyle(color: Colors.grey),
            ),
          ]);
        }

        final reportes = snapshot.data!.docs;

        return _buildReportCard(
          'Cierres de Caja Recientes',
          Icons.point_of_sale,
          reportes.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final fecha = data['fecha'] as String? ?? '';
            final totalIngresos =
                (data['total_ingresos'] as num?)?.toDouble() ?? 0.0;
            final totalCitas = data['total_citas'] as int? ?? 0;
            final horaCierre = data['hora_cierre'] as String? ?? '';

            return _buildCierreRow(
              fecha,
              horaCierre,
              totalIngresos,
              totalCitas,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCierreRow(
    String fecha,
    String hora,
    double ingresos,
    int citas,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fecha,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                hora,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$citas citas procesadas',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              Text(
                'Q${ingresos.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiciosMasPopulares(List<Cita> citas) {
    final serviciosCount = <String, int>{};
    final serviciosIngreso = <String, double>{};

    for (final cita in citas) {
      serviciosCount[cita.servicio] = (serviciosCount[cita.servicio] ?? 0) + 1;
      if (cita.estado == EstadoCita.completada) {
        serviciosIngreso[cita.servicio] =
            (serviciosIngreso[cita.servicio] ?? 0) +
            _obtenerPrecioServicio(cita.servicio);
      }
    }

    final serviciosOrdenados = serviciosCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildReportCard(
      'Servicios Más Populares',
      Icons.star,
      serviciosOrdenados
          .take(5)
          .map(
            (entry) => _buildServiceStatRow(
              entry.key,
              '${entry.value} citas',
              'Q${(serviciosIngreso[entry.key] ?? 0).toStringAsFixed(0)}',
            ),
          )
          .toList(),
    );
  }

  Widget _buildEstadisticasEstados(List<Cita> citas) {
    final estadosCount = <EstadoCita, int>{};

    for (final cita in citas) {
      estadosCount[cita.estado] = (estadosCount[cita.estado] ?? 0) + 1;
    }

    return _buildReportCard(
      'Estados de Citas',
      Icons.pie_chart,
      estadosCount.entries
          .map(
            (entry) => _buildStatRow(
              _getEstadoTexto(entry.key),
              entry.value.toString(),
            ),
          )
          .toList(),
    );
  }

  Widget _buildReportCard(
    String titulo,
    IconData icono,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: const Color(0xFFD4AF37)),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
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

  Widget _buildServiceStatRow(String servicio, String citas, String ingreso) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            servicio,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                citas,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              Text(
                ingreso,
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Cita> _filtrarCitasPorPeriodo(List<Cita> citas) {
    return citas.where((cita) {
      return cita.fecha.isAfter(
            _fechaInicio.subtract(const Duration(days: 1)),
          ) &&
          cita.fecha.isBefore(_fechaFin.add(const Duration(days: 1)));
    }).toList();
  }

  double _calcularIngresoTotal(List<Cita> citasCompletadas) {
    return citasCompletadas.fold(
      0.0,
      (suma, cita) => suma + _obtenerPrecioServicio(cita.servicio),
    );
  }

  double _obtenerPrecioServicio(String nombreServicio) {
    // Precios base de los servicios
    const precios = {
      'Corte Clásico': 150.0,
      'Corte + Barba': 250.0,
      'Afeitado Clásico': 180.0,
      'Corte de Niños': 60.0,
      'Corte Moderno': 220.0,
      'Lavado + Peinado': 120.0,
      'Corte + Lavado + Barba': 400.0,
      'Cejas': 80.0,
      'Tratamiento Capilar': 600.0,
      'Corte + Styling': 350.0,
      'Servicio Completo': 400.0,
      'Barba Deluxe': 250.0,
    };
    return precios[nombreServicio] ?? 150.0;
  }

  String _getEstadoTexto(EstadoCita estado) {
    switch (estado) {
      case EstadoCita.pendiente:
        return 'Pendientes';
      case EstadoCita.completada:
        return 'Completadas';
      case EstadoCita.cancelada:
        return 'Canceladas';
      case EstadoCita.confirmada:
        return 'Confirmadas';
    }
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
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

    if (fechaSeleccionada != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fechaSeleccionada;
        } else {
          _fechaFin = fechaSeleccionada;
        }
      });
    }
  }
}
