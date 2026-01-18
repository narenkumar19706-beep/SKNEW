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

#### Key Architectural Decisions (Why this works)

**PostgreSQL = Source of Truth**

SOS is stateful, not event-only.

Needed for:

- Audit trails
- Legal defensibility
- Deterministic recovery

**Firebase = Notifications Only**

- No auth
- No database
- No logic
- Just reliable delivery

**Backend Owns All Logic**

- District determination
- Who gets notified
- SOS lifecycle rules
- Privacy enforcement

The app never decides these.

### Frontend - Flutter (Android-First)

#### Frontend Role (Strictly Defined)

The Flutter app is a controlled terminal, not a decision maker.

It is responsible for:

- Rendering screens
- Capturing user intent
- Requesting permissions
- Capturing GPS
- Showing backend state

It is not responsible for:

- Who receives alerts
- When SOS is valid
- How districts work
- Any security decision

#### Suggested Flutter `lib/` layout

```
lib/
 ├── main.dart
 ├── app.dart
 ├── core/
 │    ├── api/
 │    │    └── api_client.dart
 │    ├── services/
 │    │    ├── location_service.dart
 │    │    ├── foreground_service.dart
 │    │    ├── fcm_service.dart
 │    │    └── socket_service.dart
 │    ├── storage/
 │    │    └── secure_storage.dart
 │    └── constants/
 ├── features/
 │    ├── onboarding/
 │    ├── profile/
 │    ├── home/
 │    ├── sos/
 │    └── alerts/
 └── navigation/
      └── bottom_nav.dart
```

#### Android-Specific Implementation Choices

**Foreground Service (Critical)**

- Starts only during ACTIVE SOS
- Keeps GPS alive
- Shows persistent notification
- Prevents OS kill

**Location Strategy**

- Accuracy: High
- Interval: 5-10 seconds
- Offline buffering enabled
- Flush on reconnect

**Permissions Strategy**

- Asked only when needed
- Explained before system dialog
- No repeated nagging

#### Offline & Failure Behavior

SOS never stops silently.

If network drops:

- GPS continues
- Data queued locally
- Backend reconciles later

This is essential for real emergencies.

### Backend - Node.js (Fast + Real-time)

#### Backend Philosophy

The backend is a state machine, not a CRUD server.

It:

- Validates transitions
- Enforces rules
- Guarantees order
- Logs everything

```
+-------------------------------+
|  Android App (Flutter)        |
|                               |
|  - UI & Gestures              |
|  - Permissions                |
|  - GPS capture                |
|  - Foreground service         |
|  - FCM listener               |
+---------------+---------------+
                |
                | HTTPS (state changes)
                | WebSocket (live updates)
                v
+-------------------------------+
|  Backend (Node.js + Express)  |
|                               |
|  - Device identity            |
|  - SOS state machine          |
|  - District resolution        |
|  - Notification orchestration |
|  - Live location relay        |
+---------------+---------------+
                |
        +-------+--------+
        |                |
+--------------+  +--------------+
| PostgreSQL   |  | Firebase FCM |
| (truth + log)|  | (notify only)|
+--------------+  +--------------+
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
