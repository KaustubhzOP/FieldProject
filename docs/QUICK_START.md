# 🚀 QUICK START - Smart Waste Collection App

## ⚡ 3-Step Setup

### Step 1: Add Firebase Config (2 min)
1. Download `google-services.json` from Firebase Console
2. Replace file at: `android/app/google-services.json`

### Step 2: Add Google Maps API Key (1 min)
1. Get API key from Google Cloud Console
2. Open `android/app/src/main/AndroidManifest.xml`
3. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your key

### Step 3: Build APK (5 min)
```bash
flutter pub get
flutter clean
flutter build apk --release
```

**Your APK**: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📱 Install APK
- Transfer to phone → Tap to install
- OR connect via USB → Run: `flutter install`

---

## 🔑 Demo Login
```
Admin:    admin@smartwaste.com    / Admin@123
Driver:   driver1@smartwaste.com  / Driver@123
Resident: resident1@smartwaste.com / Resident@123
```

---

## 📖 Full Documentation
- **Setup Guide**: `INSTALLATION_GUIDE.md`
- **Project Details**: `PROJECT_SUMMARY.md`

---

## ❓ Issues?
- Run: `flutter doctor`
- Check: Firebase Console
- Verify: API keys configured

---

**That's it! Your app is ready! 🎉**
