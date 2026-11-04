import 'package:flutter/material.dart';

// Corrected path using forward slashes and starting with package:fukatsongs
import 'package:fukatsongs/screens/screen/home_views/notification_view.dart';

void main() {
  runApp(const PreviewApp());
}

class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Set your NotificationView as the very first screen
      home: const NotificationView(), 
    );
  }
}