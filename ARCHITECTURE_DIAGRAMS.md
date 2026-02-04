# Firebase Auth Architecture Diagrams

## Overall App Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        Flutter App Root                       │
│                         (main.dart)                           │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │   MultiProvider      │
                  │  ┌─────────────────┐ │
                  │  │ AuthController  │ │
                  │  ├─────────────────┤ │
                  │  │SettingsCtrl     │ │
                  │  ├─────────────────┤ │
                  │  │AppLocationCtrl  │ │
                  │  └─────────────────┘ │
                  └──────────┬───────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │   Consumer Auth      │
                  │    (Auth Guard)      │
                  └──────────┬───────────┘
                             │
                ┌────────────┴────────────┐
                │                        │
                ▼                        ▼
         ┌─────────────┐          ┌────────────┐
         │ HomeScreen  │          │LoginScreen │
         │(Logged In)  │          │(Not Auth)  │
         └─────────────┘          └────────────┘
```

---

## Authentication Flow - Signup

```
┌────────────────────────────────────────────────────────────────┐
│                    SignupScreen                               │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ Form Fields: Name, Email, Phone, Password               │ │
│  │                                                          │ │
│  │ [Sign Up →] Button  (Consumer<AuthController>)          │ │
│  └──────────────────────────────────────────────────────────┘ │
└─────────────────────────┬──────────────────────────────────────┘
                          │
                          │ User taps "Sign Up"
                          ▼
              ┌─────────────────────────────┐
              │ signUpUser() method called  │
              │ Validates fields            │
              └──────────────┬──────────────┘
                             │
                             ▼
              ┌──────────────────────────────────────┐
              │ context.read<AuthController>         │
              │   .signUp(email, password)           │
              └──────────────┬───────────────────────┘
                             │
                             ▼
        ┌────────────────────────────────────────┐
        │      Firebase Authentication           │
        │  • Validates email format              │
        │  • Creates user account                │
        │  • Hashes password securely            │
        └────────────────┬───────────────────────┘
                         │
                    ┌────┴────┐
                    │          │
                    ▼          ▼
            ┌──────────────┐   ┌──────────────┐
            │   Success    │   │    Error     │
            └────────┬─────┘   └────────┬─────┘
                     │                  │
                     ▼                  ▼
         ┌─────────────────────┐  ┌──────────────────┐
         │     │  │ errorMessage set │
         │ User Profile        │  │ (Firebase error) │
         │ (UserService)       │  │                  │
         │                     │  │ Show SnackBar:   │
         │ Store: name, phone  │  │ "❌ Email exists" │
         └────────┬────────────┘  └──────────────────┘
                  │
                  ▼
         ┌─────────────────────┐
         │ AuthController fires│
         │ notifyListeners()   │
         │ isAuthenticated=true│
         └────────┬────────────┘
                  │
                  ▼
         ┌─────────────────────┐
         │Consumer rebuilds    │
         │Detects: auth guard  │
         └────────┬────────────┘
                  │
                  ▼
         ┌─────────────────────┐
         │Navigate to Home     │
         │(No Get.off needed)  │
         └─────────────────────┘
```

---

## Authentication Flow - Login

```
┌────────────────────────────────────────────────────────────────┐
│                    LoginScreen                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ [Email Login Toggle]                                     │ │
│  │                                                          │ │
│  │ Email: [__________]                                     │ │
│  │ Password: [__________]                                  │ │
│  │                                                          │ │
│  │ [Login] Button (Consumer<AuthController>)              │ │
│  └──────────────────────────────────────────────────────────┘ │
└─────────────────────────┬──────────────────────────────────────┘
                          │
                          │ User taps "Login"
                          ▼
        ┌─────────────────────────────────────┐
        │ _signInWithEmailViaAuth() called     │
        │ Validates input fields               │
        └──────────────┬──────────────────────┘
                       │
                       ▼
        ┌─────────────────────────────────────┐
        │ context.read<AuthController>        │
        │   .signIn(email, password)          │
        └──────────────┬──────────────────────┘
                       │
                       ▼
      ┌──────────────────────────────────────┐
      │   Firebase Authentication            │
      │  • Validates email exists             │
      │  • Verifies password hash             │
      │  • Issues authentication token        │
      └──────────────┬───────────────────────┘
                     │
                ┌────┴────┐
                │          │
                ▼          ▼
        ┌──────────────┐   ┌──────────────┐
        │   Success    │   │    Error     │
        └────────┬─────┘   └────────┬─────┘
                 │                  │
                 ▼                  ▼
        ┌────────────────────┐  ┌──────────────────┐
        │ AuthController:    │  │ Firebase error:  │
        │ • currentUser set  │  │ • user-not-found │
        │ • isAuth = true    │  │ • wrong-password │
        │ • notifyListeners()│  │ • invalid-email  │
        └────────┬───────────┘  │                  │
                 │              │ Converted to:    │
                 │              │ errorMessage     │
                 │              │                  │
                 │              │ Show SnackBar:   │
                 │              │ "❌ Error text"  │
                 │              └──────────────────┘
                 │
                 ▼
        ┌────────────────────┐
        │Consumer rebuilds   │
        │Detects: auth guard │
        │isAuthenticated=true│
        └────────┬───────────┘
                 │
                 ▼
        ┌────────────────────┐
        │Navigate to Home    │
        │(Auth guard routes) │
        └────────────────────┘
