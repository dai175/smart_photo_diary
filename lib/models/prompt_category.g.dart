// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prompt_category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PromptCategoryAdapter extends TypeAdapter<PromptCategory> {
  @override
  final typeId = 3;

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
      case PromptCategory.emotionDepth:
        writer.writeByte(1);
      case PromptCategory.sensoryEmotion:
        writer.writeByte(2);
      case PromptCategory.emotionGrowth:
        writer.writeByte(3);
      case PromptCategory.emotionConnection:
        writer.writeByte(4);
      case PromptCategory.emotionDiscovery:
        writer.writeByte(5);
      case PromptCategory.emotionFantasy:
        writer.writeByte(6);
      case PromptCategory.emotionHealing:
        writer.writeByte(7);
      case PromptCategory.emotionEnergy:
        writer.writeByte(8);
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
