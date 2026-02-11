# Test Booking Guide - Verify End-to-End Flow

## Current Status ✅

The **Manage Bookings screen is fully integrated with Firestore** and showing real data:
- **Total Bookings**: 6
- **Pending**: 2
- **Confirmed**: 2
- **Completed**: 1
- **Cancelled**: ?

## How the System Works

```
Guest Books Property (via Property Details Screen)
    ↓
Payment processed via Razorpay
    ↓
BookingService.createBooking() called
    ↓
New document created in Firestore 'bookings' collection with:
  - userId: guest's UID
  - ownerId: property owner's UID (Ggu1NNapYcNnfZWK7ScJZLtKtrK2)
  - status: 'confirmed' (after payment)
  - createdAt: current timestamp
    ↓
Owner Dashboard StreamBuilder listens for changes
    ↓
Booking appears in real-time with:
  - Count updates (All, Pending, Confirmed, etc.)
  - Status badge
  - Guest details
  - Confirm/Decline buttons (if pending)
```

## Test Booking Structure

To verify the end-to-end flow works, create test bookings in Firestore with this structure:

```json
{
  "userId": "test-guest-uid",
  "ownerId": "Ggu1NNapYcNnfZWK7ScJZLtKtrK2",
  "propertyName": "Sunny Meadows Farm",
  "propertyType": "Farmhouse",
  "guestName": "Jane Smith",
  "guestEmail": "jane@example.com",
  "guestPhone": "9876543210",
  "startDate": Timestamp(2026, 2, 20),
  "endDate": Timestamp(2026, 2, 25),
  "dateRange": "Feb 20 - Feb 25, 2026",
  "nightsGuests": "5 nights • 2 guests",
  "total": "₹18,000",
  "status": "pending",
  "createdAt": Timestamp.serverTimestamp()
}
```

## Steps to Create Test Booking

### Option 1: Firebase Console (Recommended)

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com/project/farmigo-704ca/firestore

2. **Navigate to Bookings Collection**
   - Click on "Firestore Database"
   - Find "bookings" collection
   - Click "+ Add document"

3. **Fill in the Fields**
   - Click "Auto ID" for document ID (or enter custom ID)
   - Add these fields:
     ```
     Field Name        | Type      | Value
     userId            | String    | test-guest-123
     ownerId           | String    | Ggu1NNapYcNnfZWK7ScJZLtKtrK2
     propertyName      | String    | Sunny Meadows Farm
     propertyType      | String    | Farmhouse
     guestName         | String    | Jane Smith
     guestEmail        | String    | jane@example.com
     guestPhone        | String    | 9876543210
     status            | String    | pending
     total             | String    | ₹18,000
     dateRange         | String    | Feb 20 - Feb 25, 2026
     nightsGuests      | String    | 5 nights • 2 guests
     startDate         | Timestamp | 2026-02-20
     endDate           | Timestamp | 2026-02-25
     createdAt         | Timestamp | Server timestamp
     ```

4. **Click "Save"**

5. **Hot Reload the App**
   - Press `r` in the Flutter terminal
   - Navigate to Owner Dashboard → Bookings
   - Your new booking should appear! 🎉

### Option 2: Using Firestore Emulator (For Local Testing)

```bash
# Start Firebase Emulator
firebase emulators:start

# Then create bookings locally and test
```

## Expected Behavior

After creating a test booking with `status: "pending"`:

✅ **On Owner Dashboard → Bookings:**
- Stat cards update:
  - All: 7
  - Pending: 3
  - Confirmed: 2
  - Completed: 1
- New booking appears in the "Pending" tab
- Booking card shows:
  - Property name
  - Guest details (name, email, phone)
  - Dates (Feb 20 - 25)
  - Total (₹18,000)
  - Status badge (Pending)
  - Two action buttons: "Confirm" and "Decline"

## Test Different Status Types

Create multiple test bookings with different statuses to verify filtering:

| Status | Expected Tab | Action | Owner Can Do |
|--------|-------------|--------|-------------|
| pending | Pending | Accept/Decline | Confirm or Decline |
| confirmed | Confirmed | - | View only |
| completed | Completed | - | View only |
| cancelled | Cancelled | - | View only |

### Example Test Bookings

**Test 1: Pending Booking (New)**
```json
{
  "status": "pending",
  "guestName": "New Guest",
  "total": "₹12,000"
}
```

**Test 2: Confirmed Booking**
```json
{
  "status": "confirmed",
  "guestName": "Confirmed Guest",
  "total": "₹15,000"
}
```

**Test 3: Completed Booking**
```json
{
  "status": "completed",
  "guestName": "Completed Guest",
  "total": "₹10,000"
}
```

## Firestore Query Being Used

```dart
// From manage_bookings.dart
stream: FirebaseFirestore.instance
    .collection('bookings')
    .where('ownerId', isEqualTo: 'Ggu1NNapYcNnfZWK7ScJZLtKtrK2')
    .orderBy('createdAt', descending: true)
    .snapshots(),
```

**Important**: The query filters by `ownerId`, so test bookings MUST have:
```
ownerId: "Ggu1NNapYcNnfZWK7ScJZLtKtrK2"
```

## Confirming/Declining Bookings

When you tap "Confirm" on a pending booking:
1. Status updates to `confirmed` in Firestore
2. Guest receives notification (if FCM token exists)
3. Booking moves from "Pending" to "Confirmed" tab
4. Stat cards update automatically

## Troubleshooting

### Booking Not Appearing?

✅ **Check ownerId**
- Make sure `ownerId` = `Ggu1NNapYcNnfZWK7ScJZLtKtrK2`
- This is the currently logged-in owner's UID

✅ **Check createdAt**
- Should be a Timestamp field
- Click "Server timestamp" when creating

✅ **Hot Reload**
- Press `r` in Flutter terminal
- StreamBuilder will fetch latest data

✅ **Firestore Rules**
- Verify you're logged in as the owner
- Check security rules allow read access

### Error Messages?

If you see "Error loading bookings: Permission denied":
- Check Firestore security rules
- Verify you're logged in (check user UID matches)
- Ensure composite index is built (check Firebase Console)

## Next Steps

After verifying test bookings work:

1. ✅ Test the Confirm button (status changes to confirmed)
2. ✅ Test the Decline button (status changes to cancelled)
3. ✅ Verify notifications are sent
4. ✅ Test search and filter functionality
5. ✅ Check export to CSV works

## Real Booking Flow

Once everything is working, real bookings will be created when:

1. Guest browses properties (HomeScreen)
2. Selects a property (FarmhouseDetailsScreen)
3. Chooses dates and confirms booking
4. Completes payment with Razorpay
5. BookingService.createBooking() saves to Firestore
6. Booking appears in Owner Dashboard immediately! 🎉

---

**Questions?** Check the manage_bookings.dart file or Firestore security rules for details.
