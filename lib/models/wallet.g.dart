// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WalletAdapter extends TypeAdapter<Wallet> {
  @override
  final int typeId = 0;

  @override
  Wallet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Wallet()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..balance = fields[2] as double
      ..icon = fields[3] as String
      ..createdAt = fields[4] as DateTime
      ..accountType = fields[5] == null ? 'cash' : fields[5] as String
      ..creditLimit = fields[6] as double?
      ..spendingCap = fields[7] as double?
      ..dueDay = fields[8] as int?
      ..archived = fields[9] == null ? false : fields[9] as bool;
  }

  @override
  void write(BinaryWriter writer, Wallet obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.balance)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.accountType)
      ..writeByte(6)
      ..write(obj.creditLimit)
      ..writeByte(7)
      ..write(obj.spendingCap)
      ..writeByte(8)
      ..write(obj.dueDay)
      ..writeByte(9)
      ..write(obj.archived);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
