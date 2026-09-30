import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/wallet.dart';
import '../models/transaction.dart';
import '../models/debt.dart';
import '../utils/money.dart';
import 'ledger_service.dart';
import 'transaction_service.dart';

class WalletService {
  static Box<Wallet> get _box => Hive.box<Wallet>('wallets');
  static List<Wallet> getAll({bool includeArchived = false}) =>
      _box.values.where((w) => includeArchived || !w.archived).toList();
  static double getTotalBalance() =>
      Money.sum(getAll().where((w) => !w.isLiability).map((w) => w.balance));
  static double getTotalOwed() =>
      Money.sum(getAll().where((w) => w.isLiability).map((w) => w.balance));
  static Future<void> add(
    String name,
    String icon,
    double initialBalance, {
    String accountType = 'cash',
    double? creditLimit,
    double? spendingCap,
    int? dueDay,
  }) => LedgerService.mutate(() async {
    if (name.trim().isEmpty) {
      throw const FormatException('Give your account a name.');
    }
    if (!['cash', 'bank', 'ewallet', 'credit', 'loan'].contains(accountType)) {
      throw const FormatException('Invalid account type.');
    }
    if (_box.values.any(
      (w) => !w.archived && w.name.toLowerCase() == name.trim().toLowerCase(),
    )) {
      throw const FormatException('An account with that name already exists.');
    }
    final w = Wallet()
      ..id = const Uuid().v4()
      ..name = name.trim()
      ..icon = icon
      ..balance = Money.normalize(initialBalance)
      ..createdAt = DateTime.now()
      ..accountType = accountType
      ..creditLimit = creditLimit == null ? null : Money.positive(creditLimit)
      ..spendingCap = spendingCap == null ? null : Money.positive(spendingCap)
      ..dueDay = dueDay;
    if (w.isLiability && w.balance < 0) {
      throw const FormatException('Amount owed cannot be negative.');
    }
    if (dueDay != null && (dueDay < 1 || dueDay > 31)) {
      throw const FormatException('Due day must be between 1 and 31.');
    }
    await _box.put(w.id, w);
  });
  static Future<void> updateBalance(String id, double balance) =>
      LedgerService.mutate(() async {
        final w = _box.get(id);
        if (w == null) throw const FormatException('Account not found.');
        balance = Money.normalize(balance);
        if (w.isLiability && balance < 0) {
          throw const FormatException('Amount owed cannot be negative.');
        }
        final delta = Money.add(balance, -w.balance);
        if (delta == 0) return;
        await TransactionService.writeEntry(
          walletId: id,
          label: 'Balance reconciliation',
          amount: delta.abs(),
          isExpense: w.isLiability ? delta > 0 : delta < 0,
          category: 'Adjustment',
          date: DateTime.now(),
          entryType: 'adjustment',
          note: 'Adjusted to match your statement.',
        );
      });
  static Future<void> setCap(String id, double amount) =>
      LedgerService.mutate(() async {
        final w = _box.get(id);
        if (w == null || !w.isLiability) {
          throw const FormatException('Choose a credit or loan account.');
        }
        w.spendingCap = Money.positive(amount);
        await w.save();
      });
  static Future<void> archive(String id) => LedgerService.mutate(() async {
    final w = _box.get(id);
    if (w == null) return;
    if (Money.cents(w.balance) != 0) {
      throw const FormatException(
        'Reconcile this account to zero before archiving it.',
      );
    }
    if (Hive.box<Debt>(
      'debts',
    ).values.any((d) => d.walletId == id && !d.isPaid)) {
      throw const FormatException(
        'Move or finish this account’s obligations first.',
      );
    }
    w.archived = true;
    await w.save();
  });
  static Future<void> delete(String id) => LedgerService.mutate(() async {
    if (Hive.box<Transaction>(
          'transactions',
        ).values.any((t) => t.walletId == id || t.toWalletId == id) ||
        Hive.box<Debt>('debts').values.any((d) => d.walletId == id)) {
      throw const FormatException(
        'This account has history. Archive it instead.',
      );
    }
    await _box.delete(id);
  });
}
