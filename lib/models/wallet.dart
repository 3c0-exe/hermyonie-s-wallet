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
}