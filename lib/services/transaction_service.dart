import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/debt.dart';
import '../utils/money.dart';
import 'ledger_service.dart';
import 'store_codec.dart';

class TransactionService {
  static Box<Transaction> get _box => Hive.box<Transaction>('transactions');
  static Box<Wallet> get _wallets => Hive.box<Wallet>('wallets');
  static List<Transaction> getAll() =>
      _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  static List<Transaction> getForWallet(String id) =>
      getAll().where((t) => t.walletId == id || t.toWalletId == id).toList();
  static Future<void> add({
    required String walletId,
    required String label,
    required double amount,
    required bool isExpense,
    required String category,
    required DateTime date,
    String? note,
    String? externalId,
  }) => LedgerService.mutate(
    () => writeEntry(
      walletId: walletId,
      label: label,
      amount: amount,
      isExpense: isExpense,
      category: category,
      date: date,
      note: note,
      externalId: externalId,
    ),
  );

  /// Internal write used inside a single journaled operation.
  static Future<void> writeEntry({
    required String walletId,
    required String label,
    required double amount,
    required bool isExpense,
    required String category,
    required DateTime date,
    String? note,
    String entryType = 'standard',
    String? toWalletId,
    String? debtId,
    String? debtBefore,
    String? externalId,
  }) async {
    final wallet = _wallets.get(walletId);
    if (wallet == null || wallet.archived) {
      throw const FormatException('Choose an active account.');
    }
    if (label.trim().isEmpty) throw const FormatException('Add a description.');
    amount = Money.positive(amount);
    if (externalId != null &&
        _box.values.any((t) => t.externalId == externalId)) {
      throw const FormatException('This transaction was already imported.');
    }
    final tx = Transaction()
      ..id = const Uuid().v4()
      ..walletId = walletId
      ..label = label.trim()
      ..amount = amount
      ..isExpense = isExpense
      ..category = category
      ..date = date
      ..note = note
      ..entryType = entryType
      ..toWalletId = toWalletId
      ..debtId = debtId
      ..debtBefore = debtBefore
      ..externalId = externalId;
    final factor = wallet.isLiability ? -1 : 1;
    wallet.balance = Money.add(
      wallet.balance,
      (isExpense ? -amount : amount) * factor,
    );
    await wallet.save();
    await _box.put(tx.id, tx);
  }

  static Future<void> transfer({
    required String fromId,
    required String toId,
    required double amount,
    String? note,
  }) => LedgerService.mutate(() async {
    final from = _wallets.get(fromId), to = _wallets.get(toId);
    amount = Money.positive(amount);
    if (from == null ||
        to == null ||
        from.archived ||
        to.archived ||
        fromId == toId) {
      throw const FormatException('Choose two different active accounts.');
    }
    if (from.isLiability) {
      throw const FormatException(
        'Transfers must come from a cash, bank or e-wallet account.',
      );
    }
    if (Money.cents(from.balance) < Money.cents(amount)) {
      throw const FormatException('The source account has insufficient funds.');
    }
    if (to.isLiability && Money.cents(amount) > Money.cents(to.balance)) {
      throw const FormatException('Repayment exceeds the amount owed.');
    }
    await writeEntry(
      walletId: fromId,
      label:
          '${to.isLiability ? 'Repayment' : 'Transfer'} · ${from.name} → ${to.name}',
      amount: amount,
      isExpense: true,
      category: to.isLiability ? 'Repayment' : 'Transfer',
      date: DateTime.now(),
      entryType: to.isLiability ? 'repayment' : 'transfer',
      toWalletId: toId,
      note: note,
    );
    to.balance = Money.add(to.balance, to.isLiability ? -amount : amount);
    await to.save();
  });
  static Future<void> delete(String id) => LedgerService.mutate(() async {
    final tx = _box.get(id);
    if (tx == null) return;
    if (tx.debtId != null) {
      final related = _box.values.where((t) => t.debtId == tx.debtId).toList();
      if (related.last.id != id) {
        throw const FormatException(
          'Undo the latest payment on this obligation first.',
        );
      }
      if (tx.debtBefore != null) {
        final restored = StoreCodec.readDebt(jsonDecode(tx.debtBefore!) as Map);
        await Hive.box<Debt>('debts').put(restored.id, restored);
      }
    }
    final w = _wallets.get(tx.walletId);
    if (w != null) {
      w.balance = Money.add(
        w.balance,
        (tx.isExpense ? tx.amount : -tx.amount) * (w.isLiability ? -1 : 1),
      );
      await w.save();
    }
    final target = tx.toWalletId == null ? null : _wallets.get(tx.toWalletId);
    if (target != null) {
      target.balance = Money.add(
        target.balance,
        target.isLiability ? tx.amount : -tx.amount,
      );
      await target.save();
    }
    await _box.delete(id);
  });
  static Map<String, double> getSpendingByCategory({DateTime? month}) {
    final m = month ?? DateTime.now();
    final result = <String, double>{};
    for (final t in _box.values.where(
      (t) =>
          t.countsAsSpending &&
          t.date.year == m.year &&
          t.date.month == m.month,
    )) {
      result[t.category] = Money.add(result[t.category] ?? 0, t.amount);
    }
    return result;
  }
}
