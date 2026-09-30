import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/debt.dart';
import '../models/wallet.dart';
import '../models/transaction.dart';
import '../utils/money.dart';
import 'ledger_service.dart';
import 'store_codec.dart';
import 'transaction_service.dart';

class DebtService {
  static Box<Debt> get _box => Hive.box<Debt>('debts');
  static List<Debt> getAll({bool includePaid = false}) =>
      _box.values.where((d) => includePaid || !d.isPaid).toList()..sort(
        (a, b) => (a.dueDate ?? DateTime(9999)).compareTo(
          b.dueDate ?? DateTime(9999),
        ),
      );
  static double getTotalDebt() => Money.sum(getAll().map((d) => d.amount));
  static DateTime nextMonth(DateTime date, {int? anchorDay}) {
    final lastDay = DateTime(date.year, date.month + 2, 0).day;
    return DateTime(
      date.year,
      date.month + 1,
      (anchorDay ?? date.day) > lastDay ? lastDay : (anchorDay ?? date.day),
    );
  }

  static Future<void> add({
    required String label,
    required double amount,
    required String creditor,
    required String walletId,
    DateTime? dueDate,
    bool isRecurring = false,
    String? note,
    double? installmentAmount,
  }) => LedgerService.mutate(() async {
    final wallet = Hive.box<Wallet>('wallets').get(walletId);
    if (wallet == null || wallet.archived || wallet.isLiability) {
      throw const FormatException('Choose a cash account to pay from.');
    }
    if (label.trim().isEmpty || creditor.trim().isEmpty) {
      throw const FormatException('Add a description and payee.');
    }
    if (isRecurring && dueDate == null) {
      throw const FormatException('Recurring bills need a due date.');
    }
    if (isRecurring && installmentAmount != null) {
      throw const FormatException('Choose recurring bill or installment plan.');
    }
    final d = Debt()
      ..id = const Uuid().v4()
      ..label = label.trim()
      ..amount = Money.positive(amount)
      ..creditor = creditor.trim()
      ..walletId = walletId
      ..dueDate = dueDate
      ..anchorDay = dueDate?.day
      ..isRecurring = isRecurring
      ..note = note
      ..createdAt = DateTime.now()
      ..totalAmount = Money.positive(amount)
      ..installmentAmount = installmentAmount == null
          ? null
          : Money.positive(installmentAmount);
    if (d.installmentAmount != null && d.installmentAmount! > d.amount) {
      throw const FormatException('Installment exceeds the total owed.');
    }
    await _box.put(d.id, d);
  });
  static Future<void> markAsPaid(
    String id, {
    double? amount,
  }) => LedgerService.mutate(() async {
    final d = _box.get(id);
    if (d == null || d.isPaid) {
      throw const FormatException('This obligation is already paid.');
    }
    final payment = Money.positive(amount ?? d.nextPayment);
    if (Money.cents(payment) > Money.cents(d.amount)) {
      throw const FormatException('Payment exceeds the remaining obligation.');
    }
    final wallet = Hive.box<Wallet>('wallets').get(d.walletId);
    if (wallet == null || wallet.isLiability || wallet.archived) {
      throw const FormatException('Choose an active cash account.');
    }
    if (Money.cents(wallet.balance) < Money.cents(payment)) {
      throw const FormatException('Not enough funds in the payment account.');
    }
    await TransactionService.writeEntry(
      walletId: d.walletId,
      label: d.label,
      amount: payment,
      isExpense: true,
      category: 'Bills & Utilities',
      date: DateTime.now(),
      note: 'Payment · ${d.creditor}',
      debtId: d.id,
      debtBefore: jsonEncode(StoreCodec.debt(d)),
    );
    d.totalAmount ??= d.amount;
    d.anchorDay ??= d.dueDate?.day;
    d.amount = Money.add(d.amount, -payment);
    d.paidAmount = Money.add(d.paidAmount, payment);
    if (d.amount == 0) {
      if (d.isRecurring) {
        d.amount = d.totalAmount!;
        d.dueDate = nextMonth(
          d.dueDate ?? DateTime.now(),
          anchorDay: d.anchorDay,
        );
      } else {
        d.isPaid = true;
      }
    } else if (d.installmentAmount != null &&
        Money.cents(payment) >= Money.cents(d.installmentAmount!)) {
      d.dueDate = nextMonth(
        d.dueDate ?? DateTime.now(),
        anchorDay: d.anchorDay,
      );
    }
    await d.save();
  });
  static Future<void> delete(String id) => LedgerService.mutate(() async {
    if (Hive.box<Transaction>(
      'transactions',
    ).values.any((t) => t.debtId == id)) {
      throw const FormatException(
        'This obligation has payment history and cannot be deleted.',
      );
    }
    await _box.delete(id);
  });
}
