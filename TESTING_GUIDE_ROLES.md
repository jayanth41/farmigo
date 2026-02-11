# Integration Testing Guide - Role-Based Dashboards

## Test Plan Overview

This guide provides step-by-step testing procedures for the role-based dashboard implementation.

---

## Test Case 1: Single Role User Login

**Prerequisites:**
- User account ready with one role assigned

**Steps:**
1. Launch app from splash screen
2. Tap "Login with Phone"
3. Enter phone number and OTP
4. Verify user is logged in
5. Wait for splash animation

**Expected Results:**
- ✅ Splash screen shows for 2 seconds
- ✅ SplashScreen fetches roles from Firestore
- ✅ User navigates directly to dashboard (no role selection)
- ✅ Dashboard AppBar has back arrow
- ✅ Dashboard has drawer menu

**Firestore Check:**
```javascript
users/{uid}
├── roles: ["farmhouse_owner"]
├── activeRole: "farmhouse_owner"
```

---

## Test Case 2: Multi-Role User Login

**Prerequisites:**
- User account with 2+ roles assigned in Firestore

**Steps:**
1. Launch app
2. Go through login flow
3. Observe splash screen
4. Wait for role selection

**Expected Results:**
- ✅ RoleSelectionScreen appears after splash
- ✅ Shows all roles as selectable cards
- ✅ Each role shows appropriate icon
- ✅ "Logout" button present at bottom
- ✅ Clicking role navigates to dashboard

**Firestore Check:**
```javascript
users/{uid}
├── roles: ["farmhouse_owner", "car_owner"]
├── activeRole: "car_owner" (or whichever was last selected)
```

---

## Test Case 3: Role Switching from Drawer

**Preconditions:**
- Multi-role user logged in on a dashboard

**Steps:**
1. From dashboard, tap menu/hamburger icon
2. Drawer opens showing current role in header
3. Locate "Switch to [Other Role]" option
4. Tap on it
5. Confirm navigation to new dashboard

**Expected Results:**
- ✅ Drawer opens correctly
- ✅ Current role is highlighted/checked
- ✅ Other roles show as "Switch to [Role]"
- ✅ Clicking switches to new dashboard
- ✅ Firestore activeRole updates
- ✅ Drawer closes after selection

**Code to Verify:**
```dart
// In AppDrawerWithRoles
_switchRole('car_owner');
```

---

## Test Case 4: Adding a Vehicle

**Preconditions:**
- User in CarOwnerDashboard

**Steps:**
1. Tap "+ Add Vehicle" button in AppBar
2. Enter vehicle details:
   - Name: "Test Car"
   - Type: "Sedan"
   - Year: "2024"
   - Manufacturer: "Toyota"
   - Registration: "TS09AB1234"
   - Transmission: "Automatic"
   - Fuel: "Petrol"
   - Price: "2000"
3. Select at least 2 amenities
4. Tap "Add Vehicle"

**Expected Results:**
- ✅ Form validates required fields
- ✅ Image upload option available
- ✅ Submit button shows loading state
- ✅ Success snackbar appears
- ✅ Navigate back to dashboard
- ✅ Vehicle appears in Firestore

**Firestore Check:**
```javascript
vehicles/{vehicleId}
├── name: "Test Car"
├── ownerId: uid
├── pricePerDay: 2000
├── status: "active"
└── createdAt: timestamp
```

---

## Test Case 5: Logout Flow

**Preconditions:**
- User logged in on any dashboard

**Steps:**
1. Open drawer menu
2. Scroll to bottom
3. Tap "Logout" button
4. Confirmation dialog appears
5. Tap "Logout" in dialog
6. Observe navigation

**Expected Results:**
- ✅ Drawer opens
- ✅ "Logout" button visible at bottom
- ✅ Confirmation dialog appears
- ✅ Dialog has "Cancel" and "Logout" buttons
- ✅ Clicking Cancel closes dialog
- ✅ Clicking Logout:
  - ✅ Drawer closes
  - ✅ User is signed out in Firebase
  - ✅ App navigates to LoginScreen
  - ✅ No back button returns to dashboard

**Code Check:**
```dart
// Should call
await AuthService.logout();
Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (_) => const LoginScreen()),
);
```

---

## Test Case 6: Back Arrow Navigation

**Preconditions:**
- User in FarmhouseOwnerDashboard or CarOwnerDashboard

**Steps:**
1. Observe AppBar
2. Tap back arrow (←)
3. Observe navigation

**Expected Results:**
- ✅ Back arrow visible in AppBar
- ✅ Clicking navigates to RoleSelectionScreen (for multi-role)
- ✅ Clicking navigates to previous screen (for single-role)
- ✅ History is maintained

---

## Test Case 7: No Roles User

**Preconditions:**
- New user with empty roles array

**Steps:**
1. Create user via signup
2. Don't assign any roles
3. Login
4. Observe navigation

**Expected Results:**
- ✅ Splash screen checks roles
- ✅ Empty roles array detected
- ✅ Navigate to HomeScreen (regular user flow)
- ✅ No dashboard access yet
- ✅ User can still browse properties

**Firestore Check:**
```javascript
users/{uid}
├── roles: []
├── activeRole: null
```

---

## Test Case 8: Enroll as Another Property Owner

**Preconditions:**
- Multi-role user in dashboard

**Steps:**
1. Open drawer
2. Tap "Enroll as Another Property Owner"
3. Observe what happens

**Expected Results:**
- ✅ Drawer opens
- ✅ Option is visible
- ✅ Clicking shows snackbar: "Coming Soon"
- ✅ No crash or navigation error

**Note:** This feature is marked for future implementation

---

## Test Case 9: Settings Option

**Preconditions:**
- User in any dashboard

