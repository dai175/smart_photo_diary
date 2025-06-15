// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubscriptionStatusAdapter extends TypeAdapter<SubscriptionStatus> {
  @override
  final int typeId = 2;

  @override
  SubscriptionStatus read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubscriptionStatus(
      planId: fields[0] as String,
      isActive: fields[1] as bool,
      startDate: fields[2] as DateTime?,
      expiryDate: fields[3] as DateTime?,
      monthlyUsageCount: fields[4] as int,
      usageMonth: fields[5] as String?,
      lastResetDate: fields[6] as DateTime?,
      autoRenewal: fields[7] as bool,
      transactionId: fields[8] as String?,
      lastPurchaseDate: fields[9] as DateTime?,
      cancelDate: fields[10] as DateTime?,
      planChangeDate: fields[11] as DateTime?,
      pendingPlanId: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SubscriptionStatus obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.planId)
      ..writeByte(1)
      ..write(obj.isActive)
      ..writeByte(2)
      ..write(obj.startDate)
      ..writeByte(3)
      ..write(obj.expiryDate)
      ..writeByte(4)
      ..write(obj.monthlyUsageCount)
      ..writeByte(5)
      ..write(obj.usageMonth)
      ..writeByte(6)
      ..write(obj.lastResetDate)
      ..writeByte(7)
      ..write(obj.autoRenewal)
      ..writeByte(8)
      ..write(obj.transactionId)
      ..writeByte(9)
      ..write(obj.lastPurchaseDate)
      ..writeByte(10)
      ..write(obj.cancelDate)
      ..writeByte(11)
      ..write(obj.planChangeDate)
      ..writeByte(12)
      ..write(obj.pendingPlanId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
