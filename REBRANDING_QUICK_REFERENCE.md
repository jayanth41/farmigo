# Skybase Rebranding - Quick Reference Guide

## What Changed?

### Package Name & App Identifiers
```
OLD: com.example.flutter_application_1
NEW: com.skybase.app
```

### App Display Name
```
OLD: Farmigo
NEW: Skybase
```

---

## Files Modified

### 🤖 Android (4 areas)
- ✅ `android/app/build.gradle.kts` - namespace & applicationId
- ✅ `android/app/src/main/kotlin/com/skybase/app/MainActivity.kt` - moved & package updated
- ✅ `android/app/google-services.json` - package names updated
- ✅ Directory structure: `com/skybase/app/` (created)

### 🍎 iOS (1 file)
- ✅ `ios/Runner.xcodeproj/project.pbxproj` - all bundle identifiers updated

### 🖥️ macOS (2 files)
- ✅ `macos/Runner/Configs/AppInfo.xcconfig` - bundle ID & copyright
- ✅ `macos/Runner.xcodeproj/project.pbxproj` - bundle identifiers

### 🐧 Linux (1 file)
- ✅ `linux/CMakeLists.txt` - APPLICATION_ID

### 🪟 Windows (1 file)
- ✅ `windows/runner/Runner.rc` - company name & copyright

### 📱 Flutter UI (4 files)
- ✅ `lib/screens/about_us_screen.dart` - "About Skybase"
- ✅ `lib/screens/terms_policy_screen.dart` - "By using Skybase..."
- ✅ `lib/screens/farmhouse_details_screen.dart` - Razorpay name
- ✅ `test/widget_test.dart` - test expectations

---

## Pre-Build Checklist

```bash
# 1. Clean Flutter
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Run on each platform
flutter run -d emulator           # Android
flutter run -d iPhone             # iOS
flutter run -d macos              # macOS
flutter run -d web-chrome         # Web

# 4. Check package directory structure
ls -la android/app/src/main/kotlin/com/skybase/app/
```

---

## Testing Checklist

- [ ] App launches without errors on all platforms
- [ ] Firebase authentication works
- [ ] Razorpay payments show "Skybase" in transaction
- [ ] Push notifications work with new package name
- [ ] Deep links/universal links function correctly
- [ ] All UI strings display "Skybase" instead of "Farmigo"
- [ ] Home screen header displays "Skybase"
- [ ] About/Terms pages show correct branding
- [ ] Google Play Services resolves correctly
- [ ] App signing works (if applicable)

---

## Firebase Note ⚠️

**Important**: Firebase project ID remains **`farmigo-704ca`** because:
- This is the actual Firebase project identifier
- Changing it requires migrating Firebase projects
- App package name ≠ Firebase project ID
- No action needed for Firebase

---

## Release Store Updates

When ready to publish:

### Google Play Store
1. Go to Play Console
2. Create new app listing for "Skybase"
3. Upload APK/AAB built with `com.skybase.app` package
4. Update screenshots/description with Skybase branding

### Apple App Store
1. Go to App Store Connect
2. Create new app ID for `com.skybase.app`
3. Upload IPA built with new bundle identifier
4. Update app metadata with Skybase branding

---

## Rollback Commands

If you need to revert to Farmigo:

```bash
# Revert all changes
git checkout .

# Or selectively revert files
git checkout android/app/build.gradle.kts
git checkout android/app/src/main/kotlin/
git checkout lib/screens/
git checkout test/
```

---

## Detailed Changes Log

See `REBRANDING_SUMMARY.md` for complete line-by-line changes

---

## Questions?

Refer to `REBRANDING_SUMMARY.md` for:
- Line numbers of each change
- Before/after comparisons
- Complete file list
- Verification procedures
