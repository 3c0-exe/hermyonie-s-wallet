// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jam_person.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JamPersonAdapter extends TypeAdapter<JamPerson> {
  @override
  final int typeId = 4;

  @override
  JamPerson read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JamPerson()
      ..id = fields[0] as String
      ..sessionId = fields[1] as String
      ..name = fields[2] as String
      ..isOwner = fields[3] as bool;
  }

  @override
  void write(BinaryWriter writer, JamPerson obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sessionId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.isOwner);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JamPersonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
