import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'login.dart';
import 'home.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized before calling async native native code (like Firebase).
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase services to establish a connection with the IoT real-time database.
  await Firebase.initializeApp();
  
  // Initialize local notification service.
  // This channel handles alerts when LDR sensor thresholds are breached or system configurations change.
  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Notifikasi Umum', 
        channelDescription: 'Menampilkan notifikasi umum',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
      )
    ],
    debug: true,
  );
  
  runApp(const MyApp());
}

// Root application widget.
// Manages the top-level authentication state to control screen routing dynamically.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Tracks the current user session state.
  bool _isLoggedIn = false;

  // Callback method passed to child widgets to trigger state rebuilds upon login/logout actions.
  void _updateLoginStatus(bool status) {
    setState(() {
      _isLoggedIn = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Light IoT',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      // Conditionally render the Home or Login page based on the active authentication status.
      home: _isLoggedIn
          ? HomePage(onLogout: () => _updateLoginStatus(false))
          : LoginPage(onLoginSuccess: () => _updateLoginStatus(true)),
    );
  }
}