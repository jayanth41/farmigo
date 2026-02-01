# Farmigo - Farm Booking & Property Management App

A modern Flutter application for farm property browsing, bookings, and user management powered by Firebase Authentication and Cloud Firestore backend.

## 🎯 Key Features

### Authentication
✅ **Firebase Email/Password Auth** - Secure signup and login  
✅ **Phone OTP Login** - Via Firebase (toggle between methods)  
✅ **Auth Guard** - Automatic routing based on login state  
✅ **Password Reset** - Email-based password recovery  

### User Management
✅ **Settings Controller** - Notifications, language, currency, dark mode  
✅ **User Profiles** - Stored in Cloud Firestore with persistent storage  
✅ **Preference Persistence** - SharedPreferences for local settings  

### Location Features
✅ **Real-time GPS** - Geolocator with runtime permissions  
✅ **Reverse Geocoding** - Convert coordinates to city/state names  
✅ **Location Display** - Shows current location on home screen  

### Property Management
✅ **Property Browsing** - Grid view of available properties  
✅ **Property Details** - Detailed page with images, pricing, location  
✅ **Booking System** - Book properties directly (requires login)  
✅ **Favorites** - Mark properties as favorites (GetX-based)  

### Navigation & UI
✅ **Multi-screen App** - Home, Profile, Bookings, Offers, Settings, etc.  
✅ **GetX Navigation** - Named routes and navigation  
✅ **Modern Design** - Material 3 with custom theme  
✅ **Responsive Layout** - Works on phones and tablets  

---

## 🏗️ Architecture

### State Management
- **Provider** - Used for AuthController, SettingsController, AppLocationController
- **GetX** - Used for FavoritesController, BookingsController, Navigation
- **Firebase** - Handles user authentication and session management

### Backend
- **Firebase Authentication** - Email/password and phone OTP user management
- **Cloud Firestore** - Database for properties, bookings, user profiles

### Data Flow
```
User Input → Controller → Backend (Firebase/Cloud Firestore)
         ↓
    State Change
         ↓
   notifyListeners()
         ↓
   UI Rebuilds (Consumer/GetBuilder)
```

---

## 📁 Project Structure

