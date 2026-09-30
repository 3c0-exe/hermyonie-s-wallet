import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/workspace/wallet_workspace.dart';

class PesowiseApp extends StatelessWidget {
  const PesowiseApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Hermyonie’s Wallet',
    theme: PesowiseTheme.theme,
    debugShowCheckedModeBanner: false,
    home: const WalletWorkspace(),
  );
}
