import 'package:hive/hive.dart';
part 'jam_session.g.dart';

@HiveType(typeId: 3)
class JamSession extends HiveObject {
  @HiveField(0)
  late String id;
  @HiveField(1)
  late String name;
  @HiveField(2)
  late DateTime createdAt;
  @HiveField(3)
  late bool isSettled;
}
