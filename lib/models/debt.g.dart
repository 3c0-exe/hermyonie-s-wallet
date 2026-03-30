// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DebtAdapter extends TypeAdapter<Debt> {
  @override
  final int typeId = 2;

  @override
  Debt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Debt()
      ..id = fields[0] as String
      ..label = fields[1] as String
      ..amount = fields[2] as double
      ..creditor = fields[3] as String
      ..walletId = fields[4] as String
      ..dueDate = fields[5] as DateTime?
      ..isRecurring = fields[6] as bool
      ..note = fields[7] as String?
      ..createdAt = fields[8] as DateTime;
  }

  @override
  void write(BinaryWriter writer, Debt obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.creditor)
      ..writeByte(4)
      ..write(obj.walletId)
      ..writeByte(5)
      ..write(obj.dueDate)
      ..writeByte(6)
      ..write(obj.isRecurring)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
