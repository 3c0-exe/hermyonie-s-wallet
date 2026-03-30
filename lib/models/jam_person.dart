import 'package:hive/hive.dart';
part 'jam_person.g.dart';

@HiveType(typeId: 4)
class JamPerson extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String sessionId;
  @HiveField(2) late String name;
  @HiveField(3) late bool isOwner;
}