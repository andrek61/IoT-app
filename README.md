# 💡 Auto Light IoT - Smart Lighting Dashboard

A real-time mobile dashboard built with Flutter to monitor and manage an automated smart lighting system. This application communicates with ESP8266/ESP32 microcontrollers via Firebase Realtime Database, allowing users to seamlessly switch between hardware-driven automation and manual software overrides.

## - Key Features

* **Real-Time Sensor Telemetry:** Continuously monitors LDR (Light Dependent Resistor) sensor values and environment status (Dark/Dim/Bright) with millisecond latency.
* **Hardware Override Logic:** Safely disables manual switches when the hardware is in "Auto Sensor" mode to prevent logical conflicts between the microcontroller and the mobile app.
* **Smart Push Notifications (Delta Detection):** Utilizes custom state-comparison algorithms to trigger local notifications only during actual state changes, completely eliminating notification spam.
* **Dynamic Configuration:** Allows users to remotely calibrate sensor thresholds (house/street lights) and delay intervals directly from their mobile devices.
* **Secure Authentication:** Implements a custom Firebase node authentication system for personalized access.

## - Tech Stack

**Mobile Application:**
* **Framework:** Flutter (Dart)
* **Local Notifications:** `awesome_notifications`
* **State Management:** `setState` with Stream Subscriptions
* **Typography:** Google Fonts (Poppins)

**Backend & Hardware:**
* **Database:** Firebase Realtime Database (NoSQL)
* **Microcontroller:** ESP8266
* **Sensor:** LDR Sensor
