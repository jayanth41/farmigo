# Firebase Auth Quick Reference

## Using AuthController in Your Code

### Example 1: Sign In with Email/Password
```dart
// Inside a widget
final authCtrl = context.read<AuthController>();
final success = await authCtrl.signIn(email: 'user@example.com', password: 'password123');

if (success) {
  // Show success - auth guard will auto-navigate to HomeScreen
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Login successful')),
  );
} else {
  // Show error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('❌ ${authCtrl.errorMessage}')),
  );
}
```

### Example 2: Sign Up with Email/Password
```dart
final authCtrl = context.read<AuthController>();
final success = await authCtrl.signUp(email: 'newuser@example.com', password: 'password123');

if (success) {
  // Create user profile in database
  // Auth guard will auto-navigate to HomeScreen
} else {
  // Show error message
}
```

### Example 3: Sign Out
```dart
final authCtrl = context.read<AuthController>();
await authCtrl.signOut();
// Auth guard will auto-navigate to LoginScreen
```

### Example 4: Reset Password
```dart
final authCtrl = context.read<AuthController>();
final success = await authCtrl.sendPasswordResetEmail('user@example.com');

if (success) {
  print('✅ Reset email sent');
} else {
  print('❌ ${authCtrl.errorMessage}');
}
```

### Example 5: Listen to Auth State Changes
```dart
// In any widget, use Consumer to react to auth state
Consumer<AuthController>(
  builder: (context, authCtrl, _) {
    if (authCtrl.isLoading) {
      return const CircularProgressIndicator();
    }
    if (authCtrl.isAuthenticated) {
      return Text('Logged in as: ${authCtrl.currentUser?.email}');
    }
    return const Text('Not logged in');
  },
)
```

### Example 6: Show Loading State on Button
```dart
Consumer<AuthController>(
  builder: (context, authCtrl, _) {
    return ElevatedButton(
      onPressed: authCtrl.isLoading ? null : () => _handleLogin(),
      child: authCtrl.isLoading
          ? const CircularProgressIndicator()
          : const Text('Login'),
    );
  },
)
```

## AuthController Properties

### Getters
- `isAuthenticated` → bool (true if user logged in)
- `currentUser` → User? (Firebase user object or null)
- `errorMessage` → String (user-friendly error message)
- `isLoading` → bool (true during auth operations)

### Methods
- `signUp({required String email, required String password})` → Future<bool>
- `signIn({required String email, required String password})` → Future<bool>
- `signOut()` → Future<void>
- `sendPasswordResetEmail(String email)` → Future<bool>

## Navigation Notes

❌ **DO NOT** use `Get.offAllNamed('/home')` after signup/login  
✅ **DO** let the auth guard handle navigation

The auth guard in main.dart automatically routes based on `isAuthenticated`:
```dart
home: Consumer<AuthController>(
  builder: (context, auth, _) {
    if (auth.isAuthenticated) return const HomeScreen();
    return const LoginScreen();
  },
),
```

When AuthController fires `notifyListeners()`, the Consumer rebuilds and routes automatically.

## Error Handling Examples

```dart
// Firebase returns specific error codes
// AuthController converts them to friendly messages

"user-not-found" → "Email not registered"
"wrong-password" → "Incorrect password"
"email-already-in-use" → "Email already exists"
"weak-password" → "Password too weak"
"invalid-email" → "Invalid email address"
"operation-not-allowed" → "Login method not allowed"
"too-many-requests" → "Too many failed attempts. Try again later."
"network-request-failed" → "Network error. Check your connection."
```

Display these with:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('❌ ${authCtrl.errorMessage}')),
);
```

## Imports Required

When using AuthController in a new screen:

```dart
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
```

## Testing Authentication

### Test Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your Farmigo project
3. Go to Authentication → Users
4. See all registered users with signup timestamps

### Test Database / Profiles
1. Verify user profiles in Cloud Firestore (Firestore Console)
2. In Firebase Console → Firestore, open the `users` collection
3. Confirm user documents are created on signup with expected fields

### Debug Logging
AuthController includes debug prints:
```
✅ Auth: User logged in [user@email.com]
✅ Auth: Signup successful
✅ Auth: Password reset email sent
✅ Auth: User logged out
❌ Auth: Failed to sign in: user-not-found
❌ Auth: Signup failed: email-already-in-use
```

Check your console or `flutter run --verbose` to see these logs.

## Persistence

Firebase Auth automatically persists:
- User session across app restarts
- Token refresh
- User state

This means:
- User stays logged in after app closes
- No need to manually save tokens
- Logout clears the session

To test: Sign in → Close app → Reopen → Should still be logged in

## Phone OTP Login

Phone login still works as before (unchanged):
- Uses existing Supabase phone auth
- Toggle in LoginScreen between email/phone
- Separate from Firebase email auth

Phone OTP now uses Firebase Authentication's phone verification.
The app uses Firebase Auth for email/password and phone OTP flows; user
profiles are stored in Cloud Firestore.

## Troubleshooting

### Error: "Cannot read property 'isAuthenticated' of null"
**Cause:** AuthController not provided in MultiProvider  
**Fix:** Check lib/main.dart has `ChangeNotifierProvider<AuthController>`

### Error: "MissingPluginException: No implementation found"
**Cause:** Missing platform implementations  
**Fix:** Run `flutter pub get` and rebuild app completely

### Button stays disabled after login
**Cause:** AuthController.isLoading stuck as true  
**Check:** Debug logs for errors, verify signup/login completed

### Can't access currentUser
**Cause:** User not authenticated  
**Fix:** Check `isAuthenticated` before accessing `currentUser`

### Password reset email not sent
**Cause:** Email doesn't exist in Firebase  
**Fix:** Make sure user is registered (use correct email)

---

Created: 2024  
Updated: After Firebase Auth integration
