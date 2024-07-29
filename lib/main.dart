import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tank_time_picker/Tools/my_tools.dart';
import 'package:tank_time_picker/services/initial_notif.dart';
import 'package:workmanager/workmanager.dart';

import 'models/alarm_settings.dart';
import 'screens/sleep_schedule_screen.dart';
import 'services/forground_background_services.dart';

import 'dart:async';
import 'dart:io';

import 'dart:math';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import 'package:tank_time_picker/Tools/my_tools.dart';
import 'package:tank_time_picker/main.dart';
import 'package:workmanager/workmanager.dart';
import '../models/alarm_settings.dart';
import '../services/forground_background_services.dart';
import '../services/initial_notif.dart';

Future<void> requestExactAlarmPermission() async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
  var status = await Permission.scheduleExactAlarm.status;
  if (!status.isGranted) {
    if (await Permission.scheduleExactAlarm.request().isGranted) {
      // دسترسی اعطا شد
    } else {
      // دسترسی رد شد
      // می‌توانید یک دیالوگ به کاربر نمایش دهید یا به صورت دیگری آن را مدیریت کنید
    }
  }
}

// region Variables
AudioPlayer audioPlayer = AudioPlayer();
String selectedAlarmPath = 'alarms/default_alarm.mp3'; // مسیر آهنگ پیش‌فرض
String selectedAlarmName = 'Default Alarm';
double alarmVolume = 0.5;
bool isAlarmEnabled = true;
bool isSnoozeEnabled = false;

void playAlarm() async {
  if (selectedAlarmPath.startsWith('alarms/')) {
    await audioPlayer.setVolume(alarmVolume);
    await audioPlayer.play(AssetSource(selectedAlarmPath));
  } else {
    await audioPlayer.setVolume(alarmVolume);
    await audioPlayer.play(DeviceFileSource(selectedAlarmPath));
  }

  if (isSnoozeEnabled) {
    _scheduleSnooze();
  }
}

void _scheduleSnooze() {
  Timer(const Duration(minutes: 10), () {
    playAlarm();
    BackForGroundServices.showNotification();
  });
}

// endregion

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  await Hive.initFlutter();
  await requestExactAlarmPermission();

  Hive.registerAdapter(
    AlarmSettingsAdapter(),
  );

// region Initialize Flutter Local Notifications

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );

  // endregion

  if (Platform.isAndroid || Platform.isIOS) {
    await BackForGroundServices.initializeService();
    // await initializeService();
  }
  // InitializeNotifications().showPersistentNotification();
  runApp(MyApp());
  InitializeNotifications().showPersistentNotification();
  // await AndroidAlarmManager.periodic(
  //     const Duration(seconds: 10), 0, backgroundAlarmCallbackk);
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        // await AndroidAlarmManager.cancel(4);

        // اپلیکیشن در حال حاضر در foreground است
        debugPrint('App is in the foreground');
        break;
      case AppLifecycleState.paused:
        // اپلیکیشن در حال حاضر در background است
        debugPrint('App is in the background');
        break;
      case AppLifecycleState.inactive:
        // await AndroidAlarmManager.initialize();
        debugPrint('App is inactive');
        break;
      case AppLifecycleState.detached:
        // اپلیکیشن در وضعیت‌های دیگری است
        debugPrint('App is detached');
        break;
      case AppLifecycleState.hidden:
      // TODO: Handle this case.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SleepSchedulePage(),

      // darkTheme: ThemeData.dark(),
      // themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
    );
  }
}
