// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'writing_prompt.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WritingPromptAdapter extends TypeAdapter<WritingPrompt> {
  @override
  final typeId = 4;

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
      isPremiumOnly: fields[3] == null ? false : fields[3] as bool,
      tags: fields[4] == null ? const [] : (fields[4] as List).cast<String>(),
      description: fields[5] as String?,
      priority: fields[6] == null ? 0 : (fields[6] as num).toInt(),
      createdAt: fields[7] as DateTime?,
      isActive: fields[8] == null ? true : fields[8] as bool,
      localizedTexts: (fields[9] as Map?)?.cast<String, String>(),
      localizedDescriptions: (fields[10] as Map?)?.cast<String, String>(),
      localizedTags: (fields[11] as Map?)?.map(
        (dynamic k, dynamic v) =>
            MapEntry(k as String, (v as List).cast<String>()),
      ),
    );
  }

  @override
  void write(BinaryWriter writer, WritingPrompt obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.isActive)
      ..writeByte(9)
      ..write(obj.localizedTexts)
      ..writeByte(10)
      ..write(obj.localizedDescriptions)
      ..writeByte(11)
      ..write(obj.localizedTags);
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
