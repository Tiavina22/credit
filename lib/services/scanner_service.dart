import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../screens/ocr_scanner_screen.dart';

class ScannerService {
  static Future<String?> scanBarcode(BuildContext context) async {
    try {
      // Demander la permission de la caméra
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
        if (!status.isGranted) {
          throw 'Permission caméra refusée';
        }
      }

      // Vérifier que le context est encore valide
      if (!context.mounted) return null;

      // Naviguer vers l'écran de scanner OCR
      final result = await Navigator.push<String?>(
        context,
        MaterialPageRoute(builder: (context) => const OCRScannerScreen()),
      );

      return result;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to scan barcode: $e');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error: $e');
      }
      rethrow;
    }
  }

  static bool isValidRechargeCode(String code) {
    // Enlever tous les caractères non numériques
    String cleanCode = code.replaceAll(RegExp(r'[^0-9]'), '');
    // Vérifier si le code contient exactement 14 chiffres
    return cleanCode.length == 14 && RegExp(r'^\d{14}$').hasMatch(cleanCode);
  }

  static String cleanCode(String code) {
    return code.replaceAll(RegExp(r'[^0-9]'), '');
  }
}
