# Quick Start Guide - Role-Based Dashboards

## 🚀 Quick Setup (5 minutes)

### 1. Verify Files Are in Place

Check that these files exist:
```
lib/services/auth_service.dart
lib/screens/role_selection_screen.dart
lib/screens/farmhouse_owner_dashboard.dart
lib/screens/add_vehicle_screen.dart
lib/widgets/app_drawer_with_roles.dart
lib/screens/splash_screen.dart (modified)
lib/screens/car_owner_dashboard_new.dart (modified)
```

### 2. Update pubspec.yaml (If Needed)

Ensure these packages are in dependencies:
```yaml
firebase_core: ^4.4.0
firebase_auth: ^6.1.4
cloud_firestore: ^6.1.2
provider: ^6.1.5+1
image_picker: ^1.0.7
```

### 3. Set Up Firestore Structure

Create a user document after signup:
```dart
// After successful signup
await AuthService.initializeUserRoles(uid);

// Then add roles when user selects property type
await AuthService.addUserRole(uid, 'farmhouse_owner');
// or
await AuthService.addUserRole(uid, 'car_owner');
```

### 4. Test the Flow

#### Scenario 1: Single Role User
1. Signup with phone/email
2. Select "Farmhouse Owner" 
3. App should navigate directly to FarmhouseOwnerDashboard
4. Back arrow works
5. Drawer shows role info

#### Scenario 2: Multi-Role User
1. Signup with phone/email
2. Select "Farmhouse Owner" → dashboard appears
3. In Firebase Console, manually add "car_owner" to roles array
4. Logout and login again
5. RoleSelectionScreen should appear
6. Click on "Car Owner" role card
7. CarOwnerDashboard should appear
8. Click "Add Vehicle" button
9. AddVehicleScreen form should work

#### Scenario 3: Role Switching
1. While in CarOwnerDashboard
2. Open drawer (menu icon)
3. Click "Switch to Farmhouse Owner"
4. FarmhouseOwnerDashboard should appear
5. Verify activeRole in Firestore updated

#### Scenario 4: Logout
1. Open drawer
2. Click "Logout"
3. Confirmation dialog appears
4. Click "Logout" again
5. Should navigate to LoginScreen
6. No back button should return to dashboard

## 🧪 Testing Without Building APK

### Quick Test in Emulator/Device

```bash
# Run the app
flutter run

# Navigate: Login → Role Check → Dashboard
# Check Firestore users/{uid} for roles and activeRole
# Verify navigation flows
```

### Firebase Console Testing

1. Go to Firestore
2. Create test user document:
```
users/{testuid}
├── name: "Test User"
├── email: "test@example.com"
├── roles: ["farmhouse_owner", "car_owner"]
├── activeRole: "car_owner"
└── createdAt: now
```

3. Login with that uid
4. Should see RoleSelectionScreen

## 📋 Key Methods to Remember

### Login/Auth
```dart
// AuthService is used internally in splash screen
// No need to call directly unless doing custom auth flows

// For custom signup flows:
await AuthService.initializeUserRoles(uid);
await AuthService.addUserRole(uid, 'car_owner');
```

### Navigation
```dart
// Direct navigation to dashboard
Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (_) => const CarOwnerDashboard()),
);

// Back navigation
Navigator.of(context).pop();

// Logout
await AuthService.logout();
Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (_) => const LoginScreen()),
);
```

## 🔍 Debugging Tips

### Check Firestore Structure
```javascript
// In Firebase Console, check users/{uid}
roles: ["farmhouse_owner", "car_owner"]
activeRole: "car_owner"
```

### Check Logs
```bash
# Grep for [AuthService] or [SplashScreen] logs
flutter logs | grep -E "\[AuthService\]|\[SplashScreen\]"
```

### Test Single vs Multiple Roles
```dart
// Single role: 1 array item → direct dashboard
// Multiple roles: 2+ array items → role selection screen
// No roles: [] → home screen
```

## ⚠️ Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| User goes to HomeScreen instead of dashboard | Check Firestore - roles array might be empty. Call `initializeUserRoles()` |
| RoleSelectionScreen doesn't appear for multi-role user | Verify roles array in Firestore has 2+ items. Logout/login to refresh |
| Drawer doesn't show role options | Ensure AppDrawerWithRoles is passed `uid` parameter |
| Back arrow doesn't work | Use `pop()` not `pushReplacement()` for back |
| Logout doesn't navigate to login | Ensure `Navigator.of(context).pushReplacement()` is called after logout |

## 📊 Feature Checklist

- [x] Role-based routing from splash screen
- [x] Multi-role support with role selection
- [x] Role switching via drawer
- [x] Farmhouse owner dashboard
- [x] Car owner dashboard
- [x] Add vehicle form
- [x] Logout with confirmation
- [x] Back arrow navigation
- [x] Firestore integration

## 📱 UI/UX Features

### RoleSelectionScreen
- Shows role icons
- One-tap selection
- Logout button at bottom
- Loading state during role switch

### AppDrawerWithRoles
- Current role display in header
- Switch role menu items
- Enroll as another owner option
- Settings option
- Logout with confirmation

### Dashboards
- Back arrow in AppBar
- Drawer in side menu
- Property listings
- Stats cards
- Action buttons (Add Vehicle, etc.)

## 🎯 Next Steps After Implementation

1. **Customize Dashboards**
   - Add property-specific analytics
   - Implement bookings management
   - Add revenue tracking

2. **Enhance Enrollment Flow**
   - Implement "Enroll as Another Property Owner" flow
   - Add property verification
   - Set up KYC for new property types

3. **Add Advanced Features**
   - Role-based permissions system
   - Multi-device logout
   - Session management
   - Analytics per role

4. **Optimize Performance**
   - Cache roles in SharedPreferences
   - Implement streaming for real-time role updates
   - Use Firestore indexing

## 📞 Support Resources

- See `ROLE_BASED_DASHBOARDS_GUIDE.md` for full documentation
- Check `lib/services/auth_service.dart` for API details
- Review example implementations in dashboard screens

## ✅ Ready to Use

The implementation is production-ready with:
- ✅ Proper error handling
- ✅ Type-safe code
- ✅ Firestore integration
- ✅ Null safety
- ✅ Consistent UI/UX
- ✅ Back arrow support
- ✅ Logout confirmation
- ✅ Role persistence

---

**Status**: Ready for Production  
**Version**: 1.0.0  
**Last Updated**: February 11, 2026
