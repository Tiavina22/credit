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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey[50]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone_callback_rounded,
                    color: Colors.green[700],
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Code USSD généré',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D29),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'Votre code de recharge est prêt à être utilisé',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),

                // USSD Code Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[50]!, Colors.blue[25]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue[200]!, width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(
                        ussdCode,
                        style: const TextStyle(
                          fontSize: 28,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E40AF),
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green[700],
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Copié automatiquement',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instructions:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildModernInstructionStep(
                        '1',
                        'Ouvrez votre application de téléphone',
                        Icons.phone_rounded,
                      ),
                      _buildModernInstructionStep(
                        '2',
                        'Collez le code ou composez-le manuellement',
                        Icons.content_paste_rounded,
                      ),
                      _buildModernInstructionStep(
                        '3',
                        'Appuyez sur appeler pour exécuter',
                        Icons.call_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await USSDService.copyToClipboard(ussdCode);
                          if (mounted) {
                            _showMessage('Code recopié!', Colors.green);
                          }
                        },
                        icon: const Icon(Icons.content_copy_rounded, size: 18),
                        label: const Text('Recopier'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await USSDService.launchUSSD(ussdCode);
                          if (mounted) {
                            Navigator.of(context).pop();
                            codeController.clear();
                            _showMessage('Recharge en cours...', Colors.orange);
                          }
                        },
                        icon: const Icon(Icons.phone_rounded, size: 18),
                        label: const Text('Ouvrir le téléphone'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernInstructionStep(
    String number,
    String instruction,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorCard(MobileOperator operator) {
    bool isSelected = selectedOperator == operator;
    Color operatorColor = Color(
      int.parse('0xFF${operator.color.substring(1)}'),
    );

    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                selectedOperator = operator;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient:
                    isSelected
                        ? LinearGradient(
                          colors: [
                            operatorColor,
                            operatorColor.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                        : LinearGradient(
                          colors: [Colors.grey[100]!, Colors.grey[50]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? operatorColor : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: operatorColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                        : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Colors.white.withOpacity(0.2)
                              : operatorColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.phone_android_rounded,
                      size: 28,
                      color: isSelected ? Colors.white : operatorColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    operator.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Colors.white.withOpacity(0.2)
                              : operatorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      operator.ussdFormat.split('*')[0],
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isSelected
                                ? Colors.white.withOpacity(0.9)
                                : operatorColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Recharge',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.history_rounded, size: 20),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Balance Card (Revolut style)
                  _buildBalanceCard(),

                  const SizedBox(height: 24),

                  // Operators Section
                  _buildOperatorsSection(),

                  const SizedBox(height: 24),

                  // Code Input Section
                  _buildCodeInputSection(),

                  const SizedBox(height: 24),

                  // Action Button
                  _buildRechargeButton(),

                  const SizedBox(height: 16),

                  // USSD Info
                  if (selectedOperator != null) _buildUssdInfo(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Crédit Madagascar',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🇲🇬 MG',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Rechargez facilement',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scanner • Saisir • Recharger',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisir un opérateur',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1D29),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children:
              MobileOperator.operators
                  .map((operator) => _buildOperatorCard(operator))
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildCodeInputSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Code de recharge',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1D29),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Entrez ou scannez votre code de 14 chiffres',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 14,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
              decoration: InputDecoration(
                hintText: '00000000000000',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(16),
                  child: Icon(
                    Icons.credit_card_rounded,
                    color: Colors.grey[400],
                  ),
                ),
                counterText: '',
              ),
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Icon(Icons.qr_code_scanner_rounded),
              label: Text(
                isLoading ? 'Scan en cours...' : 'Scanner le code',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRechargeButton() {
    bool canRecharge =
        selectedOperator != null && codeController.text.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow:
            canRecharge && !isLoading
                ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
                : [],
      ),
      child: ElevatedButton(
        onPressed: (canRecharge && !isLoading) ? _rechargeCredit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canRecharge ? const Color(0xFF10B981) : Colors.grey[300],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.grey[300],
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Traitement...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flash_on_rounded, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      canRecharge
                          ? 'Recharger maintenant'
                          : 'Sélectionnez un opérateur',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: canRecharge ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildUssdInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: Colors.blue[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Code USSD ${selectedOperator!.name}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selectedOperator!.ussdFormat,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
