# Pending Approval Flow - Quick Test Guide

## Test Scenario 1: Complete Onboarding → Pending Approval

### Steps:
1. Create new test account (email: test@example.com)
2. Complete Screen 1 (basic info)
   - Name, phone, farm name, city, property type
3. Complete Screen 2 (property details)
   - Wait for green success screen
   - Click continue
4. Complete Screen 3 (add properties)
   - Add at least one property
   - Click submit
5. Verify pending approval screen shows:
   - ✅ Owner name displayed
   - ✅ "Submitted on: [date]" shown
   - ✅ Timeline with 3 steps
   - ✅ "Go to Home" button visible

### Firestore Check:
```
owners/{uid}:
- onboarding_status: "completed"
- onboarding_completed: true
- owner_status: "pending"
- verification_status: "pending_verification"
- onboarding_submitted_at: [timestamp]
```

### App Restart Test:
1. Complete the flow above
2. Kill the app (clear from recent)
3. Reopen app with same account
4. **Should see**: Pending approval screen (NOT Screen 1)

---

## Test Scenario 2: Owner Rejection

### Setup:
1. Complete Scenario 1 first
2. In Firestore, manually update:
   ```
   verification_status: "rejected"
   owner_status: "rejected"
   ```
3. Restart app with same account

### Expected Result:
- ✅ Rejection screen appears
- ✅ Shows "Application Not Approved"
- ✅ "Contact Support" action available
- ✅ "Reapply Later" option shown
- ✅ Support email displayed

---

## Test Scenario 3: Owner Approval

### Setup:
1. Complete Scenario 1 first
2. In Firestore, manually update:
   ```
   verification_status: "verified"
   owner_status: "approved"
   ```
3. Restart app with same account

### Expected Result:
- ✅ Redirects to role selection screen (NOT dashboard)
- ✅ Can choose "Farmhouse Owner" or "Co-Owner"
- ✅ After role selection → appropriate dashboard loads

---

## Bug Detection Tests

### Test: Onboarding Re-entry Bug ❌
**Should FAIL after fix**
1. Complete onboarding → see pending approval
2. Restart app
3. **Should see**: Pending approval screen
4. **Should NOT see**: Onboarding Screen 1

### Test: Dashboard Access Before Approval ❌
**Should FAIL after fix**
1. Complete onboarding → see pending approval
2. Try to manually navigate to `/farmhouse_dashboard`
3. **Should see**: Pending approval screen (redirected)
4. **Should NOT see**: Dashboard

### Test: Status Persistence ✅
**Should PASS after fix**
1. Complete onboarding with status: `pending_verification`
2. Kill app
3. Restart app
4. **Status should persist**: Still shows pending approval
5. **Retry 3 times**: Same behavior each time

---

## Debug Checklist

If tests fail, check:

1. **Firestore Field Check**
   - [ ] `onboarding_status` = "completed"
   - [ ] `verification_status` = correct value
   - [ ] `onboarding_completed` = true
   - [ ] `owner_status` = correct value

2. **Router Logic Check**
   - [ ] Open `owner_dashboard_router.dart`
   - [ ] Verify imports include new screens
   - [ ] Check `_routeByOnboardingStatus()` method
   - [ ] Verify pending check comes BEFORE role check

3. **Screen 3 Submission Check**
   - [ ] Open `owner_onboarding_screen_3.dart`
   - [ ] Look at `_completeOnboarding()` method (line 85-120)
   - [ ] Verify all 6 fields are being set

4. **App State Check**
   - [ ] Hot reload should NOT restart onboarding
   - [ ] App restart should NOT restart onboarding
   - [ ] Logout/login with same account should show pending approval

---

## Success Indicators

✅ All tests pass = **Pending Approval Flow is WORKING**

Key success markers:
1. After submission → pending approval screen shows
2. After restart → pending approval screen shows (NOT screen 1)
3. No infinite loops or navigation bugs
4. Rejection/approval flows work correctly
5. Status fields persist in Firestore

**Expected Result**: 🟢 Production-Ready
