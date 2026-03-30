import 'package:hive/hive.dart';
part 'jam_expense.g.dart';

@HiveType(typeId: 5)
class JamExpense extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String personId;
  @HiveField(2) late String sessionId;
  @HiveField(3) late String description;
  @HiveField(4) late double amount;
}