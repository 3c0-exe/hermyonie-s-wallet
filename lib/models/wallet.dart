import 'package:hive/hive.dart';

part 'wallet.g.dart';

@HiveType(typeId: 0)
class Wallet extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late double balance;

  @HiveField(3)
  late String icon;

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5, defaultValue: 'cash')
  String accountType = 'cash';
  @HiveField(6)
  double? creditLimit;
  @HiveField(7)
  double? spendingCap;
  @HiveField(8)
  int? dueDay;
  @HiveField(9, defaultValue: false)
  bool archived = false;

  bool get isLiability => accountType == 'credit' || accountType == 'loan';
  String get typeLabel => switch (accountType) {
    'bank' => 'Bank account',
    'ewallet' => 'E-wallet',
    'credit' => 'Credit card',
    'loan' => 'Loan account',
    _ => 'Cash',
  };
}
