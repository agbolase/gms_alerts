# Android Firebase (Spark, free) for GMS

FCM is free on the Spark plan. Follow this once, then rebuild the APK.

## A. Create the Firebase project (free)

1. Open [https://console.firebase.google.com](https://console.firebase.google.com) and sign in with a Google account.
2. **Add project** → name it e.g. `gms-alerts`.
3. Google Analytics: you can **disable** it to stay simplest.
4. Create the project. Stay on the **Spark (no-cost)** plan. Do **not** upgrade to Blaze.

## B. Add the Android app

1. On the project overview, click the **Android** icon.
2. Android package name (must match exactly):

   `com.grannymurray.gms_alerts`

3. App nickname: `GMS`
4. SHA-1: optional for now (needed later only for Google Sign-In, not for push).
5. **Register app**.
6. Download **`google-services.json`**.
7. Save it as:

   `mobile/gms_alerts/android/app/google-services.json`

   (replace the example file)

## C. Server key so the school site can send pushes

1. Firebase console → gear → **Project settings**.
2. **Service accounts** tab.
3. **Generate new private key** → download the JSON.
4. On the **live** Granny Murray server, save it as:

   `application/config/fcm_service_account.json`

   (same folder as `database.php`; do not commit this file to a public GitHub repo)

5. Upload the PHP files:

   - `application/helpers/gms_mobile_notify_helper.php`
   - `application/modules/mobile/controllers/Api.php`

## D. Rebuild the Android app

```bash
cd mobile/gms_alerts
git add android/app/google-services.json
git commit -m "Add Firebase google-services.json"
git push
```

Then run a new Codemagic **Android APK** build and install it.

## E. Test

1. Open GMS, sign in, allow notifications.
2. Trigger an attendance / invoice / exam alert on the school site.
3. Put GMS in the background or swipe it away. The phone should still get a sound + banner.

If nothing arrives, check live PHP logs for `GMS FCM V1`.
