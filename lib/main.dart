import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/wallet.dart';
import 'models/transaction.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(WalletAdapter());
  Hive.registerAdapter(TransactionAdapter());
  await Hive.openBox<Wallet>('wallets');
  await Hive.openBox<Transaction>('transactions');
  runApp(const PesowiseApp());
}