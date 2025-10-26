import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import '../../../models/barcode_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/config/env_config.dart';
import '../../../core/widgets/app_drawer.dart';

class ScannerPage extends StatefulWidget {
  static MaterialPageRoute route() => MaterialPageRoute(
        builder: (context) => const ScannerPage(),
      );

  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final List<BarcodeModel> _scannedBarcodes = [];
  bool _isScanning = false;
  String? _cameraError;
  MobileScannerController cameraController = MobileScannerController(
    // Para web, usar cámara frontal (user-facing)
    facing: CameraFacing.front,
    // Autostart en false - solo iniciar cuando el usuario haga clic
    autoStart: false,
    // Permitir múltiples formatos
    formats: [
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.ean8,
      BarcodeFormat.ean13,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );

  void _onBarcodeDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final String code = barcode.rawValue!;
        final String type = barcode.format.name;

        if (!_scannedBarcodes.any((item) => item.code == code)) {
          _addBarcode(code, type);
        }
      }
    }
  }

  void _addBarcode(String code, String type) async {
    final newBarcode = BarcodeModel(
      code: code,
      type: type,
      timestamp: DateTime.now(),
      isSyncing: true,
    );

    setState(() {
      _scannedBarcodes.insert(0, newBarcode);
    });

    if (EnvConfig.isSupabaseConfigured) {
      final savedId = await SupabaseService.saveBarcode(
        code: code,
        type: type,
        timestamp: newBarcode.timestamp,
      );

      setState(() {
        final index =
            _scannedBarcodes.indexWhere((item) => item.code == code);
        if (index != -1) {
          _scannedBarcodes[index] = newBarcode.copyWith(
            id: savedId,
            isSyncing: false,
            isSynced: savedId != null,
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(savedId != null
                ? '✓ Código guardado en Supabase'
                : '⚠ Error al guardar en Supabase'),
            backgroundColor: savedId != null ? Colors.green : Colors.orange,
            duration: Duration(seconds: savedId != null ? 1 : 2),
          ),
        );
      }
    }
  }

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
      _cameraError = null;
    });
    
    if (_isScanning) {
      // Reiniciar la cámara cuando se activa el escaneo
      cameraController.start().catchError((error) {
        setState(() {
          _cameraError = 'Error al iniciar cámara: $error';
          _isScanning = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_cameraError!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });
    } else {
      cameraController.stop();
    }
  }

  void _clearBarcodes() {
    setState(() {
      _scannedBarcodes.clear();
    });
  }

  Future<void> _exportAsCSV() async {
    if (_scannedBarcodes.isEmpty) return;

    try {
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
          '${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}',
        ]);
      }

      String csv = rows.map((row) => row.join(',')).join('\n');

      final directory = await getTemporaryDirectory();
      final filePath = path.join(
        directory.path,
        'codigos_${DateTime.now().millisecondsSinceEpoch}.csv',
      );

      final file = File(filePath);
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Códigos escaneados',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV exportado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSyncStatusIcon(BarcodeModel item) {
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
      return const Icon(Icons.cloud_done, color: Colors.green, size: 16);
    } else {
      return const Icon(Icons.cloud_off, color: Colors.orange, size: 16);
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
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Escáner de Códigos'),
        actions: [
          if (_scannedBarcodes.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _exportAsCSV,
              tooltip: 'Exportar',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _clearBarcodes,
              tooltip: 'Limpiar',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (_cameraError != null)
            Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _cameraError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          if (_isScanning)
            Container(
              height: 300,
              color: Colors.black,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: cameraController,
                    onDetect: _onBarcodeDetect,
                    errorBuilder: (context, error, child) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error de cámara',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                error.errorDetails?.message ?? 'No se pudo acceder a la cámara',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                cameraController.start();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Apunte la cámara al código',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: _toggleScanning,
                    icon: Icon(_isScanning ? Icons.stop : Icons.qr_code_scanner),
                    label: Text(_isScanning ? 'Detener Escaneo' : 'Iniciar Escaneo'),
                  ),
                ),
                if (_isScanning) ...[
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {
                      cameraController.switchCamera();
                    },
                    icon: const Icon(Icons.cameraswitch),
                    tooltip: 'Cambiar cámara',
                    iconSize: 32,
                  ),
                  IconButton(
                    onPressed: () {
                      cameraController.toggleTorch();
                    },
                    icon: const Icon(Icons.flash_on),
                    tooltip: 'Flash',
                    iconSize: 32,
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Códigos escaneados: ${_scannedBarcodes.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _scannedBarcodes.isEmpty
                ? const Center(child: Text('No hay códigos escaneados'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('#')),
                        DataColumn(label: Text('Código')),
                        DataColumn(label: Text('Tipo')),
                        DataColumn(label: Text('Fecha y Hora')),
                        DataColumn(label: Text('Estado')),
                      ],
                      rows: _scannedBarcodes.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return DataRow(
                          cells: [
                            DataCell(Text('${index + 1}')),
                            DataCell(Text(item.code)),
                            DataCell(Text(item.type)),
                            DataCell(Text(
                                '${item.timestamp.day}/${item.timestamp.month}/${item.timestamp.year} ${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}')),
                            DataCell(_buildSyncStatusIcon(item)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
