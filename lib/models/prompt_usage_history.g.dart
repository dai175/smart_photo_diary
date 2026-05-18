// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prompt_usage_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PromptUsageHistoryAdapter extends TypeAdapter<PromptUsageHistory> {
  @override
  final typeId = 5;

  @override
  PromptUsageHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PromptUsageHistory(
      promptId: fields[0] as String,
      usedAt: fields[1] as DateTime?,
      diaryEntryId: fields[2] as String?,
      wasHelpful: fields[3] == null ? true : fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PromptUsageHistory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.promptId)
      ..writeByte(1)
      ..write(obj.usedAt)
      ..writeByte(2)
      ..write(obj.diaryEntryId)
      ..writeByte(3)
      ..write(obj.wasHelpful);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromptUsageHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
