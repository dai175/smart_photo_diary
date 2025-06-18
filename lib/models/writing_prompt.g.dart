// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'writing_prompt.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WritingPromptAdapter extends TypeAdapter<WritingPrompt> {
  @override
  final int typeId = 4;

  @override
  WritingPrompt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WritingPrompt(
      id: fields[0] as String,
      text: fields[1] as String,
      category: fields[2] as PromptCategory,
      isPremiumOnly: fields[3] as bool,
      tags: (fields[4] as List).cast<String>(),
      description: fields[5] as String?,
      priority: fields[6] as int,
      createdAt: fields[7] as DateTime?,
      isActive: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, WritingPrompt obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.isPremiumOnly)
      ..writeByte(4)
      ..write(obj.tags)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.priority)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WritingPromptAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PromptUsageHistoryAdapter extends TypeAdapter<PromptUsageHistory> {
  @override
  final int typeId = 5;

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
      wasHelpful: fields[3] as bool,
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

class PromptCategoryAdapter extends TypeAdapter<PromptCategory> {
  @override
  final int typeId = 3;

  @override
  PromptCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PromptCategory.emotion;
      case 1:
        return PromptCategory.emotionDepth;
      case 2:
        return PromptCategory.sensoryEmotion;
      case 3:
        return PromptCategory.emotionGrowth;
      case 4:
        return PromptCategory.emotionConnection;
      case 5:
        return PromptCategory.emotionDiscovery;
      case 6:
        return PromptCategory.emotionFantasy;
      case 7:
        return PromptCategory.emotionHealing;
      case 8:
        return PromptCategory.emotionEnergy;
      default:
        return PromptCategory.emotion;
    }
  }

  @override
  void write(BinaryWriter writer, PromptCategory obj) {
    switch (obj) {
      case PromptCategory.emotion:
        writer.writeByte(0);
        break;
      case PromptCategory.emotionDepth:
        writer.writeByte(1);
        break;
      case PromptCategory.sensoryEmotion:
        writer.writeByte(2);
        break;
      case PromptCategory.emotionGrowth:
        writer.writeByte(3);
        break;
      case PromptCategory.emotionConnection:
        writer.writeByte(4);
        break;
      case PromptCategory.emotionDiscovery:
        writer.writeByte(5);
        break;
      case PromptCategory.emotionFantasy:
        writer.writeByte(6);
        break;
      case PromptCategory.emotionHealing:
        writer.writeByte(7);
        break;
      case PromptCategory.emotionEnergy:
        writer.writeByte(8);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromptCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