**Steps:**
1. Open drawer
2. Tap "Settings"
3. Observe

**Expected Results:**
- ✅ Drawer closes
- ✅ Snackbar shows: "Settings screen coming soon"
- ✅ No crash

**Note:** Settings feature pending development

---

## Test Case 10: Concurrent Role Switch

**Preconditions:**
- Multi-role user on Dashboard A

**Steps:**
1. Open drawer
2. Start switching to Dashboard B
3. Quickly open drawer again
4. Observe state consistency

**Expected Results:**
- ✅ First switch completes
- ✅ Second drawer open shows correct active role
- ✅ No race condition errors
- ✅ UI is consistent

---

## Firestore Validation Tests

### Test 11: Verify Role Persistence

**Steps:**
1. User with roles logged in
2. Force kill app
3. Relaunch app
4. Check Firestore

**Expected Results:**
- ✅ Roles still present in Firestore
- ✅ ActiveRole unchanged
- ✅ User gets same dashboard on relaunch

### Test 12: Role Array Integrity

**Check:**
```javascript
// Valid role values
"farmhouse_owner" ✅
"car_owner" ✅
"hotel_owner" (future) ✅

// Invalid should be prevented
""  ❌ Empty string
null ❌ Null value
123 ❌ Number
```

### Test 13: ActiveRole Consistency

**Steps:**
1. Set activeRole to value in roles array ✅
2. Set activeRole to value NOT in roles array ❌
3. Observe behavior

**Expected Results:**
- ✅ activeRole should be in roles array
- ✅ If mismatch, app should reset to first role

---

## Performance Tests

### Test 14: Role Fetch Performance

**Steps:**
1. Measure time from login to dashboard
2. Monitor Firestore reads
3. Check network latency

**Expected Results:**
- ✅ Dashboard appears within 3 seconds
- ✅ Only 1-2 Firestore reads for role check
- ✅ Minimal network overhead

### Test 15: Drawer Open Performance

**Steps:**
1. Open drawer from dashboard
2. Measure animation smoothness
3. Check for UI lag

**Expected Results:**
- ✅ Drawer opens smoothly
- ✅ No frame drops
- ✅ Roles load instantly (cached)

---

## Error Handling Tests

### Test 16: No Internet Connection

**Steps:**
1. Turn off internet
2. Try to login
3. Try role operations

**Expected Results:**
- ✅ Clear error messages
- ✅ Retry options available
- ✅ No crashes

### Test 17: Firestore Permission Denied

**Steps:**
1. Modify Firestore rules to deny access
2. Perform role operations
3. Observe error handling

**Expected Results:**
- ✅ Graceful error handling
- ✅ User sees error message
- ✅ No uncaught exceptions

### Test 18: Timeout Handling

**Steps:**
1. Simulate slow network
2. Role switch operation
3. Observe timeout behavior

**Expected Results:**
- ✅ Operation completes or times out gracefully
- ✅ User can retry
- ✅ No infinite loading

---

## Edge Cases

### Test 19: Very Long Role Names

**Data:**
```dart
"very_long_property_owner_type_description_here"
```

**Expected Results:**
- ✅ Drawer displays without overflow
- ✅ Text wraps properly
- ✅ UI remains intact

### Test 20: Many Roles (10+)

**Data:**
```dart
roles: ["role1", "role2", ..., "role10"]
```

**Expected Results:**
- ✅ RoleSelectionScreen scrolls
- ✅ All roles selectable
- ✅ No performance degradation

### Test 21: Rapid Role Switches

**Steps:**
1. Switch roles quickly (5-10 times)
2. Observe state

**Expected Results:**
- ✅ Each switch completes
- ✅ Final state is correct
- ✅ No state corruption

---

## Device Tests

### Test 22: Portrait/Landscape Rotation

**Steps:**
1. Rotate device
2. Observe screen reconstruction
3. Check role state

**Expected Results:**
- ✅ Layout adapts correctly
- ✅ Role state preserved
- ✅ No crashes

### Test 23: Screen Size Variations

**Test on:**
- Small phone (5" screen)
- Large phone (7" screen)
- Tablet (10" screen)

**Expected Results:**
- ✅ Responsive layout
- ✅ All buttons accessible
- ✅ Text readable

### Test 24: Accessibility

**Steps:**
1. Enable screen reader
2. Navigate drawers/buttons
3. Test with gestures

**Expected Results:**
- ✅ All buttons have labels
- ✅ Screen reader works
- ✅ Proper contrast ratios

---

## Test Summary Template

```
Test Date: _______________
Tester: ___________________
Device: ___________________
OS Version: _______________
App Version: ______________

Test Case | Status | Notes
-----------|--------|-------
1. Single Role Login | ✅/❌ |
2. Multi-Role Login | ✅/❌ |
3. Role Switching | ✅/❌ |
4. Add Vehicle | ✅/❌ |
5. Logout | ✅/❌ |
6. Back Arrow | ✅/❌ |
7. No Roles | ✅/❌ |
8. Enroll Another | ✅/❌ |
9. Settings | ✅/❌ |
10. Concurrent Switch | ✅/❌ |

Overall Status: PASS / FAIL / PARTIAL
Issues Found: _______________
```

---

## Regression Test Checklist

After any code changes, verify:

- [ ] Single role user still goes to dashboard
- [ ] Multi-role user still sees role selection
- [ ] Role switch still updates Firestore
- [ ] Drawer still shows all roles
- [ ] Logout still works
- [ ] Back arrow still works
- [ ] Add vehicle still saves to Firestore
- [ ] No new console errors
- [ ] No new navigation crashes

---

**Test Status**: Ready for Full QA  
**Version**: 1.0.0  
**Last Updated**: February 11, 2026
