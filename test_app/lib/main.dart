import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
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
  final String? id; // ID de Supabase (puede ser null si aún no se ha guardado)
  final String code;
  final DateTime timestamp;
  final String type;
  bool isSyncing; // Indica si se está guardando en Supabase
  bool isSynced; // Indica si ya se guardó en Supabase

  BarcodeItem({
    this.id,
    required this.code,
    required this.timestamp,
    required this.type,
    this.isSyncing = false,
    this.isSynced = false,
  });

  /// Crear desde JSON (para datos de Supabase)
  factory BarcodeItem.fromJson(Map<String, dynamic> json) {
    return BarcodeItem(
      id: json['id'] as String?,
      code: json['code'] as String,
      type: json['type'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isSynced: true,
    );
  }

  /// Convertir a JSON (para enviar a Supabase)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Crear una copia con campos actualizados
  BarcodeItem copyWith({
    String? id,
    String? code,
    DateTime? timestamp,
    String? type,
    bool? isSyncing,
    bool? isSynced,
  }) {
    return BarcodeItem(
      id: id ?? this.id,
      code: code ?? this.code,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isSyncing: isSyncing ?? this.isSyncing,
      isSynced: isSynced ?? this.isSynced,
    );
  }
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
          final newItem = BarcodeItem(
            code: code,
            timestamp: DateTime.now(),
            type: barcode.format.name,
            isSyncing: true, // Marcamos que se está sincronizando
          );

          setState(() {
            _scannedBarcodes.add(newItem);
          });

          // Guardar en Supabase en segundo plano
          _saveToSupabase(newItem);
        }
      }
    }
  }

  /// Guardar un código en Supabase
  Future<void> _saveToSupabase(BarcodeItem item) async {
    try {
      final id = await SupabaseService.saveBarcode(
        code: item.code,
        type: item.type,
        timestamp: item.timestamp,
      );

      // Actualizar el item con el ID de Supabase
      if (mounted) {
        setState(() {
          final index = _scannedBarcodes.indexOf(item);
          if (index != -1) {
            _scannedBarcodes[index] = item.copyWith(
              id: id,
              isSyncing: false,
              isSynced: id != null,
            );
          }
        });

        // Mostrar mensaje de éxito o error
        if (id != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Código guardado en Supabase'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠ Error al guardar en Supabase'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final index = _scannedBarcodes.indexOf(item);
          if (index != -1) {
            _scannedBarcodes[index] = item.copyWith(
              isSyncing: false,
              isSynced: false,
            );
          }
        });
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

  /// Widget que muestra el estado de sincronización
  Widget _buildSyncStatusIcon(BarcodeItem item) {
    if (item.isSyncing) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    } else if (item.isSynced) {
      return const Tooltip(
        message: 'Guardado en Supabase',
        child: Icon(
          Icons.cloud_done,
          color: Colors.green,
          size: 20,
        ),
      );
    } else {
      return const Tooltip(
        message: 'Error al guardar',
        child: Icon(
          Icons.cloud_off,
          color: Colors.orange,
          size: 20,
        ),
      );
    }
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
    if (_scannedBarcodes.isEmpty) {
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

      // Convertir a CSV manualmente
      String csv = _convertToCSV(rows);

      // Obtener el directorio temporal
      final directory = await getTemporaryDirectory();
      final filePath = path.join(
        directory.path,
        'codigos_barras_${DateTime.now().millisecondsSinceEpoch}.csv',
      );

      // Crear el archivo
      final file = File(filePath);
      await file.writeAsString(csv);

      // Compartir el archivo
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: 'Códigos de barras escaneados',
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Archivo CSV exportado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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
    if (_scannedBarcodes.isEmpty) {
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

      // Obtener el directorio temporal
      final directory = await getTemporaryDirectory();
      final filePath = path.join(
        directory.path,
        'codigos_barras_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      );

      // Guardar el archivo
      final file = File(filePath);
      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);

        // Compartir el archivo
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath)],
            subject: 'Códigos de barras escaneados',
          ),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Archivo Excel exportado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
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
            SizedBox(
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
                          DataColumn(label: Text('Estado')),
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
                              DataCell(
                                _buildSyncStatusIcon(item),
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
