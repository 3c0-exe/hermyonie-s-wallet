import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/debt.dart';
import '../core/hive_boxes.dart';
import 'transaction_service.dart';

class DebtService {
  static Box<Debt> get _box => Hive.box<Debt>(HiveBoxes.debts);
  static const _uuid = Uuid();

  static List<Debt> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) {
        return b.createdAt.compareTo(a.createdAt);
      }
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    return list;
  }

  static double getTotalDebt() =>
      _box.values.fold(0.0, (sum, d) => sum + d.amount);

  static Future<void> add({
    required String label,
    required double amount,
    required String creditor,
    required String walletId,
    DateTime? dueDate,
    bool isRecurring = false,
    String? note,
  }) async {
    final debt = Debt()
      ..id = _uuid.v4()
      ..label = label
      ..amount = amount
      ..creditor = creditor
      ..walletId = walletId
      ..dueDate = dueDate
      ..isRecurring = isRecurring
      ..note = note
      ..createdAt = DateTime.now();
    await _box.put(debt.id, debt);
  }

  static Future<void> markAsPaid(String debtId) async {
    final debt = _box.get(debtId);
    if (debt == null) return;

    await TransactionService.add(
      walletId: debt.walletId,
      label: debt.label,
      amount: debt.amount,
      isExpense: true,
      category: 'Bills & Utilities',
      date: DateTime.now(),
      note: 'Paid · ${debt.creditor}${debt.note != null ? ' · ${debt.note}' : ''}',
    );

    await _box.delete(debtId);
  }

  static Future<void> delete(String debtId) async {
    await _box.delete(debtId);
  }
}