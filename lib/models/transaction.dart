import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
class Transaction extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String walletId;

  @HiveField(2)
  late String label;

  @HiveField(3)
  late double amount;

  @HiveField(4)
  late bool isExpense;

  @HiveField(5)
  late String category;

  @HiveField(6)
  late DateTime date;

  @HiveField(7)
  String? note;

  @HiveField(8, defaultValue: 'standard')
  String entryType = 'standard';
  @HiveField(9)
  String? toWalletId;
  @HiveField(10)
  String? debtId;
  @HiveField(11)
  String? debtBefore;
  @HiveField(12)
  String? externalId;

  bool get isTransfer => entryType == 'transfer' || entryType == 'repayment';
  bool get countsAsSpending => entryType == 'standard' && isExpense;
  bool get countsAsIncome => entryType == 'standard' && !isExpense;
}
