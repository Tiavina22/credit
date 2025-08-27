import 'package:flutter_test/flutter_test.dart';
import 'package:credit/models/operator.dart';
import 'package:credit/services/scanner_service.dart';

void main() {
  group('MobileOperator Tests', () {
    test('Yas USSD generation', () {
      const operator = MobileOperator(
        name: 'Yas',
        ussdFormat: '#321*{code}#',
        logoPath: 'assets/images/yas_logo.png',
        color: '#FF6B6B',
      );

      const testCode = '12345678901234';
      final ussd = operator.generateUSSD(testCode);

      expect(ussd, equals('#321*12345678901234#'));
    });

    test('Orange USSD generation', () {
      const operator = MobileOperator(
        name: 'Orange',
        ussdFormat: '144{code}',
        logoPath: 'assets/images/orange_logo.png',
        color: '#FF8C00',
      );

      const testCode = '98765432109876';
      final ussd = operator.generateUSSD(testCode);

      expect(ussd, equals('14498765432109876'));
    });

    test('Airtel USSD generation', () {
      const operator = MobileOperator(
        name: 'Airtel',
        ussdFormat: '*999*{code}#',
        logoPath: 'assets/images/airtel_logo.png',
        color: '#FF0000',
      );

      const testCode = '11223344556677';
      final ussd = operator.generateUSSD(testCode);

      expect(ussd, equals('*999*11223344556677#'));
    });
  });

  group('ScannerService Tests', () {
    test('Valid recharge code validation', () {
      // Test avec un code valide de 14 chiffres
      expect(ScannerService.isValidRechargeCode('12345678901234'), true);

      // Test avec des codes invalides
      expect(
        ScannerService.isValidRechargeCode('123456789'),
        false,
      ); // Trop court
      expect(
        ScannerService.isValidRechargeCode('123456789012345'),
        false,
      ); // Trop long
      expect(
        ScannerService.isValidRechargeCode('1234567890123a'),
        false,
      ); // Contient des lettres
      expect(ScannerService.isValidRechargeCode(''), false); // Vide
    });

    test('Code cleaning', () {
      // Test nettoyage de code avec espaces et caractères spéciaux
      expect(ScannerService.cleanCode('1234 5678 9012 34'), '12345678901234');
      expect(ScannerService.cleanCode('1234-5678-9012-34'), '12345678901234');
      expect(
        ScannerService.cleanCode('abc12345678901234def'),
        '12345678901234',
      );
    });
  });
}
