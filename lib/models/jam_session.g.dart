// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jam_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JamSessionAdapter extends TypeAdapter<JamSession> {
  @override
  final int typeId = 3;

  @override
  JamSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JamSession()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..createdAt = fields[2] as DateTime
      ..isSettled = fields[3] as bool;
  }

  @override
  void write(BinaryWriter writer, JamSession obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.isSettled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JamSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
