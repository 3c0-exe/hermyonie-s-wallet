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
}