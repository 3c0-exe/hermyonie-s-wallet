import 'package:flutter/material.dart';
import '../../core/theme.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: PesowiseColors.background,
      body: Center(child: Text('Wallets')),
    );
  }
}