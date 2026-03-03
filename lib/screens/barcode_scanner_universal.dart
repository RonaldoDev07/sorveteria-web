import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_scanner/mobile_scanner.dart';

/// Scanner universal que funciona em qualquer plataforma
/// - No navegador: mostra campo para digitar + botão para tentar câmera
/// - No app: abre câmera diretamente
class BarcodeScannerUniversal extends StatefulWidget {
  const BarcodeScannerUniversal({super.key});

  @override
  State<BarcodeScannerUniversal> createState() => _BarcodeScannerUniversalState();
}

class _BarcodeScannerUniversalState extends State<BarcodeScannerUniversal> {
  final _codigoController = TextEditingController();
  bool _mostrarCamera = false;
  bool _cameraDisponivel = true;
  
  MobileScannerController? _cameraController;

  @override
  void initState() {
    super.initState();
    // Sempre tentar abrir câmera primeiro (web e app)
    _tentarAbrirCamera();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _tentarAbrirCamera() async {
    try {
      _cameraController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
        returnImage: false,
        formats: [
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.code128,
          BarcodeFormat.code39,
          BarcodeFormat.code93,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
        ],
      );
      
      await _cameraController!.start();
      
      if (mounted) {
        setState(() {
          _mostrarCamera = true;
          _cameraDisponivel = true;
        });
      }
    } catch (e) {
      print('❌ Câmera não disponível: $e');
      if (mounted) {
        setState(() {
          _mostrarCamera = false;
          _cameraDisponivel = false;
        });
      }
    }
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      final String? code = barcode.rawValue;
      
      if (code != null && code.isNotEmpty && code.length >= 8) {
        Navigator.pop(context, code);
      }
    }
  }

  void _confirmarCodigo() {
    final codigo = _codigoController.text.trim();
    if (codigo.isNotEmpty) {
      Navigator.pop(context, codigo);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um código válido'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF9C27B0),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Código de Barras',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_cameraDisponivel && !_mostrarCamera)
                    IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: _tentarAbrirCamera,
                      tooltip: 'Abrir câmera',
                    ),
                  if (_mostrarCamera)
                    IconButton(
                      icon: const Icon(Icons.keyboard, color: Colors.white),
                      onPressed: () {
                        setState(() => _mostrarCamera = false);
                      },
                      tooltip: 'Digitar manualmente',
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _mostrarCamera && _cameraController != null
                  ? _buildCamera()
                  : _buildManualInput(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCamera() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: MobileScanner(
            controller: _cameraController!,
            onDetect: _onBarcodeDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao acessar câmera',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _mostrarCamera = false);
                      },
                      child: const Text('Digitar manualmente'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        // Overlay com guia
        CustomPaint(
          painter: ScannerOverlay(),
          child: Container(),
        ),
        
        // Instruções
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Posicione o código de barras\ndentro da área marcada',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualInput() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_cameraDisponivel) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Câmera não disponível neste dispositivo',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          const Icon(
            Icons.keyboard,
            color: Color(0xFF9C27B0),
            size: 64,
          ),
          const SizedBox(height: 24),
          const Text(
            'Digite o Código de Barras',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _codigoController,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 18,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              hintText: 'Ex: 7891234567890',
              hintStyle: TextStyle(
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
            onSubmitted: (_) => _confirmarCodigo(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirmarCodigo,
              icon: const Icon(Icons.check_circle, size: 24),
              label: const Text(
                'Confirmar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Dica: O código geralmente tem 13 dígitos',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// Overlay personalizado para guiar o escaneamento
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.75,
      height: size.height * 0.35,
    );

    // Desenhar overlay escuro ao redor da área de scan
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(16)))
        ..fillType = PathFillType.evenOdd,
      paint,
    );

    // Desenhar bordas da área de scan
    final borderPaint = Paint()
      ..color = const Color(0xFF9C27B0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cornerLength = 30.0;

    // Cantos superiores
    canvas.drawLine(
      Offset(scanArea.left, scanArea.top),
      Offset(scanArea.left + cornerLength, scanArea.top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanArea.left, scanArea.top),
      Offset(scanArea.left, scanArea.top + cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanArea.right, scanArea.top),
      Offset(scanArea.right - cornerLength, scanArea.top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanArea.right, scanArea.top),
      Offset(scanArea.right, scanArea.top + cornerLength),
      borderPaint,
    );

    // Cantos inferiores
    canvas.drawLine(
      Offset(scanArea.left, scanArea.bottom),
      Offset(scanArea.left + cornerLength, scanArea.bottom),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanArea.left, scanArea.bottom),
      Offset(scanArea.left, scanArea.bottom - cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanArea.right, scanArea.bottom),
      Offset(scanArea.right - cornerLength, scanArea.bottom),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanArea.right, scanArea.bottom),
      Offset(scanArea.right, scanArea.bottom - cornerLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
