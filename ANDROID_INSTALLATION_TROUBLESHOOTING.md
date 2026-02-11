# Android Installation Error - Complete Troubleshooting Guide

**Error**: `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`  
**Date**: February 9, 2026  
**Status**: Device has system-level restrictions preventing app installation

---

## Problem Analysis

### Symptoms
- ❌ Debug APK fails to install
- ❌ Release APK fails to install  
- ❌ Error shows "Install canceled by user"
- ❌ No visible error dialog on device
- ✅ Device can run other apps
- ✅ USB debugging is enabled

### Root Causes (in order of likelihood)

1. **Device has a Restricted User Account**
   - User account lacks permission to install apps
   - Most common cause

2. **Device Management (MDM) Active**
   - Corporate/managed device
   - Admin policies blocking installations
   - Parental controls enabled

3. **"Unknown Sources" Permission Blocked**
   - Device doesn't allow sideloading
   - ADB installation requires special permission

4. **USB Installation Restrictions**
   - Device configured to deny USB installs
   - Security policy in place

---

## Solutions (Try in Order)

### Solution 1: Check User Account Status (EASIEST)

**On the device:**
1. Open Settings
2. Go to System → Multiple users OR Users & accounts
3. Check current user status
4. If it says "Restricted" - switch to owner/admin account
5. Retry installation

**Why this works**: Restricted user accounts cannot install apps from ADB

---

### Solution 2: Enable Unknown Sources (EASY)

**On the device:**
1. Settings → Apps & notifications
2. Advanced → Special app access
3. Find "Install unknown apps"
4. Select "Android Debug Bridge" 
5. Toggle "Allow from this source" ON
6. Retry installation

**Or check Device Administrator:**
1. Settings → Security → Device admin apps
2. Check if any MDM apps are listed
3. Note the app name

---

### Solution 3: Toggle USB Verification Off (EASY)

**On the device:**
1. Settings → System → Developer options
2. Find "Verify apps over USB"
3. Toggle OFF
4. Restart device
5. Retry installation

---

### Solution 4: Use USB File Transfer (MEDIUM - RECOMMENDED)

If ADB installation fails, install via USB:

**Step 1: Build the APK**
```bash
cd /Users/prathyushagartigipati/farmigo
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

**Step 2: Transfer via USB**
```bash
# Copy APK to device Downloads
adb push build/app/outputs/flutter-apk/app-release.apk /sdcard/Download/
```

**Step 3: Install manually on device**
- On device: Open Files app
- Navigate to: Download folder
- Tap the `app-release.apk` file
- System will prompt: "Install this app?"
- Tap "Install"
- Wait for installation

**Why this works**: Direct file installation sometimes bypasses ADB restrictions

---

### Solution 5: Use Android Emulator (MEDIUM)

If physical device has permanent restrictions:

**Step 1: Open Android Studio**
- Launch Android Studio
- Click "Device Manager" (bottom right)

**Step 2: Create Virtual Device**
- Click "Create Device"
- Select Pixel 4 or similar
- Select Android 14 (API 34)
- Click Create

**Step 3: Start Emulator**
- Click Play button next to device
- Wait for emulator to boot (2-3 minutes)

**Step 4: Run Flutter**
```bash
flutter run
# Should auto-select emulator
```

**Advantages:**
- No user restrictions
- No MDM policies
- Full control
- Good for testing

---

### Solution 6: Switch to Different User (IF APPLICABLE)

```bash
# Check users on device
adb shell pm list users

# Switch to user 0 (usually owner)
adb shell am switch-user 0

# Then try installing
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

### Solution 7: Check for MDM (Corporate Device)

If this is a company device:

**Check if managed:**
```bash
adb shell settings get global device_owner
adb shell settings get global profile_owner
```

**If output shows a package name**: Device is managed

**Solution**: Contact device administrator to:
- Allow app installation for your user
- Add your app to whitelist
- Temporarily disable restrictions for testing

---

### Solution 8: Force Install via Downgrade (ADVANCED)

```bash
# Install with grant for any account
adb install -g build/app/outputs/flutter-apk/app-release.apk

# Install and downgrade existing
adb install -r -d build/app/outputs/flutter-apk/app-release.apk

# Install for specific user
adb install --user 0 build/app/outputs/flutter-apk/app-release.apk
```

---

## Current Device Status

```
Device ID:  22041216I
Address:    192.168.31.140:36863 (reconnected on new port)
Android:    Android 14 (API 34)
Arch:       ARM64
Status:     Connected
```

---

## Recommended Action Plan

### Immediate (Try First - 5 minutes)
1. ✓ On device, check user account type
2. ✓ Enable "Unknown sources"
3. ✓ Toggle "Verify apps over USB" OFF
4. ✓ Try installing again: `flutter run -d 192.168.31.140:36863`

### If Still Failing (Try Next - 10 minutes)
5. ✓ Use USB file transfer method:
   ```bash
   flutter build apk --release
   adb push build/app/outputs/flutter-apk/app-release.apk /sdcard/Download/
   ```
   Then manually install on device

### If Still Failing (Alternative - 15 minutes)
6. ✓ Use Android Emulator instead:
   - Open Android Studio
   - Create virtual device
   - Run `flutter run`

### Last Resort (Advanced)
7. ✓ Contact device administrator (if corporate device)
8. ✓ Factory reset device (⚠️ deletes all data)

---

## Testing the Rebranded App (When Installed)

Once you get the app installed, verify:

```bash
# Check package name
adb shell pm list packages | grep skybase
# Expected: com.skybase.app

# Check app info
adb shell dumpsys package com.skybase.app

# Launch app
adb shell am start -n com.skybase.app/.MainActivity

# View logs
adb logcat | grep -i skybase
```

**Verify in app:**
- ✓ Header shows "Skybase"
- ✓ About screen shows "About Skybase"
- ✓ Firebase auth works
- ✓ Razorpay shows "Skybase"

---

## Why This Keeps Happening

1. **You rebranded the package name** from `com.example.flutter_application_1` to `com.skybase.app`
2. **New package name = new app** from Android's perspective
3. **Device has user restrictions** that prevent installing new packages
4. **System blocks installation** at the Android level (not Flutter issue)

This is a **device configuration issue**, not a code issue.

---

## Prevention for Future Releases

When releasing to users:
1. Create new Google Play Store listing for `com.skybase.app`
2. Don't try to upgrade from `com.example.flutter_application_1`
3. Ask users to uninstall old app first
4. Provide migration guide
5. Use cloud backup (Firebase) for data preservation

---

## Files for Reference

- **Rebranding Summary**: See `REBRANDING_SUMMARY.md`
- **Deployment Guide**: See `DEPLOYMENT_GUIDE.md`
- **Quick Reference**: See `REBRANDING_QUICK_REFERENCE.md`

---

## Bottom Line

✅ **Your code is fine** - All rebranding changes are correct
❌ **Device is blocking installation** - System-level restriction
✓ **Solutions exist** - USB file transfer or emulator recommended

Try **Solution 4 (USB file transfer)** or **Solution 5 (Emulator)** - both have high success rates.

