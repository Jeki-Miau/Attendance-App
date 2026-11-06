import 'package:flutter/material.dart';

import 'package:attendance_app/ui/attendance_design.dart';
import 'package:attendance_app/ui/welcome/welcome_auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance App',
      debugShowCheckedModeBanner: false,
      theme: AttendanceTheme.light,
      home: const WelcomeAuthScreen(),
    );
  }
}
