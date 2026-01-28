# Development Commands Quick Reference

## Installation & Setup

### Initial Setup
```bash
cd c:\Users\garig\Documents\flutter_projects\farmigo
flutter pub get
```

### Clean Build (if having issues)
```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter run
```

---

## Running the App

### Run on Connected Device
```bash
flutter run
```

### Run in Release Mode
```bash
flutter run --release
```

### Run with Verbose Logging
```bash
flutter run --verbose
```

### Run on Specific Device
```bash
flutter devices  # List available devices
flutter run -d <device-id>
```

---

## Building

### Build APK (Android Release)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build AAB (Android App Bundle)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Build iOS
```bash
flutter build ios --release
```

### Build Web
```bash
flutter build web --release
```

---

## Debugging

### Check for Errors
```bash
flutter analyze  # Static analysis
flutter doctor   # Check Flutter setup
flutter pub get  # Resolve dependencies
```

### Run Tests
```bash
flutter test
```

### Debug Specific File
```bash
flutter run --verbose
# Then check console output for your debug prints
```

### View Logs
```bash
flutter logs
```

---

## Code Quality

### Format Code
```bash
dart format lib/
```

### Fix Analyzer Issues
```bash
dart fix --apply
```

### Run Linter
```bash
flutter analyze
```

---

## Package Management

### Add New Package
```bash
flutter pub add package_name
# Example: flutter pub add firebase_storage
```

### Update All Packages
```bash
flutter pub upgrade
```

### Check Outdated Packages
```bash
flutter pub outdated
```

### Remove Package
```bash
flutter pub remove package_name
```

### Get Dependencies
```bash
flutter pub get
```

---

## Firebase-Specific Commands

### Check Firebase Setup
```bash
# Check if google-services.json exists in android/app/
# Check if GoogleService-Info.plist exists in ios/
```

### Verify Firebase Configuration
```dart
// In main.dart, check this runs without errors:
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

## Supabase Commands

### Check Supabase Initialization
```dart
// In main.dart, check this runs without errors:
await Supabase.initialize(
  url: 'https://kvnwikjxjimztjqsycti.supabase.co',
  anonKey: 'eyJhbGciOi...',
);
```

---

## Git Commands (if using version control)

```bash
git status
git add .
git commit -m "message"
git push
```

---

## Useful Flutter Commands

### Hot Reload
```
Press 'R' in terminal during `flutter run`
# or
Press Ctrl+S in most IDEs
```

### Hot Restart
```
Press 'r' in terminal during `flutter run`
# Full app restart (slower than hot reload)
```

### Stop Running App
```
Press 'Q' in terminal during `flutter run`
```

### List All Available Commands
```bash
flutter help
```

---

## Development Workflow

### Typical Development Session
```bash
# 1. Get latest code
git pull

# 2. Get dependencies
flutter pub get

# 3. Start development
flutter run

# 4. Use hot reload (Ctrl+S) for quick testing
# 5. Make code changes
# 6. Hot reload to see changes
# 7. Use hot restart (R) if hot reload doesn't work
# 8. Stop when done (Q)

# 9. Format code before committing
dart format lib/

# 10. Commit changes
git add .
git commit -m "Feature: implement auth"
git push
```

---

## Troubleshooting Commands

### Clear Build Cache
```bash
flutter clean
flutter pub get
flutter run
```

### Reinstall Dependencies
```bash
rm -r pubspec.lock
flutter pub get
```

### Check System Setup
```bash
flutter doctor
# Shows Android SDK, iOS tools, etc.
```

### View Help for Any Command
```bash
flutter help <command>
# Example: flutter help run
```

---

## IDE Shortcuts (VS Code)

| Action | Shortcut |
|--------|----------|
| Hot Reload | Ctrl+S or Cmd+S |
| Open Command Palette | Ctrl+Shift+P |
| Format Document | Shift+Alt+F |
| Go to Definition | F12 |
| Find References | Shift+F12 |
| Find in Files | Ctrl+Shift+F |
| Terminal | Ctrl+` |

---

## Useful VS Code Commands

```bash
# Open command palette
Ctrl+Shift+P

# Common commands:
- "Flutter: Run"
- "Flutter: Hot Reload"
- "Flutter: Hot Restart"
- "Flutter: Open DevTools"
- "Dart: Format Document"
- "Dart: Analyze"
```

---

## Firebase Console

**URL:** https://console.firebase.google.com

### Check Authentication Users
```
1. Go to Firebase Console
2. Select "Farmigo" project
3. Click "Authentication" in left menu
4. Go to "Users" tab
5. See all registered users
```

### Check App Logs
```
1. Firebase Console
2. Click "Firestore Database"
3. Or "Cloud Logging"
4. View real-time logs
```

---

## Supabase Dashboard

**URL:** https://app.supabase.com

### Check User Profiles
```
1. Go to Supabase Dashboard
2. Select "farmigo" project
3. Click "Table Editor"
4. Click "users" table
5. See all user profiles created on signup
```

### Check Bookings
```
1. Supabase Dashboard
2. Table Editor
3. Click "bookings" table
4. See all bookings made by users
```

---

## Environment Variables (if needed)

### Create .env File
```bash
# .env file in project root
FIREBASE_API_KEY=xxx
SUPABASE_URL=https://kvnwikjxjimztjqsycti.supabase.co
SUPABASE_ANON_KEY=xxx
```

### Load Environment Variables
```dart
// In pubspec.yaml:
dev_dependencies:
  flutter_dotenv: ^5.0.0

// In code:
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  // Now use: dotenv.env['FIREBASE_API_KEY']
  runApp(const MyApp());
}
```

---

## Memory & Performance Monitoring

### Monitor App Performance
```bash
flutter run --verbose
# Check console for frame rendering times
# Look for "jank" warnings
```

### Check Memory Usage
```
During `flutter run`, DevTools shows memory usage:
- Look at Memory tab
- Check for memory leaks
- Monitor garbage collection
```

---

## Common Issues & Fixes

### "No implementation found"
```bash
flutter clean
flutter pub get
flutter run
```

### "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter run
```

### "Pod install failed"
```bash
cd ios
rm Podfile.lock
pod install
cd ..
flutter run
```

### "iOS build failed"
```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
flutter run
```

---

## Useful Commands Summary

```bash
# Setup
flutter pub get

# Running
flutter run
flutter run --release
flutter run --verbose

# Building
flutter build apk --release
flutter build ios --release

# Quality
flutter analyze
dart format lib/
flutter test

# Maintenance
flutter clean
flutter pub upgrade
flutter doctor
```

---

## Documentation Links

- [Flutter Docs](https://docs.flutter.dev)
- [Dart Docs](https://dart.dev/guides)
- [Firebase Docs](https://firebase.google.com/docs)
- [Supabase Docs](https://supabase.com/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [GetX Documentation](https://pub.dev/packages/get)

---

**Keep this file handy for quick reference!** 🚀

Last Updated: 2024
