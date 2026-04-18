# Smart Waste Collection Monitoring System - Installation Guide

## Quick Start Guide

### Prerequisites
1. Flutter SDK installed (version 3.11.4 or higher)
2. Android Studio or VS Code with Flutter extensions
3. Android device or emulator
4. Firebase project with google-services.json file
5. Google Maps API key

---

## Step-by-Step Installation

### 1. Firebase Setup (5 minutes)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Enable these services:
   - **Authentication** → Enable Email/Password
   - **Firestore Database** → Create database in test mode
   - **Cloud Messaging** → Already enabled by default

4. Add Android app to Firebase:
   - Package name: `com.bmc.smart_waste_app`
   - Download `google-services.json`
   - Place it in: `android/app/google-services.json`

5. Get your Google Maps API Key:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Enable Maps SDK for Android
   - Create API key
   - Add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_API_KEY_HERE"/>
   ```

---

### 2. Install Dependencies (2 minutes)

Open terminal in project directory and run:

```bash
flutter pub get
```

---

### 3. Build APK (3-5 minutes)

```bash
flutter clean
flutter build apk --release
```

The APK will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`

---

### 4. Install APK on Android Device

**Option A: Via USB Cable**
1. Enable USB Debugging on your phone
2. Connect phone to PC
3. Run: `flutter install`

**Option B: Manual Install**
1. Transfer `app-release.apk` to your phone
2. Open the APK file
3. Allow installation from unknown sources if prompted
4. Tap Install

---

### 5. First Time Setup

1. Open the app
2. Create sample data (optional):
   - Add the sample_data.dart function to populate demo users
3. Login with demo credentials:

**Admin:**
- Email: admin@smartwaste.com
- Password: Admin@123

**Driver:**
- Email: driver1@smartwaste.com
- Password: Driver@123

**Resident:**
- Email: resident1@smartwaste.com
- Password: Resident@123

---

## Troubleshooting

### Build Errors
- Run `flutter doctor` to check for issues
- Ensure Android SDK is properly installed
- Check that all dependencies are downloaded

### Firebase Errors
- Verify google-services.json is in correct location
- Ensure Firebase services are enabled
- Check internet connection

### Maps Not Showing
- Verify API key is correct
- Ensure Maps SDK is enabled in Google Cloud
- Check that billing is enabled (free tier available)

### App Crashes
- Check logcat for error messages: `flutter logs`
- Ensure all permissions are granted
- Verify Firebase configuration

---

## Features Overview

### Resident Features
- ✅ Live truck tracking on map
- ✅ ETA calculation
- ✅ Raise and track complaints
- ✅ Collection history
- ✅ Push notifications
- ✅ Profile management

### Driver Features
- ✅ Start/stop duty
- ✅ Live GPS tracking
- ✅ View assigned routes
- ✅ Mark collections complete
- ✅ Offline support

### Admin Features
- ✅ Monitor all vehicles
- ✅ Assign routes to drivers
- ✅ Manage complaints
- ✅ View analytics
- ✅ Real-time dashboard

---

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Firebase and Google Cloud console logs
3. Verify all configuration files are in place

---

**Note:** This is a production-ready application. Ensure you:
- Replace demo credentials with real user accounts
- Set up proper Firebase security rules before going live
- Test thoroughly in your environment
- Configure proper notification settings
