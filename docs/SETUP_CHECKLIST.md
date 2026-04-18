# ✅ SETUP CHECKLIST

## Complete these steps in order

---

## PHASE 1: Firebase Setup (7 minutes)

### Create Firebase Project
- [ ] Go to https://console.firebase.google.com/
- [ ] Click "Add project"
- [ ] Name it: smart-waste-collection
- [ ] Click Continue → Create project
- [ ] Wait for creation (30 sec)

### Enable Authentication
- [ ] Click "Authentication" in left menu
- [ ] Click "Get started"
- [ ] Click "Email/Password"
- [ ] Toggle Enable to ON
- [ ] Click Save

### Create Firestore Database
- [ ] Click "Firestore Database"
- [ ] Click "Create database"
- [ ] Select "Start in test mode"
- [ ] Choose location: asia-south1 (Mumbai)
- [ ] Click Enable
- [ ] Wait for creation (1-2 min)

### Add Android App
- [ ] Click Project Settings (⚙️ icon)
- [ ] Click Android icon (</>)
- [ ] Package name: `com.bmc.smart_waste_app`
- [ ] Click "Register app"
- [ ] Click "Download google-services.json"
- [ ] **Save the file!**

### Place Config File
- [ ] Go to: `c:\Users\Manas S Parekar\OneDrive\Desktop\fp\android\app\`
- [ ] Delete existing `google-services.json`
- [ ] Copy your downloaded `google-services.json` here
- [ ] Verify file exists at this location

**✅ PHASE 1 COMPLETE!**

---

## PHASE 2: Google Maps API (3 minutes)

### Enable Maps SDK
- [ ] Go to https://console.cloud.google.com/
- [ ] Select your Firebase project (top dropdown)
- [ ] Search: "Maps SDK for Android"
- [ ] Click Enable
- [ ] Wait for activation (30 sec)

### Create API Key
- [ ] Go to: https://console.cloud.google.com/apis/credentials
- [ ] Click "+ CREATE CREDENTIALS"
- [ ] Select "API key"
- [ ] Copy the key (starts with: AIzaSy...)
- [ ] Save it somewhere safe

### Add Key to Project
- [ ] Open file: `android\app\src\main\AndroidManifest.xml`
- [ ] Find line: `YOUR_GOOGLE_MAPS_API_KEY_HERE`
- [ ] Replace with your actual API key
- [ ] Save the file

**✅ PHASE 2 COMPLETE!**

---

## PHASE 3: Build APK (5-7 minutes)

### Pre-Build Check
- [ ] Flutter installed (run: `flutter doctor`)
- [ ] Firebase config file in place
- [ ] Google Maps API key added
- [ ] Internet connection active

### Build
- [ ] Double-click: **BUILD_APK.bat**
- [ ] Wait for script to complete (5-7 min)
- [ ] Check for "BUILD SUCCESSFUL" message

### Find APK
- [ ] Navigate to: `build\app\outputs\flutter-apk\`
- [ ] Verify `app-release.apk` exists

**✅ PHASE 3 COMPLETE!**

---

## PHASE 4: Install & Test (2 minutes)

### Install on Phone
- [ ] Transfer APK to phone OR keep USB connected
- [ ] Install APK
- [ ] Allow "Unknown sources" if prompted

### Test App
- [ ] Open "Smart Waste Collection" app
- [ ] See splash screen
- [ ] Create account via Signup OR login with demo credentials
- [ ] Verify app works

### Demo Login (Optional)
- [ ] Create users in Firebase Console → Authentication → Users
- [ ] Or use app signup screen
- [ ] Test Resident login
- [ ] Test Driver login  
- [ ] Test Admin login

**✅ PHASE 4 COMPLETE!**

---

## 🎉 ALL DONE!

Your Smart Waste Collection Monitoring System is now running!

---

## Quick Reference

**Build Command**: Double-click `BUILD_APK.bat`  
**APK Location**: `build\app\outputs\flutter-apk\app-release.apk`  
**Install Command**: `flutter install`  

**Demo Users**:
- Admin: admin@smartwaste.com / Admin@123
- Driver: driver1@smartwaste.com / Driver@123
- Resident: resident1@smartwaste.com / Resident@123

---

## Issues?

| Problem | Check |
|---------|-------|
| Build fails | All checkboxes above ticked? |
| Firebase error | google-services.json in correct location? |
| Maps blank | API key in AndroidManifest.xml? |
| Can't login | User created in Firebase? |

**Detailed Help**: `FIREBASE_SETUP_GUIDE.md`

---

**Print this checklist and tick off as you go!** ✅
