# 🔥 FIREBASE & GOOGLE MAPS SETUP GUIDE

## You ONLY need to do these 2 setups (10 minutes total)

---

## SETUP 1: Firebase Configuration (7 minutes)

### Step 1: Create Firebase Project
1. Open browser and go to: **https://console.firebase.google.com/**
2. Click **"Add project"** (or select existing)
3. Project name: `smart-waste-collection` (or any name)
4. Click **Continue**
5. Disable Google Analytics (optional)
6. Click **Create project**
7. Wait for project creation (30 seconds)

### Step 2: Enable Authentication
1. In Firebase Console, click **"Authentication"** in left menu
2. Click **"Get started"**
3. Click **"Email/Password"** provider
4. Toggle **"Enable"** to ON
5. Click **Save**

### Step 3: Enable Firestore Database
1. Click **"Firestore Database"** in left menu
2. Click **"Create database"**
3. Select **"Start in test mode"** (we'll secure it later)
4. Choose location: **asia-south1 (Mumbai)** or closest to you
5. Click **Enable**
6. Wait for database creation (1-2 minutes)

### Step 4: Add Android App
1. Click **Project Overview** (top left, click gear icon ⚙️)
2. Click **"Project settings"**
3. Scroll to **"Your apps"** section
4. Click the **Android icon** (</>)
5. Fill in:
   - **Android package name**: `com.bmc.smart_waste_app` (EXACTLY this)
   - **App nickname**: Smart Waste Collection (optional)
   - **Debug signing certificate**: Leave blank
6. Click **"Register app"**
7. Click **"Download google-services.json"**
8. **IMPORTANT**: Save this file!

### Step 5: Place Firebase Config File
1. Navigate to your project folder:
   ```
   c:\Users\Manas S Parekar\OneDrive\Desktop\fp\android\app\
   ```
2. **Delete** the existing `google-services.json` file (it's a placeholder)
3. **Copy** your downloaded `google-services.json` here
4. Verify the file is at: `android\app\google-services.json`

✅ **Firebase Setup Complete!**

---

## SETUP 2: Google Maps API Key (3 minutes)

### Step 1: Enable Maps SDK
1. Go to: **https://console.cloud.google.com/**
2. Select your Firebase project from top dropdown
3. Search for: **"Maps SDK for Android"**
4. Click on it
5. Click **"Enable"**
6. Wait for activation (30 seconds)

### Step 2: Create API Key
1. Go to: **https://console.cloud.google.com/apis/credentials**
2. Click **"+ CREATE CREDENTIALS"**
3. Select **"API key"**
4. Copy the generated key (looks like: `AIzaSy...`)
5. **Save it somewhere safe**

### Step 3: Add API Key to Project
1. Open this file in any text editor (Notepad, VS Code, etc.):
   ```
   c:\Users\Manas S Parekar\OneDrive\Desktop\fp\android\app\src\main\AndroidManifest.xml
   ```

2. Find this line (around line 21):
   ```xml
   android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
   ```

3. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:
   ```xml
   android:value="AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"/>
   ```

4. **Save** the file

✅ **Google Maps Setup Complete!**

---

## 🎉 YOU'RE DONE!

### Now just run the batch file:

1. Double-click: **BUILD_APK.bat**
2. Wait 5-7 minutes
3. Your APK will be ready!

---

## 📝 Optional: Create Demo Users in Firebase

After setup, you can create demo users:

1. Go to Firebase Console → Authentication → Users
2. Click **"Add user"**
3. Create these accounts:

**Admin:**
- Email: `admin@smartwaste.com`
- Password: `Admin@123`

**Driver:**
- Email: `driver1@smartwaste.com`
- Password: `Driver@123`

**Resident:**
- Email: `resident1@smartwaste.com`
- Password: `Resident@123`

**Note**: You can also just use the app's signup screen to create these accounts!

---

## ❓ Troubleshooting

### Firebase Issues
- **Can't download google-services.json**: Make sure you registered the Android app first
- **Package name error**: Must be EXACTLY `com.bmc.smart_waste_app`
- **Firestore error**: Make sure you created the database in test mode

### Google Maps Issues
- **API key not working**: Make sure you enabled "Maps SDK for Android" (not JavaScript)
- **Billing required**: Google gives $200 free credit monthly (enough for development)
- **Maps show blank**: Check API key is correctly placed in AndroidManifest.xml

### Build Issues
- **Flutter not found**: Run `flutter doctor` first
- **Build fails**: Check both Firebase and Maps setup are complete
- **Dependencies error**: Run `flutter pub get` manually first

---

## 🚀 Quick Checklist

Before running BUILD_APK.bat, verify:

- [ ] Firebase project created
- [ ] Authentication enabled (Email/Password)
- [ ] Firestore Database created (Test mode)
- [ ] Android app registered in Firebase
- [ ] `google-services.json` downloaded and placed in `android/app/`
- [ ] Google Maps API key created
- [ ] API key added to `AndroidManifest.xml`
- [ ] Flutter installed and working (`flutter doctor`)

Once all checkboxes are ticked → **Run BUILD_APK.bat**

---

## 📞 Need Help?

If you get stuck:
1. Check the error message carefully
2. Verify each step above is completed
3. Run `flutter doctor` to check Flutter setup
4. Check Firebase Console for any error messages

**Most common mistake**: Forgetting to replace the API key in AndroidManifest.xml

---

**Total Setup Time: 10 minutes**
**Then: Just double-click BUILD_APK.bat and wait!** 🎉
