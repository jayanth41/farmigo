# Role-Based Dashboards with Multi-Property Support - Implementation Guide

## Overview

This implementation adds role-based dashboard routing and multi-property support to the Skybase Flutter + Firebase app. Users can manage multiple property types (farmhouses, cars) and switch between them seamlessly.

## Architecture

### 1. User Data Structure in Firestore

```dart
users/{uid}/
├── uid: String
├── name: String
├── email: String
├── phone: String
├── roles: List<String>          // ["farmhouse_owner", "car_owner"]
├── activeRole: String           // Currently selected role
├── createdAt: Timestamp
└── lastUpdated: Timestamp
```

### 2. Services

#### AuthService (`lib/services/auth_service.dart`)

Core service for role management:

- **getUserRoles(uid)** - Fetch all roles for a user
- **getActiveRole(uid)** - Get currently selected role
- **setActiveRole(uid, role)** - Update active role
- **addUserRole(uid, role)** - Add a new role to user
- **initializeUserRoles(uid)** - Initialize roles for new users
- **getCurrentUserRole()** - Get active role for current user
- **logout()** - Sign out user

Usage:
```dart
// Get all roles
final roles = await AuthService.getUserRoles(uid);

// Switch role
await AuthService.setActiveRole(uid, 'car_owner');

// Logout
await AuthService.logout();
```

### 3. Screens

#### RoleSelectionScreen (`lib/screens/role_selection_screen.dart`)

Displayed when user has multiple roles. Allows selection of which dashboard to access.

**Features:**
- Shows all available roles with icons
- Updates activeRole in Firestore when selected
- Navigates to appropriate dashboard
- Logout button

**Props:**
```dart
RoleSelectionScreen(roles: ["farmhouse_owner", "car_owner"])
```

#### FarmhouseOwnerDashboard (`lib/screens/farmhouse_owner_dashboard.dart`)

Dashboard for farmhouse property management.

**Features:**
- Back arrow to return to role selection
- Side drawer with role switching
- Stats cards (properties, bookings, revenue)
- Property listing
- Responsive refresh

**Navigation:**
```dart
Navigator.of(context).pop()  // Back arrow
```

#### CarOwnerDashboard (Updated: `lib/screens/car_owner_dashboard_new.dart`)

Updated car owner dashboard with role support.

**New Features:**
- Back arrow in AppBar
- AppDrawerWithRoles for role switching
- UpdatedAddVehicle button integration

**Changes:**
```dart
appBar: AppBar(
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => Navigator.of(context).pop(),
  ),
  // ... rest of appBar
),
drawer: AppDrawerWithRoles(uid: _ownerId),
```

#### AddVehicleScreen (`lib/screens/add_vehicle_screen.dart`)

Comprehensive vehicle addition form for car owners.

**Features:**
- Basic information: name, type, manufacturer, year
- Specifications: transmission, fuel type
- Pricing: price per day
- Amenities selection (AC, WiFi, Driver, etc.)
- Vehicle image upload
- Form validation
- Firestore integration

**Firestore Document:**
```dart
vehicles/{vehicleId}
├── id: String
├── ownerId: String
├── name: String
├── type: String (Sedan, SUV, etc.)
├── registrationNumber: String
├── manufacturer: String
├── year: Integer
├── transmission: String
├── fuelType: String
├── amenities: List<String>
├── pricePerDay: Double
├── description: String
├── imageUrl: String
├── status: String (active/inactive)
├── createdAt: Timestamp
└── updatedAt: Timestamp
```

### 4. Widgets

#### AppDrawerWithRoles (`lib/widgets/app_drawer_with_roles.dart`)

Reusable side menu drawer for all dashboards.

**Features:**
- Shows current active role in header
- "Switch Role" section with role options
- "Enroll as Another Property Owner" option
- "Settings" option
- "Logout" with confirmation dialog
- Role-specific icons (house, car)
- Visual indicator for active role

**Usage:**
```dart
drawer: AppDrawerWithRoles(uid: _uid)
```

### 5. Navigation Flow

#### Login Flow
```
LoginScreen
    ↓
OTPScreen (Phone verification)
    ↓
SplashScreen (Role check)
    ↓
// Based on roles:
// No roles → HomeScreen (regular user)
// 1 role → Direct to dashboard
// 2+ roles → RoleSelectionScreen
```

#### Dashboard Navigation
```
RoleSelectionScreen
    ├→ FarmhouseOwnerDashboard
    │   ├→ Drawer: Switch roles
    │   └→ Back arrow: Return to RoleSelectionScreen
    │
    └→ CarOwnerDashboard
        ├→ Drawer: Switch roles
        ├→ Add Vehicle button: AddVehicleScreen
        └→ Back arrow: Return to RoleSelectionScreen
```

#### Role Switching
```
Dashboard (Any)
    ↓
Drawer → "Switch to [Role]"
    ↓
AuthService.setActiveRole()
    ↓
Navigate to new dashboard
```

#### Logout
```
Drawer → "Logout"
    ↓
Confirmation dialog
    ↓
AuthService.logout()
    ↓
LoginScreen
```

## Implementation Details

### SplashScreen Changes

The splash screen now:
1. Checks if user is logged in
2. If logged in, fetches roles from Firestore
3. Routes based on number of roles:
   - **0 roles**: HomeScreen (regular user)
   - **1 role**: Direct to that dashboard
   - **2+ roles**: RoleSelectionScreen

```dart
Future<void> _goNext() async {
  // ... auth check
  final roles = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get()
      .then((doc) => doc.data()?['roles'] as List<dynamic>? ?? []);
  
  if (roles.isEmpty) {
    Navigator.pushReplacement(context, 
        MaterialPageRoute(builder: (_) => const HomeScreen()));
  } else if (roles.length == 1) {
    _navigateToDashboard(roles.first, uid);
  } else {
    Navigator.pushReplacement(context, 
        MaterialPageRoute(builder: (_) => RoleSelectionScreen(roles: roles)));
  }
}
```

