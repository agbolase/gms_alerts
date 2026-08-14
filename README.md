# GMS Alerts (Android + iOS)

Parent and student app for **Granny Murray / GMS** with real-time alerts and **audible sound** when a notification arrives.

## Alerts

| Type | When it fires |
|------|----------------|
| Invoices and fees | New invoice created |
| Exams and marksheet | Marks saved, or marksheet sent |
| Assignments | New assignment posted |
| Online classes | Live class scheduled |
| Attendance | Clock-in and clock-out |

## Login

Use the **guardian** or **student** portal username and password (same as the school website).

## Build

```bash
cd mobile/gms_alerts
flutter create . --project-name gms_alerts --org com.grannymurray
flutter pub get
```

Set the API URL in `lib/config/app_config.dart` if you are not pointing at live:

- Live: `https://gms.grannymurray.com/api/gms/mobile`
- Android emulator: `http://10.0.2.2/schools/api/gms/mobile`
- Physical phone on LAN: `http://YOUR_PC_IP/schools/api/gms/mobile`

### Android

Add to `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

Then:

```bash
flutter run
# or
flutter build apk
```

### iOS

In `ios/Runner/Info.plist` allow notifications. Then:

```bash
flutter run
flutter build ios
```

Allow notifications when the OS prompt appears so the alert sound can play.

## How sound works

1. The phone **long-polls** the school API (`/poll`) so new events arrive in a few seconds.
2. Each new alert plays the **system notification sound** (high-priority channel `gms_alerts`) and shows a banner.
3. Optional: save a Firebase **FCM server key** on the school record as `fcm_server_key` and register an FCM token from the app for alerts when the app is in the background or killed.

Keep the app open (or in recent apps) for the fastest audible alerts until FCM is configured.

## API

| Method | Path |
|--------|------|
| POST | `/api/gms/mobile/login` |
| GET | `/api/gms/mobile/me` |
| POST | `/api/gms/mobile/register_device` |
| GET | `/api/gms/mobile/notifications?since_id=` |
| GET | `/api/gms/mobile/poll?since_id=` |
| GET | `/api/gms/mobile/invoices` |
| GET | `/api/gms/mobile/assignments` |
| GET | `/api/gms/mobile/liveclasses` |
| GET | `/api/gms/mobile/exams` |
| GET | `/api/gms/mobile/attendance` |
# gms-alerts
