import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const CreditRechargeApp());
}

class CreditRechargeApp extends StatelessWidget {
  const CreditRechargeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recharge Crédit',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
