import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/scanner_service.dart';

class OCRScannerScreen extends StatefulWidget {
  const OCRScannerScreen({super.key});

  @override
  State<OCRScannerScreen> createState() => _OCRScannerScreenState();
}

class _OCRScannerScreenState extends State<OCRScannerScreen> {
  CameraController? cameraController;
  late TextRecognizer textRecognizer;
  bool isFlashOn = false;
  bool hasScanned = false;
  bool isCodeInArea = false;
  bool isInitialized = false;
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    textRecognizer = TextRecognizer();
    _initializeCamera();
  }

  @override
  void dispose() {
    cameraController?.dispose();
    textRecognizer.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      // Vérifier les permissions
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
        if (!status.isGranted) {
          throw 'Permission caméra refusée';
        }
      }

      // Obtenir les caméras disponibles
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw 'Aucune caméra disponible';
      }

      // Initialiser la caméra arrière
      final camera = cameras.first;
      cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await cameraController!.initialize();

      if (mounted) {
        setState(() {
          isInitialized = true;
        });
        _startScanning();
      }
    } catch (e) {
      _showErrorDialog(
        'Erreur caméra',
        'Impossible d\'initialiser la caméra: $e',
      );
    }
  }

  void _startScanning() {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    // Scanner toutes les 500ms
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !hasScanned && !isScanning) {
        _scanForText();
        _startScanning();
      }
    });
  }

  Future<void> _scanForText() async {
    if (isScanning ||
        cameraController == null ||
        !cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      isScanning = true;
    });

    try {
      final image = await cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await textRecognizer.processImage(inputImage);

      if (mounted) {
        _processRecognizedText(recognizedText.text);
      }
    } catch (e) {
      // Ignorer les erreurs silencieusement pour ne pas spam l'utilisateur
    } finally {
      if (mounted) {
        setState(() {
          isScanning = false;
        });
      }
    }
  }

  void _processRecognizedText(String text) {
    if (hasScanned) return;

    // Extraire tous les chiffres du texte reconnu
    final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');

    // Chercher des séquences de 14 chiffres
    final regex = RegExp(r'\d{14}');
    final matches = regex.allMatches(digitsOnly);

    for (final match in matches) {
      final code = match.group(0);
      if (code != null && ScannerService.isValidRechargeCode(code)) {
        setState(() {
          hasScanned = true;
          isCodeInArea = true;
        });

        // Feedback haptique
        HapticFeedback.lightImpact();
        SystemSound.play(SystemSoundType.click);

        Navigator.pop(context, code);
        return;
      }
    }

    // Chercher des chiffres qui pourraient être séparés par des espaces ou tirets
    final patterns = [
      RegExp(
        r'(\d{4})\s*(\d{4})\s*(\d{3})\s*(\d{3})',
      ), // Format: 1234 5678 901 234
      RegExp(r'(\d{4})-(\d{4})-(\d{3})-(\d{3})'), // Format: 1234-5678-901-234
      RegExp(
        r'(\d{2})\s*(\d{4})\s*(\d{4})\s*(\d{4})',
      ), // Format: 12 3456 7890 1234
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final code = match.groups([1, 2, 3, 4]).join('');
        if (code.length == 14 && ScannerService.isValidRechargeCode(code)) {
          setState(() {
            hasScanned = true;
            isCodeInArea = true;
          });

          HapticFeedback.lightImpact();
          SystemSound.play(SystemSoundType.click);

          Navigator.pop(context, code);
          return;
        }
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context, null);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _toggleFlash() async {
    if (cameraController == null) return;

    try {
      setState(() {
        isFlashOn = !isFlashOn;
      });

      await cameraController!.setFlashMode(
        isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      // Rétablir l'état en cas d'erreur
      setState(() {
        isFlashOn = !isFlashOn;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized || cameraController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Scanner les chiffres',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _toggleFlash,
            icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Conseils de scan OCR'),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• Tenez le téléphone stable'),
                          Text('• Distance recommandée: 10-15 cm'),
                          Text('• Assurez-vous que les chiffres sont nets'),
                          Text('• Bon éclairage essentiel'),
                          Text('• Évitez les reflets sur la carte'),
                          Text('• Les 14 chiffres doivent être visibles'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
              );
            },
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Vue de la caméra
          Positioned.fill(child: CameraPreview(cameraController!)),

          // Overlay personnalisé
          _buildScannerOverlay(),

          // Instructions
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(179),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Placez les 14 chiffres dans le cadre',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Assurez-vous que les chiffres sont nets et bien éclairés',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  if (isScanning) ...[
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Analyse en cours...',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bouton saisie manuelle
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, null),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Saisie manuelle',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: _ScannerOverlayShape(codeInArea: isCodeInArea),
      ),
    );
  }
}

class _ScannerOverlayShape extends ShapeBorder {
  final bool codeInArea;

  const _ScannerOverlayShape({this.codeInArea = false});

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final double scanWidth = 320.0;
    final double scanHeight = 120.0; // Plus bas pour les chiffres
    final double left = (rect.width - scanWidth) / 2;
    final double top = (rect.height - scanHeight) / 2;

    return Path()..addRRect(
      RRect.fromLTRBR(
        left,
        top,
        left + scanWidth,
        top + scanHeight,
        const Radius.circular(8),
      ),
    );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final double scanWidth = 320.0;
    final double scanHeight = 120.0; // Plus bas pour les chiffres
    final double left = (rect.width - scanWidth) / 2;
    final double top = (rect.height - scanHeight) / 2;

    // Overlay sombre
    final Paint overlayPaint = Paint()..color = Colors.black.withAlpha(128);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRRect(
          RRect.fromLTRBR(
            left,
            top,
            left + scanWidth,
            top + scanHeight,
            const Radius.circular(8),
          ),
        ),
      ),
      overlayPaint,
    );

    // Cadre de scan
    final Paint borderPaint =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromLTRBR(
        left,
        top,
        left + scanWidth,
        top + scanHeight,
        const Radius.circular(8),
      ),
      borderPaint,
    );

    // Coins du cadre
    final Paint cornerPaint =
        Paint()
          ..color = codeInArea ? Colors.green : Colors.white
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke;

    const double cornerLength = 25;

    // Coins supérieurs
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + cornerLength),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(left + scanWidth - cornerLength, top),
      Offset(left + scanWidth, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanWidth, top),
      Offset(left + scanWidth, top + cornerLength),
      cornerPaint,
    );

    // Coins inférieurs
    canvas.drawLine(
      Offset(left, top + scanHeight - cornerLength),
      Offset(left, top + scanHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + scanHeight),
      Offset(left + cornerLength, top + scanHeight),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(left + scanWidth, top + scanHeight - cornerLength),
      Offset(left + scanWidth, top + scanHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanWidth - cornerLength, top + scanHeight),
      Offset(left + scanWidth, top + scanHeight),
      cornerPaint,
    );

    // Ligne centrale pour guider l'alignement
    final Paint guidePaint =
        Paint()
          ..color = (codeInArea ? Colors.green : Colors.white).withAlpha(100)
          ..strokeWidth = 1;

    final double centerY = top + scanHeight / 2;
    canvas.drawLine(
      Offset(left + 20, centerY),
      Offset(left + scanWidth - 20, centerY),
      guidePaint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}
