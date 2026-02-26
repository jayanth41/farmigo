# Pending Approval Flow - Visual Architecture

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        APP ENTRY POINT                          │
│                      (SplashScreen)                              │
└────────────┬────────────────────────────────────────────────────┘
             │
             ├─ User not authenticated? → LoginScreen
             │
             └─ User authenticated → HomeScreen
                                       │
                                       ↓
                         ┌─────────────────────────┐
                         │  User taps "Owner       │
                         │  Dashboard"             │
                         └──────────┬──────────────┘
                                    ↓
                    ┌───────────────────────────────────┐
                    │  OwnerDashboardRouter (SMART)     │
                    │  Checks ownership status          │
                    └──────────────┬────────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
                    ↓                             ↓
        ┌─────────────────────┐      ┌─────────────────────────┐
        │ User is owner?      │      │ Owned by organization?  │
        │ YES → Continue      │      │ YES → Skip              │
        │ NO  → HomeScreen    │      │ NO  → Normal user       │
        └──────────┬──────────┘      └─────────────────────────┘
                   │
                   ↓
        ┌─────────────────────────────────────────┐
        │  Load onboarding data from Firestore    │
        │  OwnerOnboardingModel.fromFirestore()   │
        └──────────┬────────────────────────────────┘
                   │
       ┌───────────┼───────────────────────────────┐
       │           │                               │
       ↓           ↓                               ↓
   ┌─────────┐ ┌──────────────┐          ┌──────────────────┐
   │ Status: │ │ Status:      │          │ Status:          │
   │ not_    │ │ in_progress  │          │ completed        │
   │started  │ │              │          │                  │
   │         │ │ → Resume     │          └────────┬─────────┘
   │ → Start │ │ from last    │                   │
   │ Screen1 │ │ incomplete   │      ┌────────────┼─────────────────┐
   │         │ │ screen       │      │            │                 │
   └─────────┘ │              │      ↓            ↓                 ↓
               │              │   ┌─────────┐  ┌─────────┐    ┌──────────┐
               │              │   │ Pending │  │Rejected │    │Verified  │
               │              │   │ Approval│  │Account  │    │Account   │
               │              │   │         │  │         │    │          │
               │              │   │ → Show  │  │ → Show  │    │ → Check  │
               │              │   │ Pending │  │Rejection│    │Role      │
               │              │   │Approval │  │ Screen  │    │          │
               │              │   │ Screen  │  │         │    └────┬─────┘
               │              │   │         │  │         │         │
               │              │   └─────────┘  └─────────┘    ┌────┴──────┐
               │              │                               │           │
               └──────────────┘                    ┌──────────┴────┐  ┌───┴────────┐
                                                   │ Active Role   │  │ No Role    │
                                                   │ Selected?     │  │ → Role     │
                                                   │               │  │ Selection  │
                                                   │ YES → Use it  │  │ Screen     │
                                                   │ NO → Wait     │  └────┬───────┘
                                                   └───────┬───────┘       │
                                                           │               │
                                            ┌──────────────┼───────────────┘
                                            │              │
                                            ↓              ↓
                                    ┌──────────────┐  ┌────────────────┐
                                    │ Role:        │  │ User selected  │
                                    │ farmhouse    │  │ a role         │
                                    │              │  │                │
                                    │ → Farmhouse  │  │ Save selection │
                                    │ Dashboard    │  │                │
                                    │              │  │ → Dashboard    │
                                    └──────────────┘  └────────────────┘
