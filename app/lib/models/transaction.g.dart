// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 1;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      userId: fields[1] as String,
      transactionType: fields[2] as String,
      itemName: fields[3] as String,
      itemCategory: fields[4] as String?,
      quantity: fields[5] as int,
      price: fields[6] as int,
      transactionDate: fields[7] as DateTime,
      counterpartyName: fields[8] as String,
      counterpartyAddress: fields[9] as String,
      counterpartyAge: fields[10] as int?,
      counterpartyOccupation: fields[11] as String?,
      idVerificationType: fields[12] as String,
      idVerificationNumber: fields[13] as String?,
      photoUrl: fields[14] as String?,
      notes: fields[15] as String?,
      createdAt: fields[16] as DateTime,
      updatedAt: fields[17] as DateTime,
      pendingSync: fields[18] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.transactionType)
      ..writeByte(3)
      ..write(obj.itemName)
      ..writeByte(4)
      ..write(obj.itemCategory)
      ..writeByte(5)
      ..write(obj.quantity)
      ..writeByte(6)
      ..write(obj.price)
      ..writeByte(7)
      ..write(obj.transactionDate)
      ..writeByte(8)
      ..write(obj.counterpartyName)
      ..writeByte(9)
      ..write(obj.counterpartyAddress)
      ..writeByte(10)
      ..write(obj.counterpartyAge)
      ..writeByte(11)
      ..write(obj.counterpartyOccupation)
      ..writeByte(12)
      ..write(obj.idVerificationType)
      ..writeByte(13)
      ..write(obj.idVerificationNumber)
      ..writeByte(14)
      ..write(obj.photoUrl)
      ..writeByte(15)
      ..write(obj.notes)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.updatedAt)
      ..writeByte(18)
      ..write(obj.pendingSync);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
