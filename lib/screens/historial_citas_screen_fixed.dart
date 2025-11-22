import "package:flutter/material.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "../models/citas.dart";
import "../services/database_service.dart";
import "package:intl/intl.dart";

class HistorialCitasScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1a1a1a),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2a2a2a),
          elevation: 0,
          title: const Text(
            'Historial de Citas',
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
              Icon(Icons.person_off, size: 100, color: Colors.grey[600]),
              SizedBox(height: 30),
              Text(
                "Necesitas iniciar sesión\npara ver tu historial de citas",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[400]),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
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
                  "Iniciar Sesión",
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
        title: const Text(
          'Historial de Citas',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: HistorialContentWidget(userId: user.uid),
    );
  }
}

class HistorialContentWidget extends StatefulWidget {
  final String userId;

  const HistorialContentWidget({Key? key, required this.userId})
    : super(key: key);

  @override
  _HistorialContentWidgetState createState() => _HistorialContentWidgetState();
}

class _HistorialContentWidgetState extends State<HistorialContentWidget> {
  List<Cita> _citas = [];
  bool _isLoading = true;
  String? _error;
  String _debugInfo = 'Iniciando...';

  @override
  void initState() {
    super.initState();
    _cargarCitasDirecto();
  }

  Future<void> _cargarCitasDirecto() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _debugInfo = 'Conectando a Firebase...';
    });

    try {
      print('🔍 CARGANDO citas para usuario: ${widget.userId}');

      // Consulta directa a Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('citas')
          .get();

      setState(() {
        _debugInfo = 'Documentos encontrados: ${querySnapshot.docs.length}';
      });

      print('📊 Total documentos en colección: ${querySnapshot.docs.length}');

      List<Cita> citasDelUsuario = [];

      // Procesar cada documento
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          print(
            '🔍 Doc ${doc.id}: usuarioId="${data['usuarioId']}", userId="${data['userId']}"',
          );

          // Verificar si pertenece al usuario
          bool esDelUsuario =
              data['usuarioId'] == widget.userId ||
              data['userId'] == widget.userId;

          if (esDelUsuario) {
            final cita = Cita.fromMap(data, doc.id);
            citasDelUsuario.add(cita);
            print('✅ Cita agregada: ${cita.servicio}');
          }
        } catch (e) {
          print('❌ Error procesando doc ${doc.id}: $e');
        }
      }

      setState(() {
        _citas = citasDelUsuario..sort((a, b) => b.fecha.compareTo(a.fecha));
        _isLoading = false;
        _debugInfo =
            'Encontradas: ${_citas.length} citas de ${querySnapshot.docs.length} total';
      });

      print('🎯 RESULTADO FINAL: ${_citas.length} citas para ${widget.userId}');
    } catch (e) {
      print('❌ ERROR: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _debugInfo = 'Error de conexión: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fondo negro fijo para evitar el gris
    return Container(color: Colors.black, child: _buildContent());
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFD4AF37)),
            SizedBox(height: 20),
            Text(
              'Cargando historial...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              _debugInfo,
              style: TextStyle(color: Color(0xFFD4AF37), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red),
            SizedBox(height: 20),
            Text(
              'Error de conexión',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              _debugInfo,
              style: TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _cargarCitasDirecto,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
              child: Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_citas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 100, color: Color(0xFFD4AF37)),
            SizedBox(height: 30),
            Text(
              'No tienes citas registradas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/servicios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                "Agendar Nueva Cita",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Lista de citas
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: _citas.length,
            separatorBuilder: (context, index) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              final cita = _citas[index];
              return _buildCitaCard(cita);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCitaCard(Cita cita) {
    Color estadoColor;
    IconData estadoIcon;
    String estadoTexto;

    switch (cita.estado) {
      case EstadoCita.pendiente:
        estadoColor = Colors.orange;
        estadoIcon = Icons.access_time;
        estadoTexto = "PENDIENTE";
        break;
      case EstadoCita.confirmada:
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle;
        estadoTexto = "CONFIRMADA";
        break;
      case EstadoCita.completada:
        estadoColor = Colors.blue;
        estadoIcon = Icons.done_all;
        estadoTexto = "COMPLETADA";
        break;
      case EstadoCita.cancelada:
        estadoColor = Colors.red;
        estadoIcon = Icons.cancel;
        estadoTexto = "CANCELADA";
        break;
    }

    return Card(
      elevation: 8,
      color: const Color(0xFF2a2a2a),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: estadoColor.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    cita.servicio,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: estadoColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(estadoIcon, color: estadoColor, size: 16),
                      SizedBox(width: 4),
                      Text(
                        estadoTexto,
                        style: TextStyle(
                          color: estadoColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[400], size: 16),
                SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy').format(cita.fecha),
                  style: TextStyle(color: Colors.grey[300], fontSize: 14),
                ),
                SizedBox(width: 20),
                Icon(Icons.access_time, color: Colors.grey[400], size: 16),
                SizedBox(width: 8),
                Text(
                  cita.hora,
                  style: TextStyle(color: Colors.grey[300], fontSize: 14),
                ),
              ],
            ),
            if (cita.notas.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.note, color: Color(0xFFD4AF37), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Notas:',
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      cita.notas,
                      style: TextStyle(color: Colors.grey[300], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (cita.estado == EstadoCita.pendiente) ...[
                  TextButton.icon(
                    onPressed: () => _cancelarCita(cita.id),
                    icon: Icon(Icons.cancel, color: Colors.red, size: 18),
                    label: Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                ],
                TextButton.icon(
                  onPressed: () => _mostrarDetalles(cita),
                  icon: Icon(Icons.info, color: Color(0xFFD4AF37), size: 18),
                  label: Text(
                    'Detalles',
                    style: TextStyle(color: Color(0xFFD4AF37), fontSize: 14),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _cancelarCita(String citaId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2a2a2a),
          title: Text(
            '¿Cancelar Cita?',
            style: TextStyle(color: Color(0xFFD4AF37)),
          ),
          content: Text(
            'Esta acción no se puede deshacer.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('No', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await DatabaseService().cancelarCita(citaId);
                  _cargarCitasDirecto(); // Recargar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cita cancelada correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al cancelar la cita'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Sí, Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDetalles(Cita cita) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2a2a2a),
          title: Text(
            'Detalles de la Cita',
            style: TextStyle(color: Color(0xFFD4AF37)),
          ),
          content: FutureBuilder<double>(
            future: Cita.obtenerPrecioServicio(cita.servicio),
            builder: (context, snapshot) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetalle('Servicio:', cita.servicio),
                  _buildDetalle(
                    'Fecha:',
                    DateFormat('dd/MM/yyyy').format(cita.fecha),
                  ),
                  _buildDetalle('Hora:', cita.hora),
                  if (snapshot.hasData)
                    _buildDetalle(
                      'Precio:',
                      'Q${snapshot.data!.toStringAsFixed(2)}',
                    )
                  else
                    _buildDetalle('Precio:', 'Cargando...'),
                  if (cita.notas.isNotEmpty)
                    _buildDetalle('Notas:', cita.notas),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar', style: TextStyle(color: Color(0xFFD4AF37))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetalle(String label, String valor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