```
lib/
├── main.dart                          # App root, MultiProvider setup, auth guard
├── firebase_options.dart              # Firebase configuration
├── theme/                             # App theme and colors
├── controllers/
│   ├── auth_controller.dart          # Firebase email/password auth
│   ├── settings_controller.dart       # User settings (SharedPreferences)
│   ├── app_location_controller.dart  # GPS + reverse geocoding
│   ├── favorites_controller.dart      # GetX favorites management
│   └── bookings_controller.dart       # GetX bookings management
├── screens/
│   ├── login_screen.dart             # Email/phone login UI
│   ├── signup_screen.dart            # Registration with Firebase
│   ├── home_screen.dart              # Main app screen with properties
│   ├── property_details_screen.dart  # Property details + booking
│   ├── settings_screen.dart          # User settings UI
│   ├── profile_screen.dart           # User profile page
│   ├── favorites_screen.dart         # Favorite properties
│   ├── bookings_screen.dart          # User bookings history
│   ├── farmhouses_screen.dart        # Farmhouse listings
│   ├── car_rentals_screen.dart       # Car rental listings
│   ├── offers_screen.dart            # Special offers
│   └── splash_screen.dart            # App startup screen
├── navigation/
│   └── app_routes.dart               # Named route definitions
├── models/                           # Data models
├── services/
│   ├── user_service.dart             # Firestore-backed user operations
│   └── booking_service.dart          # Booking operations (backend optional)
├── widgets/                          # Reusable UI components
├── data/                             # Local data and constants
└── assets/                           # Images, animations, icons
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- Firebase project configured

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd farmigo
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Download google-services.json (Android)
   - Download GoogleService-Info.plist (iOS)
   - Place in respective directories
   - Already configured in firebase_options.dart

4. **Configure Backend (if needed)**
  - The project uses Firebase by default. If you add another backend, update configuration accordingly.

5. **Run the app**
   ```bash
   flutter run
   ```

---

## 🔐 Authentication Flow

### Email/Password Signup
1. User fills signup form (name, email, phone, password)
2. Taps "Sign Up" button
3. AuthController.signUp() calls Firebase Auth
4. User profile created in Cloud Firestore
5. Auth guard auto-navigates to Home

### Email/Password Login
1. User enters email and password
2. Taps "Login" button
3. AuthController.signIn() authenticates with Firebase
4. Auth guard auto-navigates to Home
5. Session persists across app restarts

### Logout
1. User taps logout (in Settings/Profile)
2. AuthController.signOut() clears Firebase session
3. Auth guard auto-navigates to Login

### Phone OTP (Alternative)
1. User selects "Use phone login" toggle
2. Enters phone number and gets OTP
3. Firebase handles phone verification
4. Logs user in

---

## 📚 Important Files to Know

- [FIREBASE_AUTH_INTEGRATION.md](FIREBASE_AUTH_INTEGRATION.md) - Complete auth setup documentation
- [FIREBASE_AUTH_QUICK_REFERENCE.md](FIREBASE_AUTH_QUICK_REFERENCE.md) - Code examples and usage patterns
- [FAVORITES_ARCHITECTURE.md](FAVORITES_ARCHITECTURE.md) - Favorites feature architecture
- [firebase_options.dart](lib/firebase_options.dart) - Firebase config (auto-generated)

---

## 🎮 Using AuthController

### In Your Widgets

**Option 1: Using context.read() (One-time access)**
```dart
final authCtrl = context.read<AuthController>();
final success = await authCtrl.signIn(email: email, password: password);
```

**Option 2: Using Consumer (Reactive UI)**
```dart
Consumer<AuthController>(
  builder: (context, authCtrl, _) {
    return Text(authCtrl.isAuthenticated 
        ? 'Logged in as ${authCtrl.currentUser?.email}'
        : 'Not logged in');
  },
)
```

**Option 3: Using context.watch() (Inside build)**
```dart
@override
Widget build(BuildContext context) {
  final authCtrl = context.watch<AuthController>();
  return Text(authCtrl.isAuthenticated ? 'Logged in' : 'Logged out');
}
```

See [FIREBASE_AUTH_QUICK_REFERENCE.md](FIREBASE_AUTH_QUICK_REFERENCE.md) for more examples.

---

## 🛠️ Using Settings Controller

### Save Settings
```dart
final settingsCtrl = context.read<SettingsController>();
await settingsCtrl.setDarkMode(true);
await settingsCtrl.setLanguage('es'); // Spanish
await settingsCtrl.setCurrency('USD');
```

### Read Settings
```dart
Consumer<SettingsController>(
  builder: (context, settingsCtrl, _) {
    return Scaffold(
      backgroundColor: settingsCtrl.darkMode ? Colors.black : Colors.white,
      // Use settingsCtrl.language, settingsCtrl.currency, etc.
    );
  },
)
```

---

## 📍 Using Location Controller

### Get Current Location
```dart
Consumer<AppLocationController>(
  builder: (context, locCtrl, _) {
    return Column(
      children: [
        Text('Latitude: ${locCtrl.latitude}'),
        Text('Longitude: ${locCtrl.longitude}'),
        Text('Location: ${locCtrl.locationName}'), // e.g., "New York, NY"
      ],
    );
  },
)
```

### Request Permission
```dart
final locCtrl = context.read<AppLocationController>();
final granted = await locCtrl.requestPermission();
if (granted) {
  locCtrl.startListening(); // Start GPS updates
}
```

---

## 📦 Dependencies

### Core Flutter
- `flutter` - Flutter SDK
- `cupertino_icons` - iOS icons

### State Management
- `provider: ^6.1.5+1` - ChangeNotifier state management
- `get: ^4.6.6` - GetX for navigation and state

### Firebase
- `firebase_core: ^3.15.2` - Firebase SDK
- `firebase_auth: ^5.7.0` - Authentication
- `cloud_firestore: ^5.6.12` - Database (future use)

### Backend
- `supabase_flutter: ^2.5.0` - Supabase client
- `http: ^1.1.0` - HTTP requests

### Location & Geocoding
- `geolocator: ^12.0.0` - GPS/location
- `geocoding: ^2.2.2` - Reverse geocoding
- `permission_handler: ^12.0.1` - Runtime permissions

### Storage
- `shared_preferences: ^2.2.0` - Local key-value storage

### UI & Navigation
- `get: ^4.6.6` - Named routes and navigation
- `app_links: ^6.4.1` - Deep linking
- `url_launcher: ^6.1.0` - Open URLs
- `path_provider: ^2.1.0` - App directories

### Utilities
- `intl: ^0.19.0` - Internationalization
- `firebase_analytics: ^10.7.0` - Analytics (future)
- `lottie: ^3.1.0` - Animations

---

## 🧪 Testing

### Manual Test Scenarios

**Signup & Authentication**
- [ ] Sign up with new email
- [ ] Sign up with existing email (should error)
- [ ] Login with correct credentials
- [ ] Login with wrong password
- [ ] Login with unregistered email
- [ ] Password reset email sent successfully

**Navigation**
- [ ] After login, app shows HomeScreen
- [ ] After logout, app shows LoginScreen
- [ ] Closing app keeps user logged in
- [ ] Clearing app data logs user out

**Location Features**
- [ ] App requests location permission
- [ ] Location updates every 5 seconds
- [ ] Reverse geocoding shows city/state
- [ ] Works with location services disabled

**Settings**
- [ ] Dark mode toggle persists
- [ ] Language change persists
- [ ] Currency selection persists
- [ ] Notification toggles work

**Bookings**
- [ ] Only logged-in users can book
- [ ] Booking appears in Supabase
- [ ] Booking appears in bookings history
- [ ] Booking details display correctly

---

## 🐛 Troubleshooting

### Issue: "No implementation found" error
**Solution:** Run `flutter pub get` and rebuild completely
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: Firebase auth not working
**Solution:** Check Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select Farmigo project
3. Enable Email/Password under Authentication
4. Check google-services.json is in android/app

### Issue: Location not updating
**Solution:** Check permissions
1. Go to app settings on device
2. Grant location permission
3. Ensure location services enabled on device
4. Restart app

### Issue: Supabase operations failing
**Solution:** Check Supabase credentials
1. Check URL and anon key in main.dart
2. Verify tables exist in Supabase
3. Check row-level security policies
4. Look at Supabase logs for errors

---

## 🚀 Deployment

### Android
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### iOS
```bash
flutter build ios --release
# Then follow xcode deployment steps
```

### Web
```bash
flutter build web --release
# Output: build/web
```

---

## 📖 Documentation

- [Firebase Auth Integration Guide](FIREBASE_AUTH_INTEGRATION.md)
- [Firebase Auth Quick Reference](FIREBASE_AUTH_QUICK_REFERENCE.md)
- [Favorites Feature Architecture](FAVORITES_ARCHITECTURE.md)
- [Android Setup Guide](ANDROID_SETUP_GUIDE.md)
- [Firebase Setup Checklist](FIREBASE_SETUP_CHECKLIST.md)

---

## 📄 License

This project is private and confidential.

---

## 👥 Contributors

- Development Team

---

## 📞 Support

For issues, questions, or feature requests, contact the development team.

---

## 🎉 Latest Updates

**Firebase Authentication Integration** (2024)
- ✅ Email/password signup and login
- ✅ Firebase Auth backend integration
- ✅ User-friendly error messages
- ✅ Auth guard for automatic routing
- ✅ Session persistence
- ✅ Password reset functionality

**Location & Settings**
- ✅ Real-time GPS location tracking
- ✅ Reverse geocoding (city/state)
- ✅ Settings persistence
- ✅ Dark mode, language, currency options

**Previous Features**
- ✅ Property browsing and details
- ✅ Booking system
- ✅ Favorites management
- ✅ User profiles
- ✅ Offers and promotions

---

**Last Updated:** 2024  
**Status:** In Active Development 🚀
