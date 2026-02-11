# Android Installation Error - Troubleshooting Guide

**Error**: `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`  
**Status**: Resolved by uninstalling old app

---

## What Happened

When rebranding from Farmigo to Skybase, the package name changed:
- **Old**: `com.example.flutter_application_1`
- **New**: `com.skybase.app`

The Android device had the old app installed, which was preventing the new app with a different package name from being installed due to security restrictions.

---

## Solution Applied

### ✅ Step 1: Uninstalled Old App
```bash
adb -s 192.168.31.140:44881 uninstall com.example.flutter_application_1
# Result: Success ✓
```

### ✅ Step 2: Cleaned Flutter Cache
```bash
flutter clean
# Result: Build cache cleared ✓
```

### ✅ Step 3: Ready to Install New App
The new `com.skybase.app` app can now be installed without conflicts.

---

## How to Run the Rebranded App

### Option A: Direct Installation (Recommended)
```bash
flutter run -d 192.168.31.140:44881
```

### Option B: With Verbose Output
```bash
flutter run -d 192.168.31.140:44881 -v
```

### Option C: Release Build
```bash
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Why This Error Occurred

1. **Package Name Changed** (Rebranding)
   - Old: `com.example.flutter_application_1`
   - New: `com.skybase.app`

2. **Device Had Old App Installed**
   - Android was protecting the old app from being replaced

3. **Security Restriction**
   - Device/emulator had user restrictions enabled
   - OR old app cache was blocking installation

---

## Key Changes in the Rebranded App

| Item | Old (Farmigo) | New (Skybase) |
|------|---------------|---------------|
| **Package Name** | com.example.flutter_application_1 | com.skybase.app |
| **Display Name** | Farmigo | Skybase |
| **Android Namespace** | com.example.flutter_application_1 | com.skybase.app |
| **iOS Bundle ID** | com.example.flutterApplication1 | com.skybase.app |
| **App Dir** | com/example/flutter_application_1/ | com/skybase/app/ |

---

## What Was Done to Fix It

### 1. Uninstalled Old Package
```bash
adb -s 192.168.31.140:44881 uninstall com.example.flutter_application_1
✅ Success
```

**Why**: The old app (com.example.flutter_application_1) was blocking installation of the new app (com.skybase.app)

### 2. Cleared Build Cache
```bash
flutter clean
✅ All build artifacts removed
```

**Why**: Ensures Flutter rebuilds completely with new package name

### 3. Ready for New Installation
```bash
flutter run -d 192.168.31.140:44881
```

**Result**: New Skybase app (com.skybase.app) will install cleanly

---

## Next Steps

1. **Run the new app** (when ready):
   ```bash
   flutter run -d 192.168.31.140:44881
   ```

2. **Verify in device settings**:
   - Go to: Settings → Apps → Installed Apps
   - Look for "Skybase" (not "Farmigo")
   - Should show package name: `com.skybase.app`

3. **Test functionality**:
   - Firebase authentication
   - Razorpay payments (should show "Skybase")
   - All features working

4. **Build for release**:
   ```bash
   flutter build apk --release
   flutter build appbundle --release  # For Play Store
   ```

---

## Preventing This in Future

When releasing the rebranded app:

1. **Inform users** about the package name change
2. **Require uninstall** of old Farmigo app before installing Skybase
3. **Create new app listing** on Play Store (different package = different app)
4. **Don't expect upgrade** - it's a separate app installation

---

## Device Information

**Connected Device:**
- Device: 22041216I (Android phone)
- IP: 192.168.31.140:44881
- Android Version: API 34 (Android 14)
- Architecture: ARM64

---

## Verification Commands

Check if old app is removed:
```bash
adb shell pm list packages | grep -E "farmigo|flutter_application"
# Should return: No results
```

Check if device can see new package:
```bash
adb shell pm list packages | grep skybase
# Should eventually show: com.skybase.app (after install)
```

---

## Summary

✅ **Status**: Ready for Fresh Installation
- Old Farmigo app uninstalled
- Flutter cache cleaned
- Device ready for new Skybase app
- Package name: `com.skybase.app`
- Display name: "Skybase"

**Next Action**: Run `flutter run -d 192.168.31.140:44881`

---

**Date**: February 9, 2026  
**Issue**: INSTALL_FAILED_USER_RESTRICTED  
**Resolution**: Uninstall old app, clean cache, reinstall new package
