import 'package:flutter/material.dart';
import '../../core/theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: PesowiseColors.background,
      body: Center(child: Text('Dashboard')),
    );
  }
}