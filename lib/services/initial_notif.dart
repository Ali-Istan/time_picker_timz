import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class InitializeNotifications {
  void initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('assets/images/app_icon.png');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void showPersistentNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'persistent_channel', // ID کانال نوتیفیکیشن
      'Persistent Notifications', // نام کانال
      channelDescription: 'Channel for persistent notifications',
      // توضیحات کانال
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      // این خط باعث می‌شود نوتیفیکیشن قابل بسته شدن نباشد
      autoCancel: false, // نوتیفیکیشن به صورت خودکار بسته نشود
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0, // ID نوتیفیکیشن
      'CodeIsta', // عنوان نوتیفیکیشن
      'This app is runnig in background', // متن نوتیفیکیشن
      platformChannelSpecifics,



    );

  }
}
