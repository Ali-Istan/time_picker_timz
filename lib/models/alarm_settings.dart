import 'package:hive/hive.dart';

part 'alarm_settings.g.dart';

@HiveType(typeId: 0)
class AlarmSettings extends HiveObject {
  @HiveField(0)
  late double startAngle;

  @HiveField(1)
  late double endAngle;

  @HiveField(2)
  late bool isAlarmEnabled;

  @HiveField(3)
  late bool isSnoozeEnabled;

  @HiveField(4)
  late double alarmVolume;

  @HiveField(5)
  late String selectedAlarmPath;

  @HiveField(6)
  late double sleepDuration;

  @HiveField(7)
  late double wakeDuration;
}