```

---

## State Management - AuthController

```
┌─────────────────────────────────────────────────────┐
│         AuthController (ChangeNotifier)             │
│                                                     │
│  Private Variables:                                 │
│  ├─ _currentUser: User?                            │
│  ├─ _isLoading: bool = false                       │
│  └─ _errorMessage: String = ''                     │
│                                                     │
│  Public Getters:                                    │
│  ├─ isAuthenticated → bool                         │
│  ├─ currentUser → User?                            │
│  ├─ errorMessage → String                          │
│  └─ isLoading → bool                               │
│                                                     │
│  Public Methods:                                    │
│  ├─ signUp({required String email, password})      │
│  ├─ signIn({required String email, password})      │
│  ├─ signOut()                                       │
│  └─ sendPasswordResetEmail(String email)           │
│                                                     │
│  Private Methods:                                   │
│  ├─ _getFirebaseErrorMessage(String code)          │
│  └─ _onAuthStateChanged(User? user)                │
│                                                     │
│  Constructor:                                       │
│  └─ Listens to Firebase Auth state changes         │
│                                                     │
└─────────────────────────────────────────────────────┘
         │
         │ Extends ChangeNotifier
         │
         ▼
    notifyListeners()
         │
         │ Triggers when:
         │ ├─ signUp() completes
         │ ├─ signIn() completes
         │ ├─ signOut() completes
         │ └─ Auth state changes
         │
         ▼
    All Consumers rebuild
         │
         ├─ Auth Guard (home routing)
         ├─ Login button (loading state)
         ├─ Signup button (loading state)
         └─ User profile widget
```

---

## Provider Setup in main.dart

```
┌──────────────────────────────────────────────────────┐
│         void main() async                            │
│  1. Initialize Firebase                              │                            │
│  3. Register GetX controllers                        │
│  4. Run MyApp()                                      │
└─────────────────────┬────────────────────────────────┘
                      │
                      ▼
        ┌─────────────────────────────┐
        │    MyApp() StatelessWidget  │
        └─────────────────────────────┘
                      │
                      ▼
      ┌───────────────────────────────────────┐
      │       MultiProvider                   │
      │  ┌─────────────────────────────────┐  │
      │  │ ChangeNotifierProvider:         │  │
      │  │  AuthController                 │  │
      │  │  SettingsController             │  │
      │  │  AppLocationController          │  │
      │  └─────────────────────────────────┘  │
      │                                       │
      │  ┌─────────────────────────────────┐  │
      │  │ GetMaterialApp                  │  │
      │  │  home: Consumer<AuthController> │  │
      │  │        Auth Guard               │  │
      │  │  getPages: [routes...]          │  │
      │  └─────────────────────────────────┘  │
      └───────────────────────────────────────┘
                      │
                      ▼
            ┌──────────────────────┐
            │  Consumer<AuthCtrl>  │
            │  (Auth Guard)        │
            └──────────┬───────────┘
                       │
                    if (auth.isAuthenticated)
                       │
                ┌──────┴────────┐
                │               │
                ▼               ▼
          ┌─────────────┐   ┌──────────────┐
          │ HomeScreen  │   │ LoginScreen  │
          └─────────────┘   └──────────────┘
```

---

## Data Flow - Complete Cycle

```
User Action
    │
    ▼
┌──────────────────────┐
│  UI Layer            │
│ (Button tap)         │
└──────────────┬───────┘
               │
               ▼
┌──────────────────────┐
│ Event Handler        │
│ (onChange, onTap)    │
└──────────────┬───────┘
               │
               ▼
┌──────────────────────────────────┐
│ AuthController Method            │
│ (signUp, signIn, signOut)        │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│ Firebase Backend                 │
│ (Auth service)                   │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│ Auth State Changes               │
│ (FirebaseAuth.authStateChanges)  │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│ AuthController Listener          │
│ (_onAuthStateChanged)            │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│ Update Internal State            │
│ (_currentUser, _isAuthenticated) │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│ notifyListeners()                │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│ All Consumers Rebuild            │
│ (Home, Auth Guard, etc)          │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│ UI Updates                       │
│ (Buttons, Navigation, Messages) │
└──────────────────────────────────┘
```

---

## Login vs Phone OTP - Side by Side

```
EMAIL LOGIN                          │  PHONE OTP LOGIN
─────────────────────────────────────┼──────────────────────────────────
Firebase Auth                        │ 
Email: user@example.com              │  Phone: +1 234 567 8900
Password: ••••••••••                 │  OTP: 123456
                                     │
User can login again tomorrow        │  User must re-verify with OTP
                                     │
Works on web                         │  Works on mobile primarily
                                     │