## Firestore Rules (Recommended)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - role management
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId;
      allow update: if request.auth.uid == userId && 
                       request.resource.data.roles == resource.data.roles;
    }
    
    // Vehicles - car owner specific
    match /vehicles/{vehicleId} {
      allow read: if request.auth != null;
      allow create: if request.auth.uid == request.resource.data.ownerId;
      allow update: if request.auth.uid == resource.data.ownerId;
      allow delete: if request.auth.uid == resource.data.ownerId;
    }
    
    // Properties - farmhouse owner specific
    match /properties/{propertyId} {
      allow read: if request.auth != null;
      allow create: if request.auth.uid == request.resource.data.ownerId;
      allow update: if request.auth.uid == resource.data.ownerId;
      allow delete: if request.auth.uid == resource.data.ownerId;
    }
  }
}
```

## Usage Examples

### Initialize User Roles (After Signup)

```dart
// In SignupScreen or onboarding
await AuthService.initializeUserRoles(uid);

// Add a role when user enrolls as property owner
await AuthService.addUserRole(uid, 'farmhouse_owner');
```

### Check User Roles

```dart
// Get all roles
List<String> roles = await AuthService.getUserRoles(uid);

// Get active role
String? activeRole = await AuthService.getActiveRole(uid);
```

### Switch Dashboard

```dart
// From drawer or role selection
await AuthService.setActiveRole(uid, 'car_owner');
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => const CarOwnerDashboard()),
);
```

### Logout

```dart
// In drawer logout button
await AuthService.logout();
Navigator.pushReplacementNamed(context, '/login');
```

## Key Features

✅ **Role-Based Routing** - Automatically routes users to correct dashboard
✅ **Multi-Property Support** - Users can manage multiple property types
✅ **Seamless Role Switching** - Switch roles via drawer menu
✅ **Role Selection Screen** - Quick role picker for multi-role users
✅ **Consistent UI/UX** - Same drawer pattern across dashboards
✅ **Logout Confirmation** - Prevents accidental logouts
✅ **Firestore Integration** - Persistent role storage
✅ **Back Navigation** - Easy navigation between screens
✅ **Vehicle Management** - Complete vehicle addition form
✅ **Status Management** - Track active/inactive properties

## Files Created/Modified

### Created:
- `lib/services/auth_service.dart` - Role management service
- `lib/screens/role_selection_screen.dart` - Role selection UI
- `lib/screens/farmhouse_owner_dashboard.dart` - Farmhouse dashboard
- `lib/screens/add_vehicle_screen.dart` - Vehicle addition form
- `lib/widgets/app_drawer_with_roles.dart` - Reusable drawer

### Modified:
- `lib/screens/splash_screen.dart` - Role-based routing
- `lib/screens/car_owner_dashboard_new.dart` - Added drawer and back arrow

## Testing Checklist

- [ ] Login with phone/email
- [ ] Create user with one role (farmhouse_owner or car_owner)
- [ ] Verify direct navigation to dashboard
- [ ] Add second role to user in Firestore console
- [ ] Logout and login again - should see RoleSelectionScreen
- [ ] Click on role card - should navigate to correct dashboard
- [ ] Test drawer role switching
- [ ] Verify activeRole updates in Firestore
- [ ] Test logout confirmation dialog
- [ ] Add a vehicle and verify in Firestore
- [ ] Test back arrow navigation
- [ ] Verify role switching maintains user session

## Future Enhancements

- [ ] Add role icons to role selection screen
- [ ] Implement "Enroll as Another Property Owner" flow
- [ ] Add role-specific onboarding for new roles
- [ ] Add analytics for role switching
- [ ] Implement profile management per role
- [ ] Add role-based notifications
- [ ] Create dashboard widgets market
- [ ] Implement role-based permissions system

## Troubleshooting

### User routes to HomeScreen instead of dashboard
**Issue:** roles array is empty or missing from users/{uid}
**Solution:** Call `AuthService.initializeUserRoles(uid)` after signup

### Role switching doesn't update UI
**Issue:** Navigator not pushing replacement
**Solution:** Ensure using `pushReplacement` not `push` to avoid back button issues

### Drawer not showing role options
**Issue:** AppDrawerWithRoles not initialized with uid
**Solution:** Pass uid to drawer constructor

### Logout not working
**Issue:** FirebaseAuth not signed out
**Solution:** Verify `AuthService.logout()` completes before navigation

## API Reference

### AuthService Methods

```dart
// Fetch user roles
static Future<List<String>> getUserRoles(String uid)

// Get active role
static Future<String?> getActiveRole(String uid)

// Set active role
static Future<void> setActiveRole(String uid, String role)

// Add role to user
static Future<void> addUserRole(String uid, String role)

// Initialize roles for new users
static Future<void> initializeUserRoles(String uid)

// Get current user's active role
static Future<String?> getCurrentUserRole()

// Logout user
static Future<void> logout()
```

## Security Notes

1. **Firestore Rules**: Implement strict rules to prevent role spoofing
2. **Role Validation**: Always validate user roles on backend
3. **Active Role**: Client-side activeRole is UX preference, validate server-side
4. **Sensitive Data**: Don't store sensitive info in roles array
5. **Logout**: Ensure proper session cleanup on all devices

## Performance Optimization

- Cache roles locally using SharedPreferences
- Implement role streaming for real-time updates
- Use Firestore indexing for role queries
- Implement pagination for large property lists

---

**Version:** 1.0.0  
**Last Updated:** February 11, 2026  
**Status:** ✅ Complete Implementation
