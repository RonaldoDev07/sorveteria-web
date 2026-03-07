import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_scanner/mobile_scanner.dart';

/// Scanner universal em TELA CHEIA para melhor visualização
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
        autoStart: false,
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
      
      // Aguardar um pouco para câmera inicializar
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Aplicar zoom para melhor foco de perto (1.5x a 2x)
      try {
        await _cameraController!.setZoomScale(1.8);
      } catch (e) {
        print('⚠️ Zoom não suportado: $e');
      }
      
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
        // Vibrar ao detectar (se disponível)
        try {
          // HapticFeedback.mediumImpact();
        } catch (e) {
          // Ignorar se não disponível
        }
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF9C27B0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Código de Barras',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_mostrarCamera && _cameraController != null)
                    IconButton(
                      icon: Icon(
                        _cameraController!.torchEnabled ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        _cameraController!.toggleTorch();
                        setState(() {});
                      },
                      tooltip: 'Lanterna',
                    ),
                  if (_cameraDisponivel && !_mostrarCamera)
                    IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                      onPressed: _tentarAbrirCamera,
                      tooltip: 'Abrir câmera',
                    ),
                  if (_mostrarCamera)
                    IconButton(
                      icon: const Icon(Icons.keyboard, color: Colors.white, size: 28),
                      onPressed: () {
                        setState(() => _mostrarCamera = false);
                      },
                      tooltip: 'Digitar manualmente',
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Content - TELA CHEIA
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
        // Câmera em tela cheia
        MobileScanner(
          controller: _cameraController!,
          onDetect: _onBarcodeDetect,
          errorBuilder: (context, error, child) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 24),
                  Text(
                    'Erro ao acessar câmera',
                    style: TextStyle(color: Colors.grey[700], fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _mostrarCamera = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('Digitar manualmente', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        ),
        
        // Overlay com guia MAIOR
        CustomPaint(
          painter: ScannerOverlay(),
          child: Container(),
        ),
        
        // Instruções MAIORES
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Posicione o código de barras\ndentro da área marcada',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.yellow[300], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Dica: Mantenha distância de 10-15cm',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualInput() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
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
                          fontSize: 14,
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
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'Digite o Código de Barras',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codigoController,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 20,
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
                  vertical: 20,
                ),
              ),
              onSubmitted: (_) => _confirmarCodigo(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _confirmarCodigo,
                icon: const Icon(Icons.check_circle, size: 28),
                label: const Text(
                  'Confirmar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
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
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Overlay minimalista - só bordas nos cantos, SEM área escura
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // NÃO desenhar overlay escuro - deixar câmera livre

    // Área de referência (invisível, só para posicionar as bordas)
    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.85,
      height: size.height * 0.40,
    );

    // Desenhar APENAS bordas nos cantos - MAIS GROSSAS e MAIORES
    final borderPaint = Paint()
      ..color = const Color(0xFF9C27B0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    final cornerLength = 60.0;

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
