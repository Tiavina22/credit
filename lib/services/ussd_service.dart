import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class USSDService {
  static Future<bool> launchUSSD(String ussdCode) async {
    try {
      if (kDebugMode) {
        print('Code USSD original: $ussdCode');
      }

      // Méthode basée sur votre application qui fonctionne
      // Enlever les # du début et de la fin pour Yas et Airtel
      String cleanUssdCode = ussdCode;
      if (cleanUssdCode.startsWith('#') && cleanUssdCode.endsWith('#')) {
        cleanUssdCode = cleanUssdCode.substring(1, cleanUssdCode.length - 1);
      }

      // Encoder le code USSD
      final encodedUssdCode = Uri.encodeComponent(cleanUssdCode);
      final uri = Uri.parse('tel:*$encodedUssdCode%23');

      if (kDebugMode) {
        print('Code USSD nettoyé: $cleanUssdCode');
        print('Code USSD encodé: $encodedUssdCode');
        print('URI générée: $uri');
        print('Launching USSD code: $cleanUssdCode');
      }

      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return true;
      }

      // Fallback : essayer sans modification pour Orange
      if (ussdCode.startsWith('144')) {
        final directUri = Uri.parse('tel:$ussdCode');
        if (await launchUrl(directUri, mode: LaunchMode.externalApplication)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur USSD: $e');
      }
      return false;
    }
  }

  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
