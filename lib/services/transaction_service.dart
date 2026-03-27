import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../core/hive_boxes.dart';

class TransactionService {
  static Box<Transaction> get _box =>
      Hive.box<Transaction>(HiveBoxes.transactions);
  static Box<Wallet> get _walletBox => Hive.box<Wallet>(HiveBoxes.wallets);
  static const _uuid = Uuid();

  static List<Transaction> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  static List<Transaction> getForWallet(String walletId) {
    final list = _box.values.where((t) => t.walletId == walletId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  static Future<void> add({
    required String walletId,
    required String label,
    required double amount,
    required bool isExpense,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    final tx = Transaction()
      ..id = _uuid.v4()
      ..walletId = walletId
      ..label = label
      ..amount = amount
      ..isExpense = isExpense
      ..category = category
      ..date = date
      ..note = note;
    await _box.put(tx.id, tx);

    // Update wallet balance
    final wallet = _walletBox.get(walletId);
    if (wallet != null) {
      wallet.balance += isExpense ? -amount : amount;
      await wallet.save();
    }
  }

  static Future<void> delete(String txId) async {
    final tx = _box.get(txId);
    if (tx == null) return;

    // Reverse the balance effect
    final wallet = _walletBox.get(tx.walletId);
    if (wallet != null) {
      wallet.balance += tx.isExpense ? tx.amount : -tx.amount;
      await wallet.save();
    }
    await _box.delete(txId);
  }

  static Map<String, double> getSpendingByCategory() {
    final Map<String, double> result = {};
    for (final tx in _box.values.where((t) => t.isExpense)) {
      result[tx.category] = (result[tx.category] ?? 0) + tx.amount;
    }
    return result;
  }
}