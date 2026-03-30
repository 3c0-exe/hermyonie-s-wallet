import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/wallet.dart';
import 'models/transaction.dart';
import 'models/debt.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(WalletAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(DebtAdapter());
  await Hive.openBox<Wallet>('wallets');
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Debt>('debts');
  runApp(const PesowiseApp());
}