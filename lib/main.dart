import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/wallet.dart';
import 'models/transaction.dart';
import 'models/debt.dart';
import 'models/jam_session.dart';
import 'models/jam_person.dart';
import 'models/jam_expense.dart';
import 'app.dart';
import 'services/ledger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(WalletAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(DebtAdapter());
  Hive.registerAdapter(JamSessionAdapter());
  Hive.registerAdapter(JamPersonAdapter());
  Hive.registerAdapter(JamExpenseAdapter());
  await Hive.openBox<Wallet>('wallets');
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Debt>('debts');
  await Hive.openBox<JamSession>('jamSessions');
  await Hive.openBox<JamPerson>('jamPersons');
  await Hive.openBox<JamExpense>('jamExpenses');
  await LedgerService.initialize();
  runApp(const PesowiseApp());
}
