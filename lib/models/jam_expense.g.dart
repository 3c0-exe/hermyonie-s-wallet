// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jam_expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JamExpenseAdapter extends TypeAdapter<JamExpense> {
  @override
  final int typeId = 5;

  @override
  JamExpense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JamExpense()
      ..id = fields[0] as String
      ..personId = fields[1] as String
      ..sessionId = fields[2] as String
      ..description = fields[3] as String
      ..amount = fields[4] as double;
  }

  @override
  void write(BinaryWriter writer, JamExpense obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.personId)
      ..writeByte(2)
      ..write(obj.sessionId)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.amount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JamExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
