import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/wallets/wallets_screen.dart';
import 'screens/transactions/transactions_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'widgets/bottom_nav.dart';

class PesowiseApp extends StatelessWidget {
  const PesowiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pesowise',
      theme: PesowiseTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    WalletsScreen(),
    TransactionsScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: PesowiseBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}