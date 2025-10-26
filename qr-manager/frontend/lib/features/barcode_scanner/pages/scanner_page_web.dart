import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:async';
import 'dart:js_util' as js_util;
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
  html.MediaStream? _stream;
  html.VideoElement? _videoElement;
  html.CanvasElement? _canvasElement;
  Timer? _scanTimer;
  final String _videoElementId = 'barcode-video-${DateTime.now().millisecondsSinceEpoch}';
  final Set<String> _scannedCodes = {}; // Para evitar duplicados

  @override
  void initState() {
    super.initState();
    // Crear y registrar el elemento de video
    _videoElement = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.transform = 'scaleX(-1)'; // Espejo para cámara frontal
    
    // Crear canvas para capturar frames
    _canvasElement = html.CanvasElement();
    
    ui_web.platformViewRegistry.registerViewFactory(
      _videoElementId,
      (int viewId) => _videoElement!,
    );
  }

  void _startScanningLoop() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      _scanFrame();
    });
  }

  void _scanFrame() {
    if (_videoElement == null || _canvasElement == null) return;
    
    try {
      final video = _videoElement!;
      final canvas = _canvasElement!;
      
      // Asegurarse de que el video está listo
      if (video.readyState != html.MediaElement.HAVE_ENOUGH_DATA) {
        return;
      }
      
      // Configurar canvas con las dimensiones del video
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      
      final context = canvas.context2D;
      context.drawImageScaled(video, 0, 0, canvas.width!, canvas.height!);
      
      // Obtener los datos de la imagen
      final imageData = context.getImageData(0, 0, canvas.width!, canvas.height!);
      
      // Llamar a jsQR para detectar códigos
      final jsQRFunction = js_util.getProperty(html.window, 'jsQR');
      if (jsQRFunction != null) {
        final code = js_util.callMethod(
          jsQRFunction, 
          'call',
          [
            null,
            imageData.data,
            canvas.width,
            canvas.height,
            js_util.jsify({'inversionAttempts': 'dontInvert'})
          ]
        );
        
        if (code != null) {
          final barcodeData = js_util.getProperty(code, 'data');
          if (barcodeData != null && barcodeData.toString().isNotEmpty) {
            final String codeString = barcodeData.toString();
            if (!_scannedCodes.contains(codeString)) {
              _scannedCodes.add(codeString);
              _addBarcode(codeString, 'QR_CODE');
            }
          }
        }
      }
    } catch (e) {
      // Ignorar errores de escaneo individual
    }
  }

  Future<void> _startCamera() async {
    try {
      setState(() {
        _cameraError = null;
        _isScanning = true;
      });

      // Solicitar acceso a la cámara
      final constraints = {
        'video': {
          'facingMode': 'user', // Cámara frontal
          'width': {'ideal': 1280},
          'height': {'ideal': 720}
        }
      };

      _stream = await html.window.navigator.mediaDevices!
          .getUserMedia(constraints);

      // Asignar el stream al elemento de video
      if (_videoElement != null) {
        _videoElement!.srcObject = _stream;
        _videoElement!.play();
        
        // Iniciar el loop de escaneo
        _startScanningLoop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Cámara iniciada. Escaneo automático activado.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _cameraError = 'Error al acceder a la cámara: ${e.toString()}';
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
    }
  }

  void _stopCamera() {
    _scanTimer?.cancel();
    if (_stream != null) {
      _stream!.getTracks().forEach((track) {
        track.stop();
      });
      _stream = null;
    }
    setState(() {
      _isScanning = false;
    });
  }

  void _toggleScanning() {
    if (_isScanning) {
      _stopCamera();
    } else {
      _startCamera();
    }
  }

  void _addBarcodeManually() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Código'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Código de barras o QR',
            hintText: 'Ingrese el código',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _addBarcode(controller.text, 'MANUAL');
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
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
        final index = _scannedBarcodes.indexWhere((item) => item.code == code);
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
                ? '✓ Código guardado'
                : '⚠ Error al guardar'),
            backgroundColor: savedId != null ? Colors.green : Colors.orange,
            duration: Duration(seconds: savedId != null ? 1 : 2),
          ),
        );
      }
    }
  }

  void _clearBarcodes() {
    setState(() {
      _scannedBarcodes.clear();
      _scannedCodes.clear();
    });
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _stopCamera();
    super.dispose();
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

      // Crear blob y descargar
      final blob = html.Blob([csv], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'codigos_${DateTime.now().millisecondsSinceEpoch}.csv')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV descargado exitosamente'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Escáner de Códigos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addBarcodeManually,
            tooltip: 'Agregar código manualmente',
          ),
          if (_scannedBarcodes.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportAsCSV,
              tooltip: 'Exportar CSV',
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
              width: double.infinity,
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
              child: HtmlElementView(viewType: _videoElementId),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _toggleScanning,
                  icon: Icon(_isScanning ? Icons.stop : Icons.videocam),
                  label: Text(_isScanning ? 'Detener Cámara' : 'Iniciar Cámara'),
                ),
                ElevatedButton.icon(
                  onPressed: _addBarcodeManually,
                  icon: const Icon(Icons.keyboard),
                  label: const Text('Agregar Manualmente'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Códigos registrados: ${_scannedBarcodes.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _scannedBarcodes.isEmpty
                ? const Center(
                    child: Text(
                      'No hay códigos registrados.\nAgréguelos manualmente o use un lector externo.',
                      textAlign: TextAlign.center,
                    ),
                  )
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
                            DataCell(SelectableText(item.code)),
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
