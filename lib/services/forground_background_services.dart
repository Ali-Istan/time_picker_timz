import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BackForGroundServices {
  static final FlutterLocalNotificationsPlugin
      flutterLocalNotificationsPlugin2 = FlutterLocalNotificationsPlugin();

  // region Foreground and Background
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,

        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });
      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }
    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
// bring to foreground

    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
// CustomLoader.message("foreground");
//           flutterLocalNotificationsPlugin.show(
//             2,
//             'COOL SERVICE',
//             'Awesome ${DateTime.now()}',
//             const NotificationDetails(
//               android: AndroidNotificationDetails(
//                 "notificationChannelId",
//                 'MY FOREGROUND SERVICE',
//                 icon: 'ic_bg_service_small',
//                 ongoing: true,
//                 playSound: false,
//               ),
//             ),
//           );
        }
      }
    });
  }

// endregion

  // region initializeNotifications
  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
            '@mipmap/ic_launcher'); // Make sure this is correct
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin2.initialize(initializationSettings);
  }

  static Future<void> showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'alarm_service_channel',
      'Alarm Service Channel',
      channelDescription: 'Channel for Alarm Service',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      playSound: true,
      icon: 'assets/images/app_icon.png', // Ensure this is correct
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin2.show(
      1,
      'Alarm',
      'Your alarm is ringing!',
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

// endregion
}
