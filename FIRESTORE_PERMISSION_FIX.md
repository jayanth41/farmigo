# Firestore Permission Fix - Owner Analytics Dashboard

## Problem
The owner analytics screen was failing with error:
```
Error: "the caller does not have permission to execute the specified operation"
```

## Root Cause
The Firestore security rules restricted booking read access to only the booking owner (guest/buyer via `userId` field). Property owners needed to query bookings by `ownerId` field, which was not permitted by the security rules.

## Solution

### Updated Firestore Security Rules
**File**: `/Users/prathyushagartigipati/farmigo/firestore.rules`

**Change**: Updated the bookings collection read permissions:

**Before**:
```firestore
allow read: if request.auth != null && resource.data.userId == request.auth.uid;
```

**After**:
```firestore
allow read: if request.auth != null 
            && (resource.data.userId == request.auth.uid || resource.data.ownerId == request.auth.uid);
```

**Explanation**:
- Guests can read bookings where they are the `userId` (booking owner)
- Property owners can read bookings where they are the `ownerId` (property owner)

---

## How the Analytics Dashboard Works Now

### Permission Flow
1. **Owner visits Analytics screen** → `Firebase.auth.currentUser.uid`
2. **Query executes**: `bookings.where('ownerId', '==', userId).where('status', '==', 'confirmed')`
3. **Firestore evaluates**:
   - Is user authenticated? ✅ (request.auth != null)
   - Is `resource.data.ownerId == request.auth.uid`? ✅ YES → **READ ALLOWED**
4. **Data returned** → StreamBuilder updates UI with real-time data

---

## Data Access Matrix

| User Type | Can Read | Condition |
|-----------|----------|-----------|
| Guest | Their own bookings | `userId == request.auth.uid` |
| Property Owner | Their property bookings | `ownerId == request.auth.uid` |
| Other users | ❌ None | Not matching either condition |

---

## Implementation Details

### Owner Analytics Queries
All four tabs now query with proper permissions:

```dart
FirebaseFirestore.instance
  .collection('bookings')
  .where('ownerId', isEqualTo: userId)           // Filter by property owner
  .where('status', isEqualTo: 'confirmed')       // Filter confirmed bookings only
  .snapshots()                                   // Real-time stream
```

### What Gets Displayed

**Revenue Tab**:
- Total revenue: Sum of owner's confirmed bookings' `totalAmount`
- Total bookings: Count of owner's confirmed bookings
- Monthly trend: Aggregated by `checkIn` date

**Properties Tab**:
- Bookings grouped by `propertyName`
- Bar chart: Bookings count vs Revenue per property
- Tooltips with exact values

**Categories Tab**:
- Pie chart from booking `category` field
- Auto-calculated percentages
- No hardcoded values

**Occupancy Tab**:
- Weekly occupancy from `checkIn` → `checkOut` ranges
- Normalized to 0-100% scale
- Bar chart Mon-Sun breakdown

---

## Testing

✅ **Build Status**: Successful (59.5MB APK)
✅ **Device Test**: App running on 22041216I
✅ **Firestore Queries**: Authenticated properly
✅ **StreamBuilders**: Real-time updates working
✅ **No Permission Errors**: Analytics data loads successfully

---

## Firestore Rules Summary

**Complete bookings collection permissions**:

```firestore
match /bookings/{bookingId} {
  // Create: Guest can only create their own bookings
  allow create: if request.auth != null
                && request.resource.data.userId == request.auth.uid
                && request.resource.data.userId is string;

  // Read: Either the guest (userId) or property owner (ownerId)
  allow read: if request.auth != null 
              && (resource.data.userId == request.auth.uid || resource.data.ownerId == request.auth.uid);

  // Update: Only the booking creator (guest) can update
  allow update: if request.auth != null
                && resource.data.userId == request.auth.uid
                && (request.resource.data.userId == resource.data.userId || !request.resource.data.keys().hasAll(['userId']));

  // Delete: Not allowed for clients
  allow delete: if false;
}
```

---

## Notes for Deployment

1. **These rules are now live** in the Firestore console
2. **No code changes needed** - the app already queries with `ownerId`
3. **Backward compatible** - guests can still read their own bookings
4. **Security preserved** - no user can read bookings they don't own
5. **Real-time updates** - StreamBuilders listen for changes automatically

---

## Troubleshooting

If the analytics still show no data:
1. Verify user is logged in as a property owner
2. Check that bookings have `ownerId` field populated
3. Verify bookings have `status: "confirmed"`
4. Check Firestore console for any remaining permission issues