```

---

## 📊 State Machine: Owner Status

```
                    ┌─────────────────────────────────────┐
                    │  START: Not an Owner                │
                    │  onboarding_status: null            │
                    │  verification_status: null          │
                    └────────────┬────────────────────────┘
                                 │
                    User: "I want to be an owner"
                                 │
                                 ↓
                    ┌─────────────────────────────────────┐
                    │ ONBOARDING_NOT_STARTED              │
                    │ onboarding_status: "not_started"    │
                    │ verification_status: null           │
                    │ → Show Screen 1                     │
                    └────────────┬────────────────────────┘
                                 │
                    User fills: basic info
                                 │
                                 ↓
                    ┌─────────────────────────────────────┐
                    │ ONBOARDING_IN_PROGRESS              │
                    │ onboarding_status: "in_progress"    │
                    │ completed_screens: ["screen_1"]     │
                    │ → Show Screen 2                     │
                    └────────────┬────────────────────────┘
                                 │
                    User fills: property details
                                 │
                                 ↓
                    ┌─────────────────────────────────────┐
                    │ ONBOARDING_IN_PROGRESS              │
                    │ onboarding_status: "in_progress"    │
                    │ completed_screens: ["screen_1", "2"]│
                    │ → Show Screen 3                     │
                    └────────────┬────────────────────────┘
                                 │
                    User adds: properties
                                 │
                                 ↓
                    ┌─────────────────────────────────────┐
                    │ SUBMITTED - PENDING VERIFICATION    │ ⭐ KEY STATE
                    │ onboarding_status: "completed"      │
                    │ owner_status: "pending"             │
                    │ verification_status:                │
                    │   "pending_verification"            │
                    │ → Show PendingApprovalScreen        │
                    │ → Block Dashboard Access            │
                    └────────┬────────────────────────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
         Developer     Developer      Developer
         (APPROVED)    (REJECTED)     (NEEDS INFO)
              │              │              │
              ↓              ↓              ↓
    ┌──────────────┐ ┌────────────────┐ ┌──────────────────┐
    │ APPROVED     │ │ REJECTED       │ │ NEEDS_REVISION   │
    │ verification │ │ verification   │ │ verification     │
    │ _status:     │ │ _status:       │ │ _status:         │
    │ "verified"   │ │ "rejected"     │ │ "pending_fix"    │
    │ owner_status:│ │ owner_status:  │ │ owner_status:    │
    │ "approved"   │ │ "rejected"     │ │ "needs_revision" │
    │              │ │                │ │                  │
    │ → Role       │ │ → Rejection    │ │ → Revision       │
    │   Selection  │ │   Screen       │ │   Screen         │
    │              │ │                │ │ (resubmit)       │
    └──────────────┘ │                │ └──────────────────┘
                     │                │
                     └────────┬───────┘
                              │
                    User contact support
                    or reapply later
                              │
                              ↓
                    ┌──────────────────────┐
                    │ RETURNED TO START    │
                    │ (reapply)            │
                    └──────────────────────┘
    
    HAPPY PATH: not_started → in_progress → pending_verification → verified → approved
    SAD PATH:   not_started → in_progress → pending_verification → rejected
```

---

## 🔄 Data Flow: Firestore Updates

```
BEFORE SUBMISSION (In Progress):
┌─────────────────────────────────┐
│ owners/{uid}                     │
├─────────────────────────────────┤
│ onboarding_status: "in_progress"│
│ completed_screens: ["screen_1"] │
│ basic_info: {...}               │
│ property_details: null          │
│ updatedAt: 2025-01-20T10:00Z    │
└─────────────────────────────────┘

                    ↓↓↓ User clicks SUBMIT on Screen 3 ↓↓↓

AFTER SUBMISSION (Pending Approval):
┌──────────────────────────────────────┐
│ owners/{uid}                         │
├──────────────────────────────────────┤
│ onboarding_status: "completed"       │  ← PERMANENT
│ onboarding_completed: true           │  ← ONE-TIME FLAG
│ owner_status: "pending"              │
│ verification_status: "pending_        │  ← Router uses this
│   verification"                      │
│ completed_screens: ["screen_1",      │
│                    "screen_2",       │
│                    "screen_3"]       │
│ basic_info: {...}                    │
│ property_details: {...}              │
│ properties: [...addedProperties...]  │
│ onboarding_submitted_at: 2025-01-20  │
│   T10:30:00Z                         │
│ updatedAt: 2025-01-20T10:30:00Z      │
└──────────────────────────────────────┘

                    ↓↓↓ Developer approves in admin ↓↓↓

AFTER APPROVAL (Access Granted):
┌──────────────────────────────────────┐
│ owners/{uid}                         │
├──────────────────────────────────────┤
│ onboarding_status: "completed"       │
│ onboarding_completed: true           │
│ owner_status: "approved"             │
│ verification_status: "verified"      │  ← Router shows dashboard
│ verified_at: 2025-01-20T11:00:00Z    │
│ updatedAt: 2025-01-20T11:00:00Z      │
└──────────────────────────────────────┘

                    ↓↓↓ Developer rejects in admin ↓↓↓

AFTER REJECTION (Access Denied):
┌──────────────────────────────────────┐
│ owners/{uid}                         │
├──────────────────────────────────────┤
│ onboarding_status: "completed"       │
│ onboarding_completed: true           │
│ owner_status: "rejected"             │
│ verification_status: "rejected"      │  ← Router shows rejection
│ rejection_reason: "..."              │
│ rejected_at: 2025-01-20T11:00:00Z    │
│ updatedAt: 2025-01-20T11:00:00Z      │
└──────────────────────────────────────┘
```

---

## 🛡️ Safety Checks: Preventing Loops

```
PROTECTION 1: Onboarding Status
┌────────────────────────────────────────────┐
│ Router receives request to show app        │
├────────────────────────────────────────────┤
│ Check: onboarding_status == "not_started"? │
│        → YES  → Show Screen 1              │
│        → NO   → Continue checking...       │
│                                            │
│ Check: onboarding_status == "in_progress"?│
│        → YES  → Resume from screen        │
│        → NO   → Continue checking...       │
│                                            │
│ Check: onboarding_status == "completed"?  │
│        → YES  → Check verification status │
│        → NO   → Block access              │
└────────────────────────────────────────────┘
                     ↓
          RESULT: Can't restart screens
          because status is "completed"


