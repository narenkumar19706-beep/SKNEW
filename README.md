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
