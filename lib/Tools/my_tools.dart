import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class MyTools {
  static void showPermissionDialog(
      BuildContext context, String title, String content, String text_child) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: Text(text_child),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
