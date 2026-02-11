# Car Booking Feature - Quick Reference Guide

## 📋 File Locations

| File | Purpose |
|------|---------|
| `lib/models/car_booking.dart` | Booking data model with Firestore serialization |
| `lib/services/car_booking_service.dart` | All booking business logic |
| `lib/screens/invoice_screen.dart` | Invoice display before payment |
| `lib/screens/car_rentals_screen.dart` | Car listings + calendar booking widget |
| `lib/screens/car_owner_dashboard_new.dart` | Enhanced owner dashboard (rename to car_owner_dashboard.dart) |

## 🎯 Key Classes & Methods

### CarBooking Model
```dart
final String id;              // Firestore doc ID
final String carId;           // Reference to car/property
final String carName;         // Display name
final DateTime startDate;     // Booking start
final DateTime endDate;       // Booking end
final int pricePerDay;        // Base daily rate
final int weekendPrice;       // Saturday/Sunday rate
final int hourlyPrice;        // Same-day hourly rate
final int driverHourlyCharge; // Driver cost per hour/day
final bool driverRequested;   // Driver included
final int finalTotal;         // Total amount

// Methods
bool get isSameDayBooking;    // True if start == end date
int get numberOfDays;         // Days in booking
```

### CarBookingService Methods
```dart
// Calculate pricing breakdown
static Map<String, int> calculatePricing({...})
  → Returns: {weekdayTotal, weekendTotal, hourlyTotal, driverTotal, finalTotal}

// Create booking in Firestore
static Future<CarBooking?> createCarBooking({...})
  → Creates booking, sends notification, returns CarBooking or null

// Get real-time bookings
static Stream<List<CarBooking>> getOwnerCarBookings(ownerId)
  → StreamBuilder compatible

// Get unread notification count
static Stream<int> getUnreadNotificationCount(ownerId)
  → StreamBuilder compatible

// Fetch blocked dates
static Future<List<DateTime>> getBlockedDates(carId)
  → Needed by CarBookingCalendarWidget
```

## 🎨 Widgets

### CarBookingCalendarWidget
**Location:** `lib/screens/car_rentals_screen.dart`

**Props:**
- `carId` (required) - Car to book
- `onBookingComplete` (required) - Callback when dates selected

**Returns:**
- User closes: `null`
- User selects: `{startDate: DateTime, endDate: DateTime}`

**Usage:**
```dart
final result = await showModalBottomSheet(
  context: context,
  builder: (_) => CarBookingCalendarWidget(
    carId: 'swift_dzire',
    onBookingComplete: () {},
  ),
);
```

## 💰 Price Calculation Logic

### Weekday/Weekend Pricing
```
For each day in booking range:
  - If Saturday or Sunday: add weekendPrice
  - Otherwise: add pricePerDay
```

### Same-Day Booking (Hourly)
```
  hourlyTotal = hours * hourlyPrice
```

### Driver Charges
```
  For multi-day: driverTotal = numberOfDays * driverHourlyCharge
  For hourly: driverTotal = hours * driverHourlyCharge
```

### Final Total
```
  finalTotal = weekdayTotal + weekendTotal + hourlyTotal + driverTotal
```

## 🔴 Red Flags / Common Mistakes

❌ **Wrong:** Forgetting to fetch blocked dates before selection
✅ **Right:** Load blocked dates in `initState()` of calendar widget

❌ **Wrong:** Storing guest name in booking (no GuestModel reference)
✅ **Right:** Store userId and fetch guest details separately

❌ **Wrong:** Not storing booking in user's subcollection
✅ **Right:** Use batch write to save in both locations

❌ **Wrong:** Sending FCM notification without checking token
✅ **Right:** Check token exists before sending

❌ **Wrong:** Calculating prices with timezone issues
✅ **Right:** Use UTC dates, compare only year/month/day

## 🧪 Test Data Structure

### Test Booking for Firestore
```json
{
  "carId": "swift_dzire",
  "carName": "Swift Dzire",
  "userId": "guest_uid_here",
  "ownerId": "owner_uid_here",
  "startDate": Timestamp(2026-02-15),
  "endDate": Timestamp(2026-02-17),
  "hours": null,
  "pricePerDay": 2200,
  "weekendPrice": 2500,
  "hourlyPrice": null,
  "driverHourlyCharge": 500,
  "driverRequested": true,
  "weekdayTotal": 4400,
  "weekendTotal": 2500,
  "driverTotal": 1000,
  "hourlyTotal": 0,
  "finalTotal": 7900,
  "status": "confirmed",
  "createdAt": Timestamp(now),
  "guestFcmToken": "token_here"
}
```

