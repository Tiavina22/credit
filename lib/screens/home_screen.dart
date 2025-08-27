import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/operator.dart';
import '../models/recharge_history.dart';
import '../services/scanner_service.dart';
import '../services/ussd_service.dart';
import '../services/database_helper.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MobileOperator? selectedOperator;
  final TextEditingController codeController = TextEditingController();
  final DatabaseHelper dbHelper = DatabaseHelper();
  bool isLoading = false;

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  Future<void> _scanCode() async {
    setState(() {
      isLoading = true;
    });

    try {
      String? scannedCode = await ScannerService.scanBarcode(context);
      if (scannedCode != null && scannedCode.isNotEmpty) {
        String cleanedCode = ScannerService.cleanCode(scannedCode);
        if (ScannerService.isValidRechargeCode(cleanedCode)) {
          setState(() {
            codeController.text = cleanedCode;
          });
          _showMessage('Code scanné avec succès!', Colors.green);
        } else {
          _showMessage('Code invalide: doit contenir 14 chiffres', Colors.red);
        }
      } else {
        // L'utilisateur a annulé ou aucun code n'a été scanné
        _showMessage('Scan annulé', Colors.orange);
      }
    } catch (e) {
      _showMessage('Erreur lors du scan: $e', Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _rechargeCredit() async {
    if (selectedOperator == null) {
      _showMessage('Veuillez sélectionner un opérateur', Colors.orange);
      return;
    }

    String code = codeController.text.trim();
    if (code.isEmpty) {
      _showMessage('Veuillez entrer ou scanner un code', Colors.orange);
      return;
    }

    String cleanedCode = ScannerService.cleanCode(code);
    if (!ScannerService.isValidRechargeCode(cleanedCode)) {
      _showMessage('Code invalide: doit contenir 14 chiffres', Colors.red);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String ussdCode = selectedOperator!.generateUSSD(cleanedCode);

      // Sauvegarder dans l'historique
      RechargeHistory history = RechargeHistory(
        operator: selectedOperator!.name,
        code: cleanedCode,
        date: DateTime.now(),
        status: 'Tenté',
      );
      await dbHelper.insertRecharge(history);

      // Lancer le code USSD avec la méthode qui fonctionne
      bool success = await USSDService.launchUSSD(ussdCode);

      if (success) {
        _showMessage('Code USSD lancé: $ussdCode', Colors.green);
        // Nettoyer le champ après succès
        codeController.clear();
      } else {
        // En cas d'échec, copier dans le presse-papiers et afficher la dialog
        await USSDService.copyToClipboard(ussdCode);
        _showUssdDialog(ussdCode);
      }
    } catch (e) {
      _showMessage('Erreur: $e', Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showUssdDialog(String ussdCode) {
    // Copier automatiquement dans le presse-papiers
    USSDService.copyToClipboard(ussdCode);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.phone, color: Colors.green[600]),
              const SizedBox(width: 8),
              const Text('Code USSD généré'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Votre code de recharge a été généré:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      ussdCode,
                      style: const TextStyle(
                        fontSize: 24,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        '📋 Copié automatiquement',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Instructions:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildInstructionStep(
                '1',
                'Ouvrez votre application de téléphone',
              ),
              _buildInstructionStep(
                '2',
                'Collez le code ou composez-le manuellement',
              ),
              _buildInstructionStep('3', 'Appuyez sur appeler pour executer'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Relancer l'application téléphone avec le code
                await USSDService.launchUSSD(ussdCode);
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('📞 Ouvrir le téléphone'),
            ),
            TextButton(
              onPressed: () async {
                // Recopier dans le presse-papiers
                await USSDService.copyToClipboard(ussdCode);
                if (mounted) {
                  _showMessage('Code recopié!', Colors.green);
                }
              },
              child: const Text('📋 Recopier'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (mounted) {
                  codeController.clear();
                  _showMessage('Recharge en cours...', Colors.orange);
                }
              },
              child: const Text('✅ Terminé'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstructionStep(String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(instruction, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorButton(MobileOperator operator) {
    bool isSelected = selectedOperator == operator;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedOperator = operator;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Color(int.parse('0xFF${operator.color.substring(1)}'))
                    : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.phone_android,
                size: 32,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
              const SizedBox(height: 8),
              Text(
                operator.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Recharge Crédit',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Opérateur
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choisir un opérateur',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children:
                          MobileOperator.operators
                              .map((operator) => _buildOperatorButton(operator))
                              .toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Section Code
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Code de recharge (14 chiffres)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 14,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'Entrez le code de 14 chiffres',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.credit_card),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _scanCode,
                        icon:
                            isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.qr_code_scanner),
                        label: Text(
                          isLoading ? 'Scan en cours...' : 'Scanner le code',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Bouton de recharge
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _rechargeCredit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child:
                    isLoading
                        ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Traitement...',
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        )
                        : const Text(
                          'Recharger',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),

            const SizedBox(height: 20),

            // Informations USSD
            if (selectedOperator != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Code USSD ${selectedOperator!.name}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedOperator!.ussdFormat,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
