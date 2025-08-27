import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/scanner_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isFlashOn = false;
  bool hasScanned = false;
  bool isCodeInArea = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      final String? code = barcode.rawValue;

      if (code != null && code.isNotEmpty) {
        // Simplifier : accepter tous les codes détectés
        // bool inArea = _isInScanArea(barcode);
        bool inArea = true; // Accepter tous les codes pour faciliter l'usage

        // Mettre à jour l'état visuel
        if (inArea != isCodeInArea) {
          setState(() {
            isCodeInArea = inArea;
          });
        }

        // Traiter le code détecté
        if (inArea) {
          setState(() {
            hasScanned = true;
          });

          // Vibration de succès
          _vibrate();

          String cleanedCode = ScannerService.cleanCode(code);
          if (ScannerService.isValidRechargeCode(cleanedCode)) {
            // Son de succès (feedback système)
            SystemSound.play(SystemSoundType.click);
            Navigator.pop(context, cleanedCode);
          } else {
            // Vibration d'erreur
            _vibrateError();
            _showErrorDialog(
              'Code invalide',
              'Le code scanné doit contenir exactement 14 chiffres.\n\nCode scanné: $code\nCode nettoyé: $cleanedCode',
            );
          }
        }
      }
    } else {
      // Aucun code détecté, réinitialiser l'état
      if (isCodeInArea) {
        setState(() {
          isCodeInArea = false;
        });
      }
    }
  }

  Future<void> _vibrate() async {
    // Utiliser les feedbacks haptiques intégrés de Flutter
    HapticFeedback.lightImpact();
  }

  Future<void> _vibrateError() async {
    // Utiliser les feedbacks haptiques intégrés de Flutter
    HapticFeedback.heavyImpact();
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
                setState(() {
                  hasScanned = false;
                });
              },
              child: const Text('Réessayer'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context, null);
              },
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  void _toggleFlash() {
    setState(() {
      isFlashOn = !isFlashOn;
    });
    cameraController.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Scanner le code',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _toggleFlash,
            icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
          ),
          IconButton(
            onPressed: () {
              // Afficher une aide contextuelle
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Conseils de scan'),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• Tenez le téléphone stable'),
                          Text('• Distance recommandée: 15-20 cm'),
                          Text('• Assurez-vous d\'un bon éclairage'),
                          Text('• Activez le flash si nécessaire'),
                          Text('• Le code doit être bien visible et net'),
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
          // Scanner
          MobileScanner(controller: cameraController, onDetect: _onDetect),

          // Overlay personnalisé
          _buildScannerOverlay(isCodeInArea),

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
                    'Tenez votre téléphone à 15-20 cm du code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Assurez-vous que le code est bien éclairé',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (isFlashOn)
                    const Text(
                      '💡 Flash activé',
                      style: TextStyle(color: Colors.yellow, fontSize: 12),
                    ),
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

  Widget _buildScannerOverlay(bool codeInArea) {
    return Container(
      decoration: ShapeDecoration(
        shape: _ScannerOverlayShape(codeInArea: codeInArea),
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
    final double scanWidth = 320.0; // Zone plus large
    final double scanHeight = 200.0; // Zone plus haute
    final double left = (rect.width - scanWidth) / 2;
    final double top = (rect.height - scanHeight) / 2;

    return Path()..addRRect(
      RRect.fromLTRBR(
        left,
        top,
        left + scanWidth,
        top + scanHeight,
        const Radius.circular(12),
      ),
    );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final double scanWidth = 320.0; // Zone plus large
    final double scanHeight = 200.0; // Zone plus haute
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
            const Radius.circular(12),
          ),
        ),
      ),
      overlayPaint,
    );

    // Cadre de scan avec bordures plus visibles
    final Paint borderPaint =
        Paint()
          ..color = Colors.white
          ..strokeWidth =
              3 // Plus épais
          ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromLTRBR(
        left,
        top,
        left + scanWidth,
        top + scanHeight,
        const Radius.circular(12),
      ),
      borderPaint,
    );

    // Coins du cadre de scan plus visibles
    final Paint cornerPaint =
        Paint()
          ..color = codeInArea ? Colors.green : Colors.white
          ..strokeWidth =
              6 // Plus épais
          ..style = PaintingStyle.stroke;

    const double cornerLength = 25;

    // Coin supérieur gauche
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top + 12)
        ..arcToPoint(Offset(left + 12, top), radius: const Radius.circular(12))
        ..lineTo(left + cornerLength, top),
      cornerPaint,
    );

    // Coin supérieur droit
    canvas.drawPath(
      Path()
        ..moveTo(left + scanWidth - cornerLength, top)
        ..lineTo(left + scanWidth - 12, top)
        ..arcToPoint(
          Offset(left + scanWidth, top + 12),
          radius: const Radius.circular(12),
        )
        ..lineTo(left + scanWidth, top + cornerLength),
      cornerPaint,
    );

    // Coin inférieur gauche
    canvas.drawPath(
      Path()
        ..moveTo(left, top + scanHeight - cornerLength)
        ..lineTo(left, top + scanHeight - 12)
        ..arcToPoint(
          Offset(left + 12, top + scanHeight),
          radius: const Radius.circular(12),
        )
        ..lineTo(left + cornerLength, top + scanHeight),
      cornerPaint,
    );

    // Coin inférieur droit
    canvas.drawPath(
      Path()
        ..moveTo(left + scanWidth - cornerLength, top + scanHeight)
        ..lineTo(left + scanWidth - 12, top + scanHeight)
        ..arcToPoint(
          Offset(left + scanWidth, top + scanHeight - 12),
          radius: const Radius.circular(12),
        )
        ..lineTo(left + scanWidth, top + scanHeight - cornerLength),
      cornerPaint,
    );

    // Ligne de scan plus visible
    final Paint scanLinePaint =
        Paint()
          ..color = (codeInArea ? Colors.green : Colors.white).withAlpha(180)
          ..strokeWidth = 3; // Plus épaisse

    final double scanLineY = top + scanHeight / 2;
    canvas.drawLine(
      Offset(left + 30, scanLineY),
      Offset(left + scanWidth - 30, scanLineY),
      scanLinePaint,
    );

    // Ajout de points sur la ligne de scan pour plus de visibilité
    final Paint dotPaint =
        Paint()
          ..color = codeInArea ? Colors.green : Colors.white
          ..style = PaintingStyle.fill;

    // Points aux extrémités de la ligne
    canvas.drawCircle(Offset(left + 30, scanLineY), 3, dotPaint);
    canvas.drawCircle(Offset(left + scanWidth - 30, scanLineY), 3, dotPaint);
    canvas.drawCircle(Offset(left + scanWidth / 2, scanLineY), 2, dotPaint);

    // Indicateur de code détecté
    if (codeInArea) {
      final Paint successPaint =
          Paint()
            ..color = Colors.green.withAlpha(51)
            ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromLTRBR(
          left,
          top,
          left + scanWidth,
          top + scanHeight,
          const Radius.circular(12),
        ),
        successPaint,
      );
    }
  }

  @override
  ShapeBorder scale(double t) => this;
}