### Test Blocked Dates for Property
```json
{
  "blockedDates": [
    Timestamp(2026-02-12),
    Timestamp(2026-02-13),
    Timestamp(2026-02-20),
  ],
  "hourlyPrice": 500,
  "weekendPrice": 2500,
  "driverHourlyCharge": 500,
  ...other car fields
}
```

## 🔐 Firestore Security Rules to Add

```firestore
// Car bookings - Anyone authenticated can read/write their own
match /car_bookings/{document=**} {
  allow read: if request.auth != null && 
    (resource.data.userId == request.auth.uid || 
     resource.data.ownerId == request.auth.uid);
  allow create: if request.auth != null && 
    request.resource.data.userId == request.auth.uid;
  allow update, delete: if request.auth != null && 
    resource.data.ownerId == request.auth.uid;
}

// Owner notifications - Owners can read/write their own
match /owner_notifications/{document=**} {
  allow read: if request.auth != null && 
    resource.data.ownerId == request.auth.uid;
  allow write: if request.auth != null;
}
```

## 📱 Screen Flow

```
HomeScreen
    ↓
CarRentalsScreen (list of cars)
    ↓ [Tap car]
CarRentalCard (car details)
    ↓ [Book Now button]
CarBookingCalendarWidget (select dates)
    ↓ [Select dates]
InvoiceScreen (show price)
    ↓ [Confirm & Pay]
Razorpay (payment)
    ↓ [Success]
CarBookingService.createCarBooking() (save booking)
    ↓
Firestore (car_bookings collection)
    ↓
Owner Dashboard (real-time update)
    ↓
CarOwnerDashboard "Recent Bookings" tab
```

## 🚨 Firebase Cloud Function Template

```javascript
// functions/index.js

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendOwnerBookingNotification = functions.firestore
  .document('car_bookings/{bookingId}')
  .onCreate(async (snap, context) => {
    const booking = snap.data();
    
    // Create notification document
    const notification = {
      ownerId: booking.ownerId,
      propertyId: booking.carId,
      message: `New car booking from ${booking.startDate} to ${booking.endDate}`,
      bookingId: context.params.bookingId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
      type: 'car_booking',
    };
    
    await admin.firestore()
      .collection('owner_notifications')
      .add(notification);
    
    // Try to send FCM (optional)
    try {
      const userDoc = await admin
        .firestore()
        .collection('users')
        .doc(booking.ownerId)
        .get();
      
      const fcmTokens = userDoc.data()?.fcmTokens || [];
      
      if (fcmTokens.length > 0) {
        await admin.messaging().sendMulticast({
          tokens: fcmTokens,
          notification: {
            title: "New Car Booking 🚗",
            body: notification.message,
          },
          data: {
            bookingId: context.params.bookingId,
            type: "car_booking",
          },
        });
      }
    } catch (e) {
      console.error("FCM send failed:", e);
    }
  });
```

## ✅ Integration Checklist

- [ ] Created `lib/models/car_booking.dart`
- [ ] Created `lib/services/car_booking_service.dart`
- [ ] Created `lib/screens/invoice_screen.dart`
- [ ] Updated `lib/screens/car_rentals_screen.dart` with CarBookingCalendarWidget
- [ ] Renamed `lib/screens/car_owner_dashboard_new.dart` to `car_owner_dashboard.dart`
- [ ] Updated Firestore security rules
- [ ] Deployed Cloud Function for notifications (optional but recommended)
- [ ] Added test bookings to Firestore
- [ ] Tested calendar with blocked dates
- [ ] Tested invoice display
- [ ] Tested owner dashboard real-time updates
- [ ] Tested notification badge counter
- [ ] Tested notifications panel

## 🎓 Learning Resources

- Firestore timestamp handling: https://firebase.google.com/docs/firestore/query-data/query-cursors
- Flutter date utilities: https://api.flutter.dev/flutter/dart-core/DateTime-class.html
- Cloud Functions: https://firebase.google.com/docs/functions/get-started
- FCM with Flutter: https://firebase.google.com/docs/cloud-messaging/flutter/client

## 🆘 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| Blocked dates not showing | Ensure Firestore doc exists with blockedDates array |
| Price calculation wrong | Check weekday/weekend detection (weekday != 6,7) |
| Notifications not received | Verify Cloud Function deployed and FCM tokens stored |
| Calendar not loading | Check car ID is correct and Firestore query permissions |
| Invoice showing wrong total | Verify pricing calculation includes all components |

---

**Version:** 1.0
**Status:** Ready for Integration
**Last Updated:** Feb 10, 2026
