import 'package:hive/hive.dart';

part 'debt.g.dart';

@HiveType(typeId: 2)
class Debt extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String label;

  @HiveField(2)
  late double amount;

  @HiveField(3)
  late String creditor;

  @HiveField(4)
  late String walletId;

  @HiveField(5)
  DateTime? dueDate;

  @HiveField(6)
  late bool isRecurring;

  @HiveField(7)
  String? note;

  @HiveField(8)
  late DateTime createdAt;
}