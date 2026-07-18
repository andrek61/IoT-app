import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

// Main dashboard interface for the Auto Light IoT application.
// Handles real-time data synchronization with Firebase, local state management, and push notifications.
class HomePage extends StatefulWidget {
  final VoidCallback onLogout;
  const HomePage({super.key, required this.onLogout});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Local UI state controllers for toggle switches.
  bool SensorLDRSwitch = true;
  bool lampuRumahSwitch = false;
  bool lampuJalanSwitch = false;

  int? lastUpdateId;

  // Real-time clock states.
  String currentTime = '';
  Timer? timer;

  // Environment status flags derived from sensor readings.
  bool isMalam = false;
  bool isSore = false;

  // Firebase data placeholders. Initialized with loading indicators.
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('sensor');
  String ldr = 'Memuat...';
  String ambangSLrumah = "Memuat...";
  String ambangSLjalan = "Memuat...";
  String delayS = "Memuat...";
  String status = "terang";
  
  // Hardware control states.
  bool sensorOn = true;
  bool lampuROn = false;
  bool lampuJOn = false;

  // Previous state trackers (Delta Detection).
  // Used to compare incoming Firebase data against the current state to ensure
  // notifications are only triggered once per state change, preventing notification spam.
  bool? _prevIsMalam;
  bool? _prevIsSore;
  bool? _prevSensorOn;
  bool? _prevLampuROn;
  bool? _prevLampuJOn;
  String? _prevDelay;
  String? _prevAmbangBLrumah;
  String? _prevAmbangBLjalan;

  @override
  void initState() {
    // Request system-level notification permissions upon dashboard initialization.
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
    
    super.initState();

    // Initialize the digital clock and set it to update every second.
    _updateTime();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
    
    // Subscribe to Firebase Realtime Database node 'sensor'.
    // This stream listens continuously and triggers a UI rebuild whenever hardware data changes.
    _ref.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map;
      
      setState(() {
        ldr = data['ldr'].toString();
        status = data['status'];
        ambangSLrumah = data['ambang_lampu_rumah'].toString();
        ambangSLjalan = data['ambang_lampu_jalan'].toString();
        sensorOn = data['sensor_on'];
        lampuROn = data['lampu_rumah_on'];
        lampuJOn = data['lampu_jalan_on'];
        
        // Convert millisecond delay from hardware to readable seconds.
        delayS = (data['delay'] / 1000).round().toString();

        SensorLDRSwitch = sensorOn;
        
        // Hardware Override Logic:
        // If the automatic sensor is ON, manual controls are strictly disabled to prevent hardware conflict.
        // If OFF, the LDR reading is hidden to reflect that the sensor is inactive.
        if (SensorLDRSwitch){
          lampuROn = false;
          lampuJOn = false;
        } else {
          ldr = "Memuat...";
        }

        lampuRumahSwitch = lampuROn;
        lampuJalanSwitch = lampuJOn;

        // Determine environment status based on string mapping from the microcontroller.
        isMalam = status.toLowerCase() == "gelap";
        isSore = status.toLowerCase() == "redup";

        // ==========================================
        // Notification Delta Evaluators
        // Evaluates if a specific data point has changed since the last stream emission.
        // ==========================================
        
        if (_prevIsSore != null && _prevIsSore != isSore) {
          tampilkanNotifikasi("Auto Light IoT", isSore ? "Nilai LDR sudah melebihi ambang sensor rumah 🎯, lampu rumah dinyalakan otomatis." : "Nilai LDR lebih kecil dari ambang sensor rumah 🎯, lampu rumah dimatikan otomatis.");
        }
        _prevIsSore = isSore;

        if (_prevIsMalam != null && _prevIsMalam != isMalam) {
          tampilkanNotifikasi("Auto Light IoT", isMalam ? "Sudah mulai gelap 🌃, lampu Jalan dinyalakan otomatis." : "Sudah terang kembali ☀️, lampu rumah dimatikan otomatis.");
        }
        _prevIsMalam = isMalam;

        if (_prevSensorOn != null && _prevSensorOn != sensorOn) {
          tampilkanNotifikasi("Auto Light IoT", sensorOn ? "Sensor berhasil diaktif 🟢" : "Sensor berhasil dinonaktif 🔴");
        }
        _prevSensorOn = sensorOn;
        
        if (_prevAmbangBLrumah != null && _prevAmbangBLrumah != ambangSLrumah) {
          tampilkanNotifikasi("Auto Light IoT", "Ambang batas 🎯 lampu rumah berhasil diubah menjadi $ambangSLrumah");
        }
        _prevAmbangBLrumah = ambangSLrumah;

        if (_prevAmbangBLjalan != null && _prevAmbangBLjalan != ambangSLjalan) {
          tampilkanNotifikasi("Auto Light IoT", "Ambang batas 🎯 lampu jalan berhasil diubah menjadi $ambangSLjalan");
        }
        _prevAmbangBLjalan = ambangSLjalan;

        if (_prevDelay != null && _prevDelay != delayS) {
          tampilkanNotifikasi("Auto Light IoT", "Delay ⏳ berhasil diubah menjadi $delayS detik");
        }
        _prevDelay = delayS;

        // Manual control notifications only trigger if the automatic sensor is turned off.
        if (_prevLampuROn != null && _prevLampuROn != lampuROn && !sensorOn) {
          tampilkanNotifikasi("Auto Light IoT", lampuROn ? "Lampu Rumah 💡 diaktifkan secara manual 🟢" : "Lampu Rumah 💡 dimatikan secara manual 🔴");
        }
        _prevLampuROn = lampuROn;

        if (_prevLampuJOn != null && _prevLampuJOn != lampuJOn && !sensorOn) {
          tampilkanNotifikasi("Auto Light IoT", lampuJOn ? "Lampu Jalan 💡 diaktifkan secara manual 🟢" : "Lampu Jalan 💡 dimatikan secara manual 🔴");
        }
        _prevLampuJOn = lampuJOn;

      });
    });
  }

  // Helper method to construct and trigger local push notifications via AwesomeNotifications.
  void tampilkanNotifikasi(String title, String body) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'basic_channel',
        title: title,
        body: body,
        // BigText layout prevents text truncation on longer notification bodies.
        notificationLayout: NotificationLayout.BigText,
      ),
    );
  }

  // Updates the localized clock state based on device time.
  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      currentTime = '${_twoDigits(now.hour)}:${_twoDigits(now.minute)}';
    });
  }

  // Formats single-digit integers with a leading zero (e.g., 9 -> 09).
  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  void dispose() {
    // Cancel the active periodic timer to prevent memory leaks when the widget is destroyed.
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return AnimatedContainer(
      duration: Duration(seconds: 1),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isMalam
              ? [Color(0xFF0D47A1), Colors.black]
              : [Color(0xFF87CEEB), Colors.white],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, 
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                'Auto Light IoT',
                style: GoogleFonts.poppins(
                  color: isMalam? const Color.fromARGB(255, 240, 255, 255) : Colors.black,
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Kelompok 19 - Cahaya',
                style: GoogleFonts.poppins(
                  color: isMalam? const Color.fromARGB(255, 240, 255, 255) : Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: Duration(seconds: 1),
                child: Container(
                  key: ValueKey<bool>(isMalam), // penting agar transisi bisa dibedakan
                  width: screenWidth * 0.9,
                  height: 200,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(isMalam
                          ? 'assets/images/malam.png'
                          : 'assets/images/siang.png'),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                    child: Center(
                      child: Text(
                        isMalam ? 'Cahaya: Gelap' : 'Cahaya: Terang',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 3,
                              color: Colors.black54,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedContainer(
                      duration: Duration(seconds: 1),
                      curve: Curves.easeInOut,
                      width: screenWidth * 0.42,
                      height: 150,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isMalam? Color.fromARGB(255, 4, 20, 44) : Colors.lightBlue[50],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nilai LDR:',
                            style: TextStyle(
                              color: isMalam? const Color.fromARGB(255, 240, 255, 255) : Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: ldr == 'Memuat...' ? 30 : 25),
                          Text(
                            ldr,
                            style: TextStyle(
                              color: isMalam? const Color.fromARGB(255, 240, 255, 255) : Colors.black,
                              fontSize: ldr == 'Memuat...' ? 20 : 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.05), // Spasi antar kotak
                    AnimatedContainer(
                      duration: Duration(seconds: 1),
                      curve: Curves.easeInOut,
                      width: screenWidth * 0.42,
                      height: 150,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isMalam? Color.fromARGB(255, 4, 20, 44) : Colors.lightBlue[50],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jam:',
                            style: TextStyle(
                              color: isMalam? const Color.fromARGB(255, 240, 255, 255) : Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 25),
                          Text(
                            currentTime,
                            style: TextStyle(
                              color: isMalam? const Color.fromARGB(255, 240, 255, 255) : Colors.black,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              AnimatedContainer(
                width: screenWidth * 0.9,
                duration: Duration(seconds: 1),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isMalam? Color.fromARGB(255, 4, 20, 44) : Colors.lightBlue[50],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Setting',
                          style: TextStyle(
                            color: isMalam? const Color.fromARGB(255, 240, 255, 255) : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sensor',
                          style: TextStyle(
                            color: isMalam? const Color.fromARGB(255, 240, 255, 255) : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Switch(
                          value: SensorLDRSwitch,
                          onChanged: (value) {
                            setState(() {
                              SensorLDRSwitch = value;
                              lampuRumahSwitch = false;
                              lampuJalanSwitch = false;
                            });
                             _ref.update({
                              'sensor_on': value,
                              'lampu_rumah_on': false,
                              'lampu_jalan_on': false,
                            });
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ambang sensor rumah',
                          style: TextStyle(
                            color: isMalam? const Color.fromARGB(255, 240, 255, 255) : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final ambang = await showDialog<String>(
                              context: context,
                              builder: (context) {
                                TextEditingController ctrl = TextEditingController();
                                return AlertDialog(
                                  title: const Text('Set Ambang Cahaya Lampu Rumah'),
                                  content: TextField(
                                    controller: ctrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(hintText: 'Default 600'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, ctrl.text),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (ambang != null && ambang.isNotEmpty) {
                              _ref.update({"ambang_lampu_rumah" : int.parse(ambang)});
                            }
                          },
                          child: Text(ambangSLrumah),
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ambang sensor jalan',
                          style: TextStyle(
                            color: isMalam? const Color.fromARGB(255, 240, 255, 255) : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final ambang = await showDialog<String>(
                              context: context,
                              builder: (context) {
                                TextEditingController ctrl = TextEditingController();
                                return AlertDialog(
                                  title: const Text('Set Ambang Cahaya Lampu Jalan'),
                                  content: TextField(
                                    controller: ctrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(hintText: 'Default 800'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, ctrl.text),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (ambang != null && ambang.isNotEmpty) {
                              _ref.update({"ambang_lampu_jalan" : int.parse(ambang)});
                            }
                          },
                          child: Text(ambangSLjalan),
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Delay',
                          style: TextStyle(
                            color: isMalam? const Color.fromARGB(255, 240, 255, 255) : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final delay = await showDialog<String>(
                              context: context,
                              builder: (context) {
                                TextEditingController ctrl = TextEditingController();
                                return AlertDialog(
                                  title: const Text('Delay sensor'),
                                  content: TextField(
                                    controller: ctrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(hintText: 'Default 10 detik'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, ctrl.text),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (delay != null && delay.isNotEmpty) {
                              _ref.update({"delay" : int.parse(delay) * 1000});
                            }
                          },
                          child: Text(delayS + ' S'),
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lampu Rumah',
                          style: TextStyle(
                            color: isMalam? const Color.fromARGB(255, 240, 255, 255) : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Switch(
                          value: lampuRumahSwitch,
                          onChanged: SensorLDRSwitch ? null : (value) {
                            setState(() {
                              lampuRumahSwitch = value;
                            });
                            _ref.update({"lampu_rumah_on" : value});
                          },
                        ),
                    ],
                  ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lampu Jalan',
                          style: TextStyle(
                            color: isMalam? const Color.fromARGB(255, 240, 255, 255) : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Switch(
                          value: lampuJalanSwitch,
                          onChanged: SensorLDRSwitch ? null : (value) {
                            setState(() {
                              lampuJalanSwitch = value;
                            });
                            _ref.update({"lampu_jalan_on" : value});
                          },
                        ),
                    ],
                  ),
                ],
              ),
              ),
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }
}
