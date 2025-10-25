import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Escáner de Códigos de Barras',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BarcodeScannerPage(),
    );
  }
}

class BarcodeItem {
  final String code;
  final DateTime timestamp;
  final String type;

  BarcodeItem({
    required this.code,
    required this.timestamp,
    required this.type,
  });
}

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final List<BarcodeItem> _scannedBarcodes = [];
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = false;

  void _onBarcodeDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final code = barcode.rawValue!;

        // Evitar duplicados consecutivos
        if (_scannedBarcodes.isEmpty || _scannedBarcodes.last.code != code) {
          setState(() {
            _scannedBarcodes.add(
              BarcodeItem(
                code: code,
                timestamp: DateTime.now(),
                type: barcode.format.name,
              ),
            );
          });
        }
      }
    }
  }

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
    });
  }

  void _clearBarcodes() {
    setState(() {
      _scannedBarcodes.clear();
    });
  }

  String _convertToCSV(List<List<dynamic>> rows) {
    return rows.map((row) {
      return row.map((cell) {
        // Escapar comillas dobles y envolver en comillas si contiene comas o saltos de línea
        String cellStr = cell.toString();
        if (cellStr.contains(',') || cellStr.contains('"') || cellStr.contains('\n')) {
          cellStr = '"${cellStr.replaceAll('"', '""')}"';
        }
        return cellStr;
      }).join(',');
    }).join('\n');
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exportar códigos'),
          content: const Text('Selecciona el formato de exportación:'),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.description),
              label: const Text('CSV'),
              onPressed: () {
                Navigator.of(context).pop();
                _exportAsCSV();
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.table_chart),
              label: const Text('XLSX (Excel)'),
              onPressed: () {
                Navigator.of(context).pop();
                _exportAsXLSX();
              },
            ),
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportAsCSV() async {
    print('🔍 Iniciando exportación CSV...');
    
    if (_scannedBarcodes.isEmpty) {
      print('⚠️ No hay códigos para exportar');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay códigos para exportar'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    print('✅ Códigos a exportar: ${_scannedBarcodes.length}');

    try {
      // Preparar los datos para el CSV
      List<List<dynamic>> rows = [
        ['#', 'Código', 'Tipo', 'Fecha', 'Hora'],
      ];

      for (int i = 0; i < _scannedBarcodes.length; i++) {
        final item = _scannedBarcodes[i];
        rows.add([
          i + 1,
          item.code,
          item.type,
          '${item.timestamp.day}/${item.timestamp.month}/${item.timestamp.year}',
          '${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}:${item.timestamp.second.toString().padLeft(2, '0')}',
        ]);
      }

      print('📊 Datos preparados, convirtiendo a CSV...');

      // Convertir a CSV manualmente
      String csv = _convertToCSV(rows);
      print('✅ CSV generado: ${csv.length} caracteres');

      // Obtener el directorio temporal
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/codigos_barras_${DateTime.now().millisecondsSinceEpoch}.csv';

      print('📁 Guardando en: $path');

      // Crear el archivo
      final file = File(path);
      await file.writeAsString(csv);

      print('✅ Archivo guardado, compartiendo...');

      // Compartir el archivo
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Códigos de barras escaneados',
        text: 'Lista de ${_scannedBarcodes.length} códigos escaneados',
      );

      print('✅ Compartido exitosamente');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Archivo CSV exportado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ ERROR al exportar: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar CSV: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _exportAsXLSX() async {
    print('🔍 Iniciando exportación XLSX...');
    
    if (_scannedBarcodes.isEmpty) {
      print('⚠️ No hay códigos para exportar');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay códigos para exportar'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    print('✅ Códigos a exportar: ${_scannedBarcodes.length}');

    try {
      // Crear un nuevo archivo Excel
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Códigos de Barras'];

      // Agregar encabezados con estilo
      sheetObject.appendRow([
        TextCellValue('#'),
        TextCellValue('Código'),
        TextCellValue('Tipo'),
        TextCellValue('Fecha'),
        TextCellValue('Hora'),
      ]);

      // Agregar datos
      for (int i = 0; i < _scannedBarcodes.length; i++) {
        final item = _scannedBarcodes[i];
        sheetObject.appendRow([
          IntCellValue(i + 1),
          TextCellValue(item.code),
          TextCellValue(item.type),
          TextCellValue('${item.timestamp.day}/${item.timestamp.month}/${item.timestamp.year}'),
          TextCellValue('${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}:${item.timestamp.second.toString().padLeft(2, '0')}'),
        ]);
      }

      print('📊 Excel generado con ${_scannedBarcodes.length} filas');

      // Obtener el directorio temporal
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/codigos_barras_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      print('📁 Guardando en: $path');

      // Guardar el archivo
      final file = File(path);
      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        print('✅ Archivo guardado, compartiendo...');

        // Compartir el archivo
        await Share.shareXFiles(
          [XFile(path)],
          subject: 'Códigos de barras escaneados',
          text: 'Lista de ${_scannedBarcodes.length} códigos escaneados en formato Excel',
        );

        print('✅ Compartido exitosamente');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Archivo Excel exportado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ ERROR al exportar XLSX: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar Excel: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Escáner de Códigos'),
        actions: [
          if (_scannedBarcodes.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _showExportDialog,
              tooltip: 'Exportar y compartir',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _clearBarcodes,
              tooltip: 'Limpiar lista',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Área del escáner
          if (_isScanning)
            Container(
              height: 300,
              child: MobileScanner(
                controller: cameraController,
                onDetect: _onBarcodeDetect,
              ),
            ),

          // Botón para iniciar/detener escaneo
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _toggleScanning,
              icon: Icon(_isScanning ? Icons.stop : Icons.qr_code_scanner),
              label: Text(_isScanning ? 'Detener Escaneo' : 'Iniciar Escaneo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Contador y encabezado de tabla
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Códigos escaneados: ${_scannedBarcodes.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Tabla de códigos escaneados
          Expanded(
            child: _scannedBarcodes.isEmpty
                ? Center(
                    child: Text(
                      'No hay códigos escaneados',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('#')),
                          DataColumn(label: Text('Código')),
                          DataColumn(label: Text('Tipo')),
                          DataColumn(label: Text('Hora')),
                        ],
                        rows: _scannedBarcodes.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return DataRow(
                            cells: [
                              DataCell(Text('${index + 1}')),
                              DataCell(
                                Text(
                                  item.code,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              DataCell(Text(item.type)),
                              DataCell(
                                Text(
                                  '${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}:${item.timestamp.second.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