Standard auth method                 │  Alternative/additional method
                                     │
Provider-based (AuthController)      │  
                                     │
Toggle in LoginScreen               │  Same toggle in LoginScreen
                                     │
Use either method                    │  Can use both
─────────────────────────────────────┴──────────────────────────────────
```

---

## Error Handling Pipeline

```
Firebase Auth
    │
    ├─ error: FirebaseAuthException
    │
    ▼
AuthController
    │
    ├─ catch (e)
    │ {
    │   _errorMessage = _getFirebaseErrorMessage(e.code)
    │   _isLoading = false
    │   notifyListeners()
    │ }
    │
    ▼
Firebase Error Code          →    User-Friendly Message
─────────────────────────────────────────────────────
user-not-found               →    Email not registered
wrong-password               →    Incorrect password
email-already-in-use         →    Email already exists
weak-password                →    Password too weak
invalid-email                →    Invalid email address
operation-not-allowed        →    Login method not allowed
too-many-requests            →    Too many attempts. Try later.
network-request-failed       →    Network error. Check connection.

    │
    ▼
Show SnackBar
    │
    ├─ "❌ [User Message]"
    │ backgroundColor: Colors.red
    │
    ▼
User Sees Error & Can Retry
```

---

## Settings & Location Integration

```
AppLocationController          SettingsController
(Location + Geocoding)         (Preferences)
         │                              │
         │                              │
         ├─ requestPermission()         ├─ setDarkMode(bool)
         ├─ startListening()            ├─ setLanguage(String)
         ├─ latitude                    ├─ setCurrency(String)
         ├─ longitude                   ├─ setPushNotifications(bool)
         ├─ locationName                ├─ setEmailNotifications(bool)
         │  (city, state)               ├─ setSmsNotifications(bool)
         │                              │
         │                              ├─ Persists to
         └─ Reverse Geocodes            │  SharedPreferences
            (Google Maps API)           │
                                        └─ Loads on initialize()
    All Three Use Provider + ChangeNotifier
    │
    ├─ AutomaticallyNotifyListeners()
    ├─ Can use Consumer<ControllerName>
    └─ Can use context.read<ControllerName>
```

---

## File Organization

```
lib/
├── main.dart (97 lines)
│   └─ MultiProvider, AuthController registration
│      Auth guard for routing
│
├── controllers/
│   ├── auth_controller.dart (180 lines) ✨ NEW
│   │   ├─ signUp()
│   │   ├─ signIn()
│   │   ├─ signOut()
│   │   └─ sendPasswordResetEmail()
│   │
│   ├── settings_controller.dart (108 lines)
│   │   └─ Manages preferences
│   │
│   └── app_location_controller.dart (164 lines)
│       └─ Manages location + geocoding
│
└── screens/
    ├── login_screen.dart (342 lines) ✏️ UPDATED
    │   ├─ Email/password form
    │   ├─ Phone OTP toggle
    │   └─ Uses AuthController
    │
    └── signup_screen.dart (245 lines) ✏️ UPDATED
        ├─ Registration form
        ├─ Firebase signup
       
```

---

## Navigation Flow

```
STARTUP
    │
    ▼
MyApp → Consumer<AuthController>
    │
    ├─ isAuthenticated == false
    │      │
    │      ▼
    │  LoginScreen
    │      │
    │      ├─ [Use email login] → Email fields + Login button
    │      │                            │
    │      │                            ├─ AuthController.signIn()
    │      │                            │
    │      │                            └─ Success → isAuthenticated = true
    │      │
    │      └─ [Use phone login] → Phone field + Continue button
    │                              
    │
    ├─ isAuthenticated == true
    │      │
    │      ▼
    │  HomeScreen
    │      │
    │      ├─ [Settings] → SettingsScreen → [Logout]
    │      │
    │      └─ [Property] → PropertyDetailsScreen → [Book Now]
    │
    └─ SignupScreen (from LoginScreen)
         │
         ├─ Fill form
         │
         └─ [Sign Up] → AuthController.signUp()
                            │
                            └─ Success → isAuthenticated = true
                                      → Navigate to HomeScreen
```

---

## Deployment Readiness Checklist

```
✅ Code Quality
   ├─ No compile errors
   ├─ No runtime warnings
   ├─ Proper error handling
   ├─ Debug logging included
   └─ Best practices followed

✅ Functionality
   ├─ Signup works
   ├─ Login works
   ├─ Logout works
   ├─ Password reset works
   ├─ Session persists
   └─ Auto-routing works

✅ Integration
   ├─ Firebase configured
   ├─ Provider setup complete
   ├─ GetX still functional
   └─ Location & Settings working

✅ Documentation
   ├─ Architecture documented
   ├─ Usage examples provided
   ├─ Error codes mapped
   ├─ Troubleshooting guide
   └─ Commands reference

✅ Production Ready
   ├─ Tested
   ├─ Documented
   ├─ Secure
   └─ Deployable
```

---

**Last Updated:** 2024
**Status:** Complete ✅
