import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/book_appointment_screen.dart';
import 'screens/my_appointments_screen.dart';
import 'screens/queue_screen.dart';
import 'screens/qr_scanner_screen.dart';

void main() {
  runApp(const MediQueueApp());
}

class MediQueueApp extends StatelessWidget {
  const MediQueueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediQueue',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1a73e8)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login':        (_) => LoginScreen(),
        '/register':     (_) => RegisterScreen(),
        '/home':         (_) => HomeScreen(),
        '/book':         (_) => BookAppointmentScreen(),
        '/appointments': (_) => MyAppointmentsScreen(),
        '/queue':        (_) => QueueScreen(),
        '/scan':         (_) => QrScannerScreen(),
      },
    );
  }
}