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

#### Suggested Node.js `src/` layout

```
src/
 ├── server.js
 ├── app.js
 ├── config/
 │    ├── db.js
 │    ├── fcm.js
 │    └── env.js
 ├── routes/
 │    ├── device.routes.js
 │    ├── sos.routes.js
 │    ├── alerts.routes.js
 │    └── location.routes.js
 ├── controllers/
 │    ├── device.controller.js
 │    ├── sos.controller.js
 │    ├── alerts.controller.js
 │    └── location.controller.js
 ├── services/
 │    ├── sos.service.js
 │    ├── district.service.js
 │    ├── fcm.service.js
 │    └── socket.service.js
 └── middlewares/
      └── auth.middleware.js
```

#### Core Backend Services Explained

**Device Service**

- Registers device
- Issues JWT
- Manages profile
- Binds FCM token
- No phone verification is required

**SOS Service (Heart of the System)**

Enforces:

- One active SOS per device
- Valid state transitions only
- Controlled resolution
- Notification triggers

This service cannot be bypassed.

**District Resolution Service**

- Converts lat/lng -> district
- Ensures alerts remain local
- Enables future geo-fencing
- Never done on client

**Notification Service**

Accepts semantic events:

- SOS_CREATED
- SOS_UPDATED
- SOS_RESOLVED

Converts them to FCM payloads.

Handles retries and logging.

**Location Stream Service**

- Stores GPS trail
- Emits live updates via WebSocket
- Throttles noise
- Preserves history

### Key Backend APIs (Minimum Production Set)

#### Authentication Model

- Device-bound JWT
- Short TTL
- Re-register allowed
- No refresh token complexity

Header:

```
Authorization: Bearer <jwt>
```

#### Device APIs

**Register Device**

POST /device/register

Creates identity and issues JWT.

**Get Profile**

GET /device/profile

**Update Profile**

PUT /device/profile

Editable:

- Name
- Phone

Derived (read-only):

- Address
- District

#### SOS APIs

**Trigger SOS**

POST /sos/trigger

Backend:

- Validates state
- Resolves district
- Creates SOS
- Notifies responders

**Add Update**

POST /sos/update

Only allowed if SOS is ACTIVE.

**Resolve SOS**

POST /sos/resolve

Ends lifecycle and sends final notification.

#### Location APIs

**Update Location**

POST /location/update

**Live Location**

GET /location/live/:sos_id

#### Alerts API

**District Alerts**

GET /alerts/district

Returns:

- ACTIVE alerts only
- Distance calculated server-side
- Phone visible only during ACTIVE SOS

### SOS Flow (End-to-End)

#### User Journey

App Launch
  ↓
Grant Location
  ↓
Profile Setup
  ↓
Home (Locked)
  ↓ slide
Home (Ready)
  ↓ press & hold
SOS ACTIVE
  ↓
Notifications sent
  ↓
Live tracking
  ↓
Add update (optional)
  ↓
Resolve SOS

#### System Flow (What actually happens)

User presses and holds SOS.

App sends trigger request.

Backend:

- Validates
- Resolves district
- Creates SOS

FCM sent to district users.

Foreground service starts.

Location updates stream.

Responders view alert.

User resolves SOS.

Backend closes lifecycle.

Final notification sent.

#### Privacy Guarantees

- No tracking before SOS
- No tracking after resolution
- Phone visible only while ACTIVE
- Location scoped to district

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
