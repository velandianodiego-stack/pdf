import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reportes EPS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const CitasReportScreen(),
    );
  }
}

// Modelo de Datos Cita
class Cita {
  final int id;
  final String pacienteNombre;
  final String pacienteDocumento;
  final String medicoNombre;
  final String especialidad;
  final String fecha;
  final String estado;
  final String observaciones;

  Cita({
    required this.id,
    required this.pacienteNombre,
    required this.pacienteDocumento,
    required this.medicoNombre,
    required this.especialidad,
    required this.fecha,
    required this.estado,
    required this.observaciones,
  });

  factory Cita.fromJson(Map<String, dynamic> json) {
    return Cita(
      id: json['id'],
      pacienteNombre: json['paciente_nombre'] ?? '',
      pacienteDocumento: json['paciente_documento'] ?? '',
      medicoNombre: json['medico_nombre'] ?? '',
      especialidad: json['especialidad'] ?? '',
      fecha: json['fecha'] ?? '',
      estado: json['estado'] ?? '',
      observaciones: json['observaciones'] ?? '',
    );
  }
}

class CitasReportScreen extends StatefulWidget {
  const CitasReportScreen({super.key});

  @override
  State<CitasReportScreen> createState() => _CitasReportScreenState();
}

class _CitasReportScreenState extends State<CitasReportScreen> {
  // URL del backend - Para web/Chrome usar localhost
  final String apiUrl = 'http://localhost:3000/api/citas';

  List<Cita> _citas = [];
  List<Cita> _filteredCitas = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String?
  _selectedStatus; // null = Todos, 'Atendida', 'Cancelada', 'No Asistida'
  Uint8List? _logoImage;

  final List<String> _statusOptions = [
    'Todos',
    'Atendida',
    'Cancelada',
    'No Asistida',
  ];

  @override
  void initState() {
    super.initState();
    _loadLogo();
    _fetchCitas();
  }

  // Cargar logo de assets
  Future<void> _loadLogo() async {
    try {
      final imageData = await rootBundle.load('assets/images/logo.png');
      setState(() {
        _logoImage = imageData.buffer.asUint8List();
      });
    } catch (e) {
      // Logo no disponible - se usará placeholder
    }
  }

  // Petición HTTP GET al backend Node.js
  Future<void> _fetchCitas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _citas = data.map((json) => Cita.fromJson(json)).toList();
          _applyFilter();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Error en el servidor: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  // Aplicar filtro de estado
  void _applyFilter() {
    if (_selectedStatus == null || _selectedStatus == 'Todos') {
      _filteredCitas = _citas;
    } else {
      _filteredCitas = _citas
          .where((cita) => cita.estado == _selectedStatus)
          .toList();
    }
  }

  // Cambiar estado seleccionado
  void _onStatusFilterChanged(String? status) {
    setState(() {
      _selectedStatus = status;
      _applyFilter();
    });
  }

