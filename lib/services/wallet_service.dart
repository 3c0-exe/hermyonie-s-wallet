import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/wallet.dart';
import '../core/hive_boxes.dart';
import '../models/transaction.dart';

class WalletService {
  static Box<Wallet> get _box => Hive.box<Wallet>(HiveBoxes.wallets);
  static const _uuid = Uuid();

  static List<Wallet> getAll() => _box.values.toList();

  static double getTotalBalance() =>
      _box.values.fold(0.0, (sum, w) => sum + w.balance);

  static Future<void> add(String name, String icon, double initialBalance) async {
    final wallet = Wallet()
      ..id = _uuid.v4()
      ..name = name
      ..icon = icon
      ..balance = initialBalance
      ..createdAt = DateTime.now();
    await _box.put(wallet.id, wallet);
  }

  static Future<void> updateBalance(String walletId, double newBalance) async {
    final wallet = _box.get(walletId);
    if (wallet != null) {
      wallet.balance = newBalance;
      await wallet.save();
    }
  }

static Future<void> delete(String walletId) async {
  final txBox = Hive.box<Transaction>(HiveBoxes.transactions);
  final txToDelete = txBox.values
      .where((t) => t.walletId == walletId)
      .map((t) => t.id)
      .toList();
  for (final id in txToDelete) {
    await txBox.delete(id);
  }
  await _box.delete(walletId);
}
}