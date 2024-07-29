// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlarmSettingsAdapter extends TypeAdapter<AlarmSettings> {
  @override
  final int typeId = 0;

  @override
  AlarmSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmSettings()
      ..startAngle = fields[0] as double
      ..endAngle = fields[1] as double
      ..isAlarmEnabled = fields[2] as bool
      ..isSnoozeEnabled = fields[3] as bool
      ..alarmVolume = fields[4] as double
      ..selectedAlarmPath = fields[5] as String
      ..sleepDuration = fields[6] as double
      ..wakeDuration = fields[7] as double;
  }

  @override
  void write(BinaryWriter writer, AlarmSettings obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.startAngle)
      ..writeByte(1)
      ..write(obj.endAngle)
      ..writeByte(2)
      ..write(obj.isAlarmEnabled)
      ..writeByte(3)
      ..write(obj.isSnoozeEnabled)
      ..writeByte(4)
      ..write(obj.alarmVolume)
      ..writeByte(5)
      ..write(obj.selectedAlarmPath)
      ..writeByte(6)
      ..write(obj.sleepDuration)
      ..writeByte(7)
      ..write(obj.wakeDuration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
