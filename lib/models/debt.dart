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

  @HiveField(9)
  double? installmentAmount;
  @HiveField(10)
  double? totalAmount;
  @HiveField(11, defaultValue: 0.0)
  double paidAmount = 0;
  @HiveField(12, defaultValue: false)
  bool isPaid = false;

  @HiveField(13)
  int? anchorDay;

  double get nextPayment =>
      installmentAmount != null && installmentAmount! < amount
      ? installmentAmount!
      : amount;
}