  // Función para generar el PDF de un comprobante individual
  Future<Uint8List> _generatePdfComprobante(Cita cita) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Encabezado con logo
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (_logoImage != null)
                      pw.Image(
                        pw.MemoryImage(_logoImage!),
                        height: 60,
                        width: 60,
                      )
                    else
                      pw.Container(
                        height: 60,
                        width: 60,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey400),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'LOGO',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'EPS SALUD TOTAL - COMPROBANTE DE CITA',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.indigo900,
                            ),
                          ),
                          pw.Text(
                            'N° Cita: ${cita.id}',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'INFORMACIÓN DEL PACIENTE',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Divider(),
                pw.Text('Nombre Paciente: ${cita.pacienteNombre}'),
                pw.Text('Documento Identidad: ${cita.pacienteDocumento}'),
                pw.SizedBox(height: 15),
                pw.Text(
                  'DETALLES DE LA ATENCIÓN',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Divider(),
                pw.Text('Médico Tratante: ${cita.medicoNombre}'),
                pw.Text('Especialidad: ${cita.especialidad}'),
                pw.Text('Fecha / Hora: ${cita.fecha}'),
                pw.Text('Estado de la Cita: ${cita.estado}'),
                pw.SizedBox(height: 15),
                pw.Text(
                  'OBSERVACIONES CLÍNICAS',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Divider(),
                pw.Text(
                  cita.observaciones.isNotEmpty
                      ? cita.observaciones
                      : 'Sin observaciones registadas.',
                ),
                pw.Spacer(),
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Documento generado automáticamente por el Sistema de Información EPS',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    return pdf.save();
  }

  // Función para generar un reporte global con tabla de todas las citas (o filtradas)
  Future<Uint8List> _generatePdfReporteGeneral() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.indigo700, width: 2),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Logo en encabezado
                if (_logoImage != null)
                  pw.Image(pw.MemoryImage(_logoImage!), height: 50, width: 50)
                else
                  pw.Container(
                    height: 50,
                    width: 50,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'LOGO',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'REPORTE GENERAL DE CITAS',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                      if (_selectedStatus != null && _selectedStatus != 'Todos')
                        pw.Text(
                          'Estado: $_selectedStatus',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.indigo700,
                          ),
                        ),
                    ],
                  ),
                ),
                pw.Text(
                  'Fecha: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 20),
            padding: const pw.EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 20,
            ),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey400, width: 1),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total de registros: ${_filteredCitas.length}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: [
              'ID',
              'Paciente',
              'Documento',
              'Médico',
              'Especialidad',
              'Fecha',
              'Estado',
            ],
            data: _filteredCitas
                .map(
                  (c) => [
                    c.id.toString(),
                    c.pacienteNombre,
                    c.pacienteDocumento,
                    c.medicoNombre,
                    c.especialidad,
                    c.fecha,
                    c.estado,
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.indigo700,
            ),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 9),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  void _verPdfPreview(
    BuildContext context,
    Future<Uint8List> Function() buildPdf,
    String title,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: PdfPreview(
            build: (format) => buildPdf(),
            allowPrinting: true,
            allowSharing: true,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Citas EPS'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _filteredCitas.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Exportar Reporte PDF',
              onPressed: () {
                _verPdfPreview(
                  context,
                  _generatePdfReporteGeneral,
                  'Reporte de Citas',
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _fetchCitas,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Filtro de estado
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    border: Border(
                      bottom: BorderSide(color: Colors.indigo.shade200),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filtrar por Estado:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _statusOptions.map((status) {
                            final isSelected =
                                (_selectedStatus == null &&
                                    status == 'Todos') ||
                                _selectedStatus == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(status),
                                selected: isSelected,
                                onSelected: (_) {
                                  _onStatusFilterChanged(
                                    status == 'Todos' ? null : status,
                                  );
                                },
                                backgroundColor: Colors.white,
                                selectedColor: Colors.indigo.shade300,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Lista de citas
                Expanded(
                  child: _filteredCitas.isEmpty
                      ? Center(
                          child: Text(
                            'No hay citas con el filtro seleccionado',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredCitas.length,
                          itemBuilder: (context, index) {
                            final cita = _filteredCitas[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: cita.estado == 'Atendida'
                                      ? Colors.green
                                      : cita.estado == 'Cancelada'
                                      ? Colors.red
                                      : Colors.orange,
                                  child: Icon(
                                    cita.estado == 'Atendida'
                                        ? Icons.check_circle
                                        : cita.estado == 'Cancelada'
                                        ? Icons.cancel
                                        : Icons.schedule,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  cita.pacienteNombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${cita.especialidad} - ${cita.medicoNombre}\nFecha: ${cita.fecha} | Estado: ${cita.estado}',
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.print,
                                    color: Colors.indigo,
                                  ),
                                  tooltip: 'Imprimir Comprobante',
                                  onPressed: () {
                                    _verPdfPreview(
                                      context,
                                      () => _generatePdfComprobante(cita),
                                      'Comprobante Cita #${cita.id}',
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
