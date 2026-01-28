# Firebase Setup & Configuration Guide

## Overview
This guide covers setting up Firebase Authentication, Firestore, and Google Sign-In for the Farmigo Flutter app.

## Prerequisites
- Firebase project created at [console.firebase.google.com](https://console.firebase.google.com)
- Google Cloud project with OAuth 2.0 credentials
- Android SDK with Google Play Services

## Step 1: Firebase Console Setup

### 1.1 Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project"
3. Enter project name (e.g., "Farmigo")
4. Enable Google Analytics (optional)
5. Click "Create project"

### 1.2 Enable Authentication Methods

#### Email/Password
1. Go to Authentication → Sign-in method
2. Click "Email/Password"
3. Enable "Email/Password"
4. Click "Save"

#### Google Sign-In
1. Go to Authentication → Sign-in method
2. Click "Google"
3. Enable Google Sign-In
4. Select support email
5. Click "Save"

#### Phone OTP
1. Go to Authentication → Sign-in method
2. Click "Phone"
3. Enable Phone
4. Add test numbers for development (optional)
5. Click "Save"

### 1.3 Create Firestore Database
1. Go to Firestore Database
2. Click "Create Database"
3. Start in **Test mode** (for development)
4. Select location (closest to your region)
5. Click "Enable"

### 1.4 Set Firestore Security Rules

Replace default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User profiles
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      allow read: if request.auth.uid != null;
    }
    
    // Bookings
    match /bookings/{bookingId} {
      allow read: if request.auth.uid != null;
      allow write: if request.auth.uid == resource.data.userId;
      allow create: if request.auth.uid == request.resource.data.userId;
    }
    
    // Reviews
    match /reviews/{reviewId} {
      allow read: if request.auth.uid != null;
      allow create: if request.auth.uid == request.resource.data.userId;
      allow update, delete: if request.auth.uid == resource.data.userId;
    }
  }
}
```

## Step 2: Android Configuration

### 2.1 Download google-services.json
1. In Firebase Console, go to Project Settings
2. Under "Your apps", select Android app
3. Download `google-services.json`
4. Place in `android/app/` directory

### 2.2 Android Build Configuration
File: `android/app/build.gradle.kts`

Already configured in the project with:
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

### 2.3 Configure Google Sign-In OAuth

1. In Firebase Console, go to Project Settings → Service Accounts
2. Click "Generate new private key"
3. Save the JSON file securely
4. Go to Google Cloud Console
5. Enable Google+ API
6. Create OAuth 2.0 credentials for Android:
   - Get SHA-1 of your app signing key:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   - Add SHA-1 to Firebase Console: Project Settings → App verification

### 2.4 Android Manifest Permissions
File: `android/app/src/main/AndroidManifest.xml`

Required permissions (usually auto-added by Flutter):
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

## Step 3: iOS Configuration

### 3.1 Download GoogleService-Info.plist
1. In Firebase Console, go to Project Settings
2. Under "Your apps", select iOS app
3. Download `GoogleService-Info.plist`
4. Open Xcode: `ios/Runner.xcworkspace`
5. Drag `GoogleService-Info.plist` into Xcode
6. Ensure "Copy items if needed" is checked
7. Select Runner target

### 3.2 Configure Google Sign-In
1. In Xcode, go to Info.plist (right-click, Open As → Source Code)
2. Add the following before closing `</dict>`:
```xml
<key>GIDClientID</key>
<string>[YOUR_GOOGLE_CLIENT_ID]</string>
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.[YOUR_REVERSE_CLIENT_ID]</string>
    </array>
  </dict>
</array>
```

Find these values in GoogleService-Info.plist file.

### 3.3 Pod Update
```bash
cd ios
pod update
cd ..
```

## Step 4: Verify Setup

### Test Firebase Connection
Run the app and check logs:
```bash
flutter run -v
```

Look for:
- ✅ Firebase initialized
- ✅ Firestore connected
- ✅ Google Sign-In ready

### Test Authentication
1. **Email/Password**: Sign up with email and password
2. **Google Sign-In**: Click "Sign in with Google"
3. **Phone OTP**: Enter phone number and verify with OTP

### Verify Firestore Storage
1. In Firebase Console, go to Firestore
2. Navigate to `users` collection
3. Verify user document created with:
   - uid
   - email
   - name
   - phone
   - loginType
   - createdAt

## Step 5: Development Considerations

### Enable Debug Logging
In `lib/main.dart`:
```dart
// Enable Firebase debug logs
if (kDebugMode) {
  FirebaseAuth.instance.setLanguageCode('en');
}
```

### Test Users (Optional)
Add test users in Firebase Console:
- Authentication → Users tab
- Click "Add user"
- Enter email and password
- Click "Add user"

### Phone Number Testing
1. Add test phone numbers in Authentication → Phone
2. Use format: `+[country_code][number]` (e.g., `+919876543210`)
3. Use code `123456` for OTP in development

## Step 6: Production Deployment

### Android Release
```bash
flutter build apk --release
flutter build appbundle --release
```

**Before release:**
- Update SHA-1 in Firebase Console with release key SHA-1
- Configure Google Play Console OAuth credentials

### iOS Release
```bash
flutter build ios --release
```

**Before release:**
- Update provisioning profiles
- Configure TestFlight or App Store OAuth

### Production Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Only user can read/write their own profile
      allow read, write: if request.auth.uid == userId;
    }
    
    match /bookings/{bookingId} {
      // Only owner and admins can read
      allow read: if request.auth.uid == resource.data.userId || 
                     request.auth.token.admin == true;
      // Only owner can write
      allow write: if request.auth.uid == resource.data.userId;
    }
  }
}
```

## Troubleshooting

### Google Sign-In Not Working

**Problem**: "Sign-in cancelled" or blank sign-in dialog

**Solutions**:
1. Verify `google-services.json` is in `android/app/`
2. Check SHA-1 fingerprint matches in Firebase Console
3. Ensure Google+ API is enabled in Google Cloud Console
4. Try clearing app cache: `flutter clean && flutter pub get`

### Phone OTP Not Working

**Problem**: "Too many SMS" or code not received

**Solutions**:
1. Verify phone number format: `+[country_code][number]`
2. Check Firebase Console allows phone auth
3. Verify test numbers are added in Firebase Console
4. Wait 60 seconds between retry attempts

### Firestore User Profile Not Saving

**Problem**: User signs in but profile not in Firestore

**Solutions**:
1. Check Firestore Rules allow writes
2. Verify Firestore database exists and is in `Test mode`
3. Check app logs for Firestore errors
4. Ensure `FirestoreUserService` is imported correctly

### Dark Mode Not Persisting

**Problem**: Dark mode setting resets on app restart

**Solutions**:
1. Check `SettingsController` initializes properly
2. Verify SharedPreferences has write permissions
3. Check logs for initialization errors

## API Endpoints & Resources

### Firebase Console
- [Firebase Console](https://console.firebase.google.com)
- [Google Cloud Console](https://console.cloud.google.com)

### Documentation
- [Firebase Auth Docs](https://firebase.flutter.dev/docs/auth/overview/)
- [Firestore Docs](https://firebase.flutter.dev/docs/firestore/overview/)
- [Google Sign-In Docs](https://pub.dev/packages/google_sign_in)

### Support
- Firebase Support: [firebase.google.com/support](https://firebase.google.com/support)
- Stack Overflow: Tag with `firebase` and `flutter`

## Security Checklist

- [ ] Firebase Rules configured in production
- [ ] SHA-1 fingerprints added for all signing keys
- [ ] Google OAuth credentials secured
- [ ] Phone test numbers removed before production
- [ ] Firestore indexes created for queries
- [ ] User data encrypted in transit (automatic with HTTPS)
- [ ] Sensitive data not logged (email, passwords, tokens)
- [ ] API keys restricted in Google Cloud Console

## Next Steps

1. ✅ Follow this guide step-by-step
2. ✅ Test all authentication methods
3. ✅ Verify Firestore operations
4. ✅ Test dark mode toggle
5. ✅ Deploy to TestFlight/Play Store for beta testing
6. ✅ Monitor Firebase Analytics
7. ✅ Gather user feedback
8. ✅ Release to production

---

**Last Updated**: January 28, 2026
**Status**: Complete ✅
