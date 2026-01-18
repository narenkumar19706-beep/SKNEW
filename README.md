# rrt_flutter_app

A new Flutter project.

## Architecture

### Overall Architecture (Clean & Scalable)

#### Architectural Intent

The RRT system is designed to:

- Work without login / OTP
- Be fast under stress
- Prevent false or accidental SOS
- Preserve privacy by default
- Scale district -> city -> state without rewrite
- Remain auditable (important for public-interest systems)

This leads to a state-driven backend + thin client architecture.

```
+----------------------------------+
|      Android App (Flutter)       |
|                                  |
| • SOS UI & Gestures              |
| • Location & Foreground Service  |
| • FCM Listener                   |
| • Offline-safe queue             |
+------------------+---------------+
                   |
                   | HTTPS + WebSocket
                   v
+----------------------------------+
|        Backend (Node.js)         |
|                                  |
| • Device Identity (JWT)          |
| • District Resolution Engine     |
| • SOS Lifecycle State Machine    |
| • Notification Orchestrator      |
| • Realtime Location Relay        |
+------------------+---------------+
                   |
           +-------+--------+
           |                |
+------------------+  +------------------+
| PostgreSQL       |  | Firebase FCM     |
| (Source Truth)   |  | (Notify only)    |
+------------------+  +------------------+
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