PROTECTION 2: Verification Status
┌────────────────────────────────────────────┐
│ onboarding_status == "completed"? YES      │
├────────────────────────────────────────────┤
│ Check: verification_status == "pending"?   │
│        → YES  → Show pending approval      │
│        → NO   → Continue checking...       │
│                                            │
│ Check: verification_status == "rejected"?  │
│        → YES  → Show rejection screen      │
│        → NO   → Continue checking...       │
│                                            │
│ Check: verification_status == "verified"?  │
│        → YES  → Show role selection        │
│        → NO   → Block access               │
└────────────────────────────────────────────┘
                     ↓
          RESULT: Dashboard blocked
          until verification_status is "verified"


PROTECTION 3: One-Time Flag
┌────────────────────────────────────────────┐
│ Screen 3 submission logic:                 │
├────────────────────────────────────────────┤
│ Set: onboarding_completed = true           │
│                                            │
│ This flag ensures:                         │
│ - User can't run onboarding twice          │
│ - Analytics track first-time completion    │
│ - Admin can verify completion status       │
└────────────────────────────────────────────┘
                     ↓
          RESULT: Data integrity maintained
          across all app sessions
```

---

## 📱 UI Flow: User Perspective

```
SCREEN SEQUENCE:

Screen 1: Enter Basics
┌─────────────────────┐
│ Name, Phone,        │
│ Farm Name,          │
│ City, Property Type │
│                     │
│ [CONTINUE]          │
└─────────────────────┘
         ↓
Screen 2: Property Details
┌─────────────────────┐
│ Property size,      │
│ Amenities,          │
│ Pricing             │
│ [SUBMIT]            │
└─────────────────────┘
         ↓
  GREEN SUCCESS SCREEN
┌─────────────────────┐
│ ✅ Success!         │
│ Property saved      │
│ [CONTINUE]          │
└─────────────────────┘
         ↓
Screen 3: Add More Properties
┌─────────────────────┐
│ List of properties  │
│ [Add Property]      │
│ [SUBMIT]            │
└─────────────────────┘
         ↓
  GREEN SUCCESS SCREEN
┌─────────────────────┐
│ ✅ Success!         │
│ Properties added    │
│ Account pending     │
│ [CONTINUE]          │
└─────────────────────┘
         ↓
PENDING APPROVAL SCREEN  ⭐ NEW
┌──────────────────────────┐
│ ⏳ Verification Progress │
│                          │
│ Timeline:                │
│ ✓ Submitted              │
│ ⏳ Under Review           │
│ ⃝ Approved               │
│                          │
│ Submitted: Jan 20, 2025  │
│ [GO TO HOME]             │
└──────────────────────────┘
         ↓
HOME SCREEN (Not Dashboard!)
┌─────────────────────┐
│ Browse farmhouses   │
│ Make bookings       │
│ [Owner Dashboard]   │
└─────────────────────┘
         ↓
IF OWNER TAPS
"Owner Dashboard"
         ↓
Router checks approval status
         ↓
If not verified:
  Show Pending Approval (again)
If verified:
  Show Role Selection
If rejected:
  Show Rejection Screen
```

---

## 📈 Timeline: Verification Process

```
Timeline on Pending Approval Screen:

Day 0 - User Submits:
  ▪ 10:30 AM - User submits application
  ▪ Firestore timestamp saved
  ▪ Screen shows "Submitted"

Days 1-3 - Under Review:
  ▪ Admin logs in
  ▪ Reviews documents
  ▪ Verifies information
  ▪ Screen shows "Under Review"

Day 4 - Approved:
  ▪ Admin clicks "Approve"
  ▪ Firestore updated: verified_status = "verified"
  ▪ User receives email notification
  ▪ Screen shows "Approved"
  ▪ Next login shows Role Selection

Optional - Rejected:
  ▪ Admin clicks "Reject"
  ▪ Rejection reason added
  ▪ User receives email
  ▪ User sees Rejection Screen on next login
  ▪ Can contact support or reapply
```

---

**Diagram Status**: ✅ Complete & Accurate
**Last Updated**: 2025-01-20
**Version**: 1.0
