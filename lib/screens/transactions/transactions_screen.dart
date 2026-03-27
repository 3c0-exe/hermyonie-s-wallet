import 'package:flutter/material.dart';
import '../../core/theme.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: PesowiseColors.background,
      body: Center(child: Text('Transactions')),
    );
  }
}