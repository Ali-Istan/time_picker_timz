import 'dart:async';
import 'dart:io';

import 'dart:math';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import 'package:tank_time_picker/Tools/my_colors.dart';
import 'package:tank_time_picker/Tools/my_tools.dart';
import 'package:tank_time_picker/main.dart';
import 'package:vibration/vibration.dart';
import 'package:workmanager/workmanager.dart';
import '../Tools/RoundedArcPainter.dart';
import '../models/alarm_settings.dart';
import '../services/forground_background_services.dart';
import '../services/initial_notif.dart';

class SleepSchedulePage extends StatefulWidget {
  @override
  _SleepSchedulePageState createState() => _SleepSchedulePageState();
}

class _SleepSchedulePageState extends State<SleepSchedulePage> {
  double startAngle = 270 * pi / 180; // Midnight
  double endAngle = 330 * pi / 180; // 1 AM
  bool draggingStartHandle = false;
  bool draggingEndHandle = false;
  bool draggingWholeHandle = false;
  double initialAngle = 0.0;

  // final AudioPlayer audioPlayer = AudioPlayer();
  // String selectedAlarmPath = 'alarms/default_alarm.mp3'; // مسیر آهنگ پیش‌فرض
  // String selectedAlarmName = 'Default Alarm';
  // double alarmVolume = 0.5;
  // bool isAlarmEnabled = true; // Variable to store the state of the alarm switch
  // bool isSnoozeEnabled = false;
  Timer? alarmTimer;

  String alarmName = 'Default Alarm Name'; // فیلد جدید
  late Box<AlarmSettings> alarmSettingsBox;

  DateTime sleepTime = DateTime.now();
  DateTime wakeTime = DateTime.now();
  double sleepDuration = 0;
  double wakeDuration = 0;

  @override
  void initState() {
    super.initState();

    initializeHive();
    audioPlayer.setReleaseMode(ReleaseMode.loop);
    _setAlarm(); // Set the alarm when initializing
  }

  Future<void> initializeHive() async {
    if (Hive.isBoxOpen('alarmSettingsBox')) {
      alarmSettingsBox = Hive.box<AlarmSettings>('alarmSettingsBox');
    } else {
      alarmSettingsBox = await Hive.openBox<AlarmSettings>('alarmSettingsBox');
    }
    loadSettings();
  }

  Future<void> loadSettings() async {
    // Load settings from Hive
    if (alarmSettingsBox.isNotEmpty) {
      final settings = alarmSettingsBox.getAt(0);
      if (settings != null) {
        setState(() {
          startAngle = settings.startAngle;
          endAngle = settings.endAngle;
          isAlarmEnabled = settings.isAlarmEnabled;
          isSnoozeEnabled = settings.isSnoozeEnabled;
          alarmVolume = settings.alarmVolume;
          selectedAlarmPath = settings.selectedAlarmPath;
          sleepDuration = settings.sleepDuration;
          wakeDuration = settings.wakeDuration;
        });
      }
    }
    _setAlarm(); // Set the alarm when settings are loaded
  }

  // void _scheduleSnooze() {
  //   Timer(const Duration(minutes: 10), () {
  //     _playAlarm();
  //     BackForGroundServices.showNotification();
  //   });
  // }
  //
  // void _playAlarm() async {
  //   if (selectedAlarmPath.startsWith('alarms/')) {
  //     await audioPlayer.setVolume(alarmVolume);
  //     await audioPlayer.play(AssetSource(selectedAlarmPath));
  //   } else {
  //     await audioPlayer.setVolume(alarmVolume);
  //     await audioPlayer.play(DeviceFileSource(selectedAlarmPath));
  //   }
  //
  //   if (isSnoozeEnabled) {
  //     _scheduleSnooze();
  //   }
  // }

  void _setAlarm() async {
    if (!isAlarmEnabled) return; // If alarm is not enabled, return early

    final now = DateTime.now();
    var wakeupTime = DateTime(
      now.year,
      now.month,
      now.day,
      getTimeFromAngle(endAngle).hour,
      getTimeFromAngle(endAngle).minute,
    );

    if (wakeupTime.isBefore(now)) {
      wakeupTime = wakeupTime.add(const Duration(days: 1));
    }
    Duration durationUntilAlarm = wakeupTime.difference(now);

    await AndroidAlarmManager.oneShot(
      durationUntilAlarm,
      4,
      backgroundAlarmCallback,
      exact: true,
      wakeup: true,
    );

    setState(() {
      sleepTime = now;
      wakeTime = wakeupTime;
      sleepDuration = (sweepAngle / (2 * pi)) * 24; // Calculate sleep duration
      wakeDuration = 24 - sleepDuration; // Calculate wake duration
    });

    debugPrint("durationUntilAlarm ${durationUntilAlarm.toString()}");
    debugPrint("wakeupTime ${wakeupTime.toString()}");
    // await Future.delayed(durationUntilAlarm).then((value) {
    //   playAlarm();
    //   BackForGroundServices.showNotification();
    // });
  }

  void _saveSettings() {
    final settings = AlarmSettings()
      ..startAngle = startAngle
      ..endAngle = endAngle
      ..isAlarmEnabled = isAlarmEnabled
      ..isSnoozeEnabled = isSnoozeEnabled
      ..alarmVolume = alarmVolume
      ..selectedAlarmPath = selectedAlarmPath
      ..sleepDuration = sleepDuration // Save sleep duration
      ..wakeDuration = wakeDuration; // Save wake duration

    if (alarmSettingsBox.isEmpty) {
      alarmSettingsBox.add(settings);
    } else {
      alarmSettingsBox.putAt(0, settings);
    }
  }

  Future<void> _requestPermissionsAndOpenFilePicker() async {
    bool storagePermission = await Permission.storage.request().isGranted;
    bool manageExternalStoragePermission =
        await Permission.manageExternalStorage.request().isGranted;

    if (storagePermission || manageExternalStoragePermission) {
      _openFilePicker();
    } else {
      MyTools.showPermissionDialog(context, "File Permission",
          "This app needs access to your File. Do you allow it?", "Accept");
    }
  }

  Future<void> _openFilePicker() async {
    debugPrint("Selecting file...");
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.audio);

    if (result != null) {
      File file = File(result.files.single.path!);
      setState(() {
        selectedAlarmPath = file.path;
        selectedAlarmName = result.files.single.name;
        _saveSettings(); // Save settings when alarm path is changed
      });
    } else {
      // User canceled the picker
    }
  }

  void _stopAlarm() async {
    await audioPlayer.stop();
    audioPlayer.dispose();
  }

  void _onDragStart(DragStartDetails details, Size size) {
    final touchPosition = details.localPosition;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final startHandlePosition = Offset(
      center.dx + radius * cos(startAngle),
      center.dy + radius * sin(startAngle),
    );
    final endHandlePosition = Offset(
      center.dx + radius * cos(endAngle),
      center.dy + radius * sin(endAngle),
    );

    const double handleRadius = 20.0; // شعاع قابل درگ
    const double centerRadius = 10.0; // شعاع ناحیه مرکزی دستگیره

    final startHandleDistance = (touchPosition - startHandlePosition).distance;
    final endHandleDistance = (touchPosition - endHandlePosition).distance;

    setState(() {
      draggingStartHandle = startHandleDistance <= handleRadius &&
          startHandleDistance > centerRadius;
      draggingEndHandle =
          endHandleDistance <= handleRadius && endHandleDistance > centerRadius;

      if (!draggingStartHandle && !draggingEndHandle) {
        final touchAngle = _calculateAngle(touchPosition, center);
        draggingWholeHandle = (touchAngle >= min(startAngle, endAngle) &&
                touchAngle <= max(startAngle, endAngle)) ||
            (startAngle > endAngle &&
                (touchAngle >= startAngle || touchAngle <= endAngle));

        if (draggingWholeHandle) {
          initialAngle = touchAngle;
        }
      }

      // ویبره کوچک هنگام شروع درگ کردن
      if (draggingStartHandle || draggingEndHandle || draggingWholeHandle) {
        _vibrate();
      }
    });
  }

  double _calculateAngle(Offset touchPosition, Offset center) {
    final angle =
        atan2(touchPosition.dy - center.dy, touchPosition.dx - center.dx);
    return angle < 0 ? angle + 2 * pi : angle;
  }

  void _onDragUpdate(DragUpdateDetails details, Size size) {
    final touchPosition = details.localPosition;
    final center = Offset(size.width / 2, size.height / 2);

    final angle = _calculateAngle(touchPosition, center);

    setState(() {
      if (draggingStartHandle) {
        startAngle = angle;
      } else if (draggingEndHandle) {
        endAngle = angle;
      } else if (draggingWholeHandle) {
        final offsetAngle = angle - initialAngle;
        startAngle = (startAngle + offsetAngle) % (2 * pi);
        endAngle = (endAngle + offsetAngle) % (2 * pi);
        initialAngle = angle;
      }

      // ویبره کوچک هنگام به‌روزرسانی درگ کردن
      if (draggingStartHandle || draggingEndHandle || draggingWholeHandle) {
        _vibrate();
      }
    });

    _setAlarm(); // Update alarm time on drag update
    _saveSettings(); // Save settings on drag update
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      draggingStartHandle = false;
      draggingEndHandle = false;
      draggingWholeHandle = false;
    });
  }

  void _vibrate() async {
    Vibration.vibrate(duration: 1); // ویبره 20 میلی‌ثانیه‌ای
  }

  double get sweepAngle => endAngle >= startAngle
      ? endAngle - startAngle
      : 2 * pi - (startAngle - endAngle);

  String formatDuration(double duration) {
    int totalMinutes = (duration * 60).round();
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')} hr ${minutes.toString().padLeft(2, '0')} min';
  }

  String getSweepAngleString() {
    double totalMinutes =
        (sweepAngle / (2 * pi)) * 24 * 60; // Updated for 24-hour format
    int hours = (totalMinutes / 60).floor();
    int minutes = (totalMinutes % 60).floor();
    return '${hours.toString().padLeft(2, '0')} hr ${minutes.toString().padLeft(2, '0')} min';
  }

  String getWakeDurationString() {
    debugPrint(" wakeDuration: ${wakeDuration.toString()}");
    double totalMinutes =
        (wakeDuration / (2 * pi)) * 24 * 60; // Updated for 24-hour format
    debugPrint(" totalMinutes: ${totalMinutes.toString()}");
    int hours = (totalMinutes / 60).floor();
    int minutes = (totalMinutes % 60).floor();
    return '${hours.toString().padLeft(2, '0')} hr ${minutes.toString().padLeft(2, '0')} min';
  }

  String getTimeString(double angle) {
    double adjustedAngle =
        (angle - pi / 2) % (2 * pi); // Adjust to match clock numbers
    if (adjustedAngle < 0) adjustedAngle += 2 * pi; // Normalize to 0-2pi
    double hours = (adjustedAngle / (2 * pi)) * 24;
    int intHours = hours.toInt();
    int minutes = ((hours - intHours) * 60).toInt();
    String period = intHours <= 12 ? 'PM' : 'AM';

    // Adjust for 12-hour clock
    if (intHours == 0) intHours = 12;
    if (intHours > 12) intHours -= 12;

    return '${intHours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} $period';
  }

  TimeOfDay getTimeFromAngle(double angle) {
    double adjustedAngle =
        (angle + pi / 2) % (2 * pi); // Adjust to match clock numbers
    if (adjustedAngle < 0) adjustedAngle += 2 * pi; // Normalize to 0-2pi
    double hours = (adjustedAngle / (2 * pi)) * 24;
    int intHours = hours.toInt();
    int minutes = ((hours - intHours) * 60).toInt();

    // Ensure hour is within 24-hour format
    intHours = intHours % 24;

    return TimeOfDay(hour: intHours, minute: minutes);
  }

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Your Schedule'),
        actions: [
          TextButton(
            onPressed: () {
              _stopAlarm();

              alarmTimer?.cancel();
              _saveSettings(); // Save settings when done
            },
            child: Text(
              'Done',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${getTimeString(startAngle)} - ${getTimeString(endAngle)}',
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(height: 15),

                Stack(
                  children: [
                    Center(
                      child: GestureDetector(
                        onPanStart: (details) =>
                            _onDragStart(details, Size(300, 300)),
                        onPanUpdate: (details) => _onDragUpdate(
                          details,
                          Size(300, 300),
                        ),
                        child: CustomPaint(
                          painter: SleepClockPainter(
                              startAngle, sweepAngle, isDarkMode, endAngle),
                          size: Size(300, 300),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Align(
                        child: Container(
                          alignment: Alignment.center,
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.withOpacity(0)),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Text(
                  getSweepAngleString(),
                  style: TextStyle(fontSize: 24),
                ),
                const Text(
                  'This schdule meets yours sleep goal.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 10),
                // Text(
                //   'Total Sleep Time: ${formatDuration(sleepDuration)} hours',
                //   style: TextStyle(fontSize: 18),
                // ),
                Text(
                  'Total Wake Time: ${formatDuration(wakeDuration)} hours',
                  style: TextStyle(fontSize: 12),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  child: ListTile(
                    title: Text(
                      'Alarm Options',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      // <= No more error here :)
                      color: MyColors.baseColor,
                    ),
                    child: Padding(
                      padding:  const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Alarm"),
                          Switch(
                            activeTrackColor: Colors.green,
                            value: isAlarmEnabled,
                            onChanged: (value) {
                              setState(() {
                                isAlarmEnabled = value;
                                _setAlarm(); // Update alarm time based on the switch state
                                _saveSettings(); // Save settings to Hive
                              });
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      // <= No more error here :)
                      color: MyColors.baseColor,
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Sounds & Haptics'),
                              if (selectedAlarmName.isNotEmpty)
                                Text(
                                  selectedAlarmName,
                                  style: TextStyle(color: Colors.grey),
                                ),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: _requestPermissionsAndOpenFilePicker,
                        ),
                        SizedBox(width: 330, child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(Icons.navigate_before_sharp),
                              SizedBox(
                                width: 290,
                                child: Slider(
                                  thumbColor: Colors.white,
                                  activeColor: Colors.blue[600],
                                  value: alarmVolume,
                                  onChanged: (value) {
                                    setState(() {
                                      alarmVolume = value;
                                      audioPlayer.setVolume(alarmVolume);
                                      _saveSettings(); // Save settings when volume is changed
                                    });
                                  },
                                ),
                              ),
                              Icon(Icons.navigate_next_sharp),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 330,
                          child: Divider(),
                        ),
                        Padding(
                          padding:  const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Snooze"),
                              Switch(
                                activeTrackColor: Colors.green,
                                value: isSnoozeEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    isSnoozeEnabled = value;
                                    _saveSettings(); // Save settings to Hive
                                  });
                                },
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(double angle, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final handleRadius = 10.0;
    final handlePosition = Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );

    return Positioned(
      left: handlePosition.dx - handleRadius,
      top: handlePosition.dy - handleRadius,
      child: Container(
        width: handleRadius * 2,
        height: handleRadius * 2,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class SleepClockPainter extends CustomPainter {
  final double startAngle;
  final double sweepAngle;
  final double endAngle;
  final bool isDarkMode;

  SleepClockPainter(
      this.startAngle, this.sweepAngle, this.isDarkMode, this.endAngle);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MyColors.baseColor
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 30.0;

    final endHandleColor =
        (4.716179970963866 > endAngle && endAngle > 1.5707963267948966)
            ? Colors.black
            : Colors.white;

    debugPrint('endAngle: $endAngle');

    final center = Offset(size.width / 2, size.height / 2);

    // تنظیم اندازه مربع و گوشه‌های گرد
    final double sideLength = size.width / 1;
    final double radiuss = 30;

    // رسم مستطیل با گوشه‌های گرد
    final rrect = RRect.fromLTRBR(
      (size.width - sideLength) / 2, // X
      (size.height - sideLength + 25) / 2, // Y
      (size.width - sideLength) / 2 + sideLength,
      (size.height - sideLength) / 2 + sideLength,
      Radius.circular(radiuss),
    );

    // canvas.drawRRect(rrect, paint);

    final big_redius = size.width / 1.9;

    final background_bigPaint = Paint()..color = MyColors.bigCircleColor;
    canvas.drawCircle(center, big_redius, background_bigPaint);

    final radius = size.width / 2.5;

    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius, backgroundPaint);

    // رسم خطوط ساعت
    final hourLinePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    final minuteLinePaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;

    const hourTextStyle = TextStyle(
      color: Colors.black,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );
    const minuteTextStyle = TextStyle(
      color: Colors.grey,
      fontSize: 14,
      fontWeight: FontWeight.normal,
    );
    // رسم تیک‌ها و اعداد
    for (int i = 1; i <= 24; i++) {
      final angle = (i * 15 - 90) * pi / 180; // چرخش 90 درجه به چپ
      final x1 = center.dx + radius * 0.85 * cos(angle);
      final y1 = center.dy + radius * 0.85 * sin(angle);
      final x2 = center.dx + radius * cos(angle);
      final y2 = center.dy + radius * sin(angle);

      if (i % 2 == 0) {
        // رسم اعداد زوج
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), hourLinePaint);

        final textPainter = TextPainter(
          text: TextSpan(
            text:
                '${i == 12 ? '12PM' : i > 12 ? (i - 12) == 6 ? '6PM' : (i - 12) == 12 ? '12AM' : i - 12 : (i) == 6 ? '6AM' : i}',
            style: (i == 12) || (i == 6) || (i - 12 == 12) || (i - 12 == 6)
                ? hourTextStyle
                : minuteTextStyle,
            // نمایش عدد به صورت 1 تا 12
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        final xText =
            center.dx + radius * 0.7 * cos(angle) - textPainter.width / 2;
        final yText =
            center.dy + radius * 0.7 * sin(angle) - textPainter.height / 2;
        textPainter.paint(canvas, Offset(xText, yText));
      } else {
        // رسم خطوط کوتاه
        final shortX1 = center.dx + radius * 0.9 * cos(angle);
        final shortY1 = center.dy + radius * 0.9 * sin(angle);
        canvas.drawLine(
            Offset(shortX1, shortY1), Offset(x2, y2), minuteLinePaint);
      }
    }

    // رسم خطوط میانی بین تیک‌ها
    for (int i = 0; i < 72; i++) {
      if (i % 3 != 0) {
        // رسم خطوط غیر از تیک‌های اصلی
        final angle = (i * 5 - 90) * pi / 180;
        final x1 = center.dx + radius * 0.9 * cos(angle);
        final y1 = center.dy + radius * 0.9 * sin(angle);
        final x2 = center.dx + radius * cos(angle);
        final y2 = center.dy + radius * sin(angle);
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), minuteLinePaint);
      }
    }

    // RoundedArcPainter(
    //   startAngle: 0,
    //   sweepAngle: pi,
    //   radius: 100,
    //   arcColor: Colors.black.withOpacity(0.2),
    //   endShapeColor: Colors.black,
    //   shapeRadius: 10.0,
    //   center: Offset(150, 150),
    // );
    // final holeRadius = radiuss-  15; // شعاع دایره وسط
    //
    // final arcPaint = Paint()
    //   ..style = PaintingStyle.stroke
    //   ..isAntiAlias = true
    //   ..color = endHandleColor
    //   ..strokeCap = StrokeCap.round
    //   ..strokeWidth = 30;
    //
    // final path = Path()
    //   ..moveTo(center.dx, center.dy)
    //   ..arcTo(
    //     Rect.fromCircle(center: center, radius: radius + 20),
    //     startAngle,
    //     sweepAngle,
    //     false,
    //   )
    //   ..lineTo(
    //     center.dx + (radius + 20) * cos(startAngle + sweepAngle),
    //     center.dy + (radius + 20) * sin(startAngle + sweepAngle),
    //   )
    //   ..arcTo(
    //     Rect.fromCircle(center: center, radius: holeRadius),
    //     startAngle + sweepAngle,
    //     -sweepAngle,
    //     false,
    //   )
    //   ..close();
    //
    // canvas.drawPath(path, arcPaint);

    // رسم آرک خواب
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..color = endHandleColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (30);

    // رسم تیک‌ها
    const int tickCount = 30;
    const double tickLength = 14;
    const double tickWidth = 2;
    const double tickPadding = 27; // فاصله ثابت برای تیک‌ها

    final Paint tickPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = tickWidth;
    final centerc = Offset(size.width / 5, size.height / 5);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 20),
      // تنظیم شعاع آرک برابر با شعاع ساعت
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // canvas.drawPath(
    //   Path.combine(
    //     PathOperation.difference,
    //     Path()..addRRect(RRect.fromLTRBR(100, 100, 300, 300, Radius.circular(10))),
    //     Path()
    //       ..addOval(Rect.fromCircle(center: Offset(200, 200), radius: 50))
    //       ..close(),
    //   ),
    //   arcPaint,
    // );

    // Calculate the number of ticks to draw based on the sweep angle
    int numberOfTicks =
        ((sweepAngle / (2 * pi)) * 72).round(); // هر 5 درجه یک تیک
    // debugPrint("numberOfTicks : "+numberOfTicks.toString());
    debugPrint("sweepAngle : " + sweepAngle.toString());

    // رسم تیک‌ها داخل آرک
    for (int i = 0; i <= tickCount; i++) {
      double angle = startAngle + (sweepAngle / tickCount) * i;
      Offset tickStart = Offset(
        center.dx + (radius + tickPadding - tickLength) * cos(angle),
        // تنظیم موقعیت داخل آرک
        center.dy + (radius + tickPadding - tickLength) * sin(angle),
      );
      Offset tickEnd = Offset(
        center.dx + (radius + tickPadding) * cos(angle),
        // تنظیم موقعیت داخل آرک
        center.dy + (radius + tickPadding) * sin(angle),
      );
      canvas.drawLine(tickStart, tickEnd, tickPaint);
    }

    // رسم آیکون قبل از اولین تیک
    final iconSize = 15.0;
    double firstTickAngle = startAngle;
    Offset firstIconOffset = Offset(
      center.dx + (radius + 3 + iconSize) * cos(firstTickAngle),
      center.dy + (radius + 3 + iconSize) * sin(firstTickAngle),
    );

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: '🛌',
      style: TextStyle(
        fontSize: iconSize,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    );
    textPainter.layout();
    textPainter.paint(
        canvas, firstIconOffset - Offset(iconSize / 2, iconSize / 2));

    // رسم آیکون بعد از آخرین تیک
    double lastTickAngle = startAngle + sweepAngle;
    Offset lastIconOffset = Offset(
      center.dx + (radius + 3 + iconSize) * cos(lastTickAngle),
      center.dy + (radius + 3 + iconSize) * sin(lastTickAngle),
    );

    textPainter.text = TextSpan(
      text: '⏰',
      style: TextStyle(
        fontSize: iconSize,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    );
    textPainter.layout();
    textPainter.paint(
        canvas, lastIconOffset - Offset(iconSize / 2, iconSize / 2));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

@pragma('vm:entry-point')
void backgroundAlarmCallback() async {
  debugPrint("backgroundAlarmCallback");
  playAlarm();
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'notificationChannelId', // id
    'Notification Channel', // title
    channelDescription: 'This channel is used for important notifications.',
    // description
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    3, // id
    'Alarm is Running', // title
    'Alarm Body', // body
    platformChannelSpecifics,

    payload: 'alarm_payload',
  );
}
