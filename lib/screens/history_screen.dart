import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recharge_history.dart';
import '../services/database_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<RechargeHistory> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<RechargeHistory> loadedHistory = await dbHelper.getRechargeHistory();
      setState(() {
        history = loadedHistory;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showMessage(
        'Erreur lors du chargement de l\'historique: $e',
        Colors.red,
      );
    }
  }

  Future<void> _clearHistory() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer'),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer tout l\'historique ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await dbHelper.clearHistory();
        await _loadHistory();
        _showMessage('Historique supprimé', Colors.green);
      } catch (e) {
        _showMessage('Erreur lors de la suppression: $e', Colors.red);
      }
    }
  }

  Future<void> _deleteHistoryItem(int id) async {
    try {
      await dbHelper.deleteRecharge(id);
      await _loadHistory();
      _showMessage('Élément supprimé', Colors.green);
    } catch (e) {
      _showMessage('Erreur lors de la suppression: $e', Colors.red);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getOperatorColor(String operator) {
    switch (operator.toLowerCase()) {
      case 'yas':
        return const Color(0xFFFF6B6B);
      case 'orange':
        return const Color(0xFFFF8C00);
      case 'airtel':
        return const Color(0xFFFF0000);
      default:
        return Colors.grey;
    }
  }

  Widget _buildHistoryItem(RechargeHistory item) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getOperatorColor(item.operator).withAlpha(51),
          child: Text(
            item.operator[0].toUpperCase(),
            style: TextStyle(
              color: _getOperatorColor(item.operator),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          item.operator,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Code: ${item.code}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              dateFormat.format(item.date),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete' && item.id != null) {
              _deleteHistoryItem(item.id!);
            }
          },
          itemBuilder:
              (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer'),
                    ],
                  ),
                ),
              ],
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Historique des recharges',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearHistory,
              tooltip: 'Vider l\'historique',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : history.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune recharge enregistrée',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Effectuez votre première recharge pour voir l\'historique',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${history.length} recharge(s) enregistrée(s)',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          return _buildHistoryItem(history[index]);
                        },
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
