import 'package:flutter/material.dart';
import '../../core/theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: PesowiseColors.background,
      body: Center(child: Text('Reports')),
    );
  }
}