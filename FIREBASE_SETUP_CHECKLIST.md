# Firebase Phone Authentication Setup Checklist

## ✅ Code Implementation (COMPLETED)

- [x] Added Firebase Core dependency (`firebase_core: ^2.27.0`)
- [x] Added Firebase Auth dependency (`firebase_auth: ^4.17.0`)
- [x] Initialized Firebase in `main.dart`
- [x] Created phone number login screen
- [x] Created OTP verification screen
- [x] Fixed all compilation errors

## 📋 Firebase Console Configuration Required

### 1. **Enable Phone Authentication**
- [ ] Go to Firebase Console: https://console.firebase.google.com
- [ ] Select your project: `farmigo-704ca`
- [ ] Navigate to: **Authentication** → **Sign-in method**
- [ ] Click on **Phone**
- [ ] Enable it (toggle ON)
- [ ] Save

### 2. **Configure Authorized Domains** (If using Web)
- [ ] In Authentication settings, go to **Settings**
- [ ] Ensure your domain is authorized

### 3. **Android Configuration**
- [ ] Download `google-services.json` from Firebase Console
- [ ] Place it in: `android/app/google-services.json`
- [ ] Ensure `google-services.json` already exists in your project

### 4. **iOS Configuration**
- [ ] Download `GoogleService-Info.plist` from Firebase Console
- [ ] Add it to Xcode project under `ios/Runner`
- [ ] Build settings should reference it

### 5. **Test Credentials** (Optional - for Development)
- [ ] In Firebase Console → Authentication → Phone
- [ ] You can add test phone numbers for development
- [ ] Use any 6-digit code as OTP for testing

## 🔧 Code Configuration

### Default Country Code
- Currently set to: **+91 (India)**
- To change: Edit `lib/screens/login_screen.dart` line with `'+91$phoneNumber'`

### OTP Timer
- Currently set to: **60 seconds**
- To change: Edit `lib/screens/otp_screen.dart` line with `_secondsRemaining = 60`

## 🚀 Next Steps to Run

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run the app:**
   ```bash
   flutter run
   ```

3. **Test Flow:**
   - App launches → Splash Screen
   - Navigate to Login Screen
   - Enter phone number (with +91 prefix, or it's added automatically)
   - Click "Send OTP"
   - Wait for SMS (or use test credentials from Firebase Console)
   - Enter 6-digit OTP
   - Click "Verify OTP"
   - Should navigate to Home Screen on success

## ⚠️ Common Issues & Solutions

### Issue: "FirebaseException: [firebase_auth/invalid-phone-number]"
**Solution:** Ensure phone number format is correct (include country code)

### Issue: "FirebaseException: [firebase_auth/missing-client-identifier]"
**Solution:** Ensure `google-services.json` is properly placed in `android/app/`

### Issue: "FirebaseException: [firebase_auth/invalid-verification-code]"
**Solution:** Ensure the OTP entered matches the one received via SMS

### Issue: App crashes during Firebase initialization
**Solution:** Check if Firebase is enabled in your console and google-services.json is valid

## 📱 Testing Recommendations

1. **With Real Phone Number:**
   - Use actual phone number
   - Wait for real SMS
   - Enter received OTP

2. **With Test Credentials (Firebase Console):**
   - Add test phone number in Firebase Console
   - Use any 6-digit code as OTP
   - Useful for quick testing

## 🔐 Security Notes

- OTP codes are sent via Firebase (managed by Google)
- Credentials are verified server-side
- Phone numbers are not stored (unless you add them to Firestore later)
- Current implementation supports phone-only authentication

## ✨ Features Included

- ✅ Phone number input with +91 prefix
- ✅ OTP sending via Firebase
- ✅ 6-digit OTP verification
- ✅ Auto-focus between OTP fields
- ✅ 60-second countdown timer for resend
- ✅ Error handling with user feedback
- ✅ Loading states during authentication
- ✅ Navigation to HomeScreen on success

---

**Last Updated:** January 6, 2026
**Status:** Ready for Firebase Console Configuration
