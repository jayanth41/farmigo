# Car Rental Booking System - Complete Implementation Guide

## 🎯 Overview

This guide covers the complete implementation of the car rental booking system with the following features:

1. **Blocked Dates Management** - Owners define unavailable dates, users cannot select them
2. **Visual Calendar** - 60-day calendar with color-coded dates
3. **Invoice Screen** - Price breakdown with detailed booking summary
4. **FCM Notifications** - Real-time owner notifications for new bookings
5. **Owner Dashboard** - Recent bookings display with notifications bell

---

## 📁 Files Created

### 1. **lib/models/car_booking.dart**
Comprehensive data model for car bookings.

**Key Fields:**
- `carId` - Reference to property in Firestore
- `startDate` / `endDate` - Booking period
- `hours` - For same-day hourly bookings
- `pricePerDay`, `weekendPrice`, `hourlyPrice` - Pricing data
- `driverHourlyCharge` - Driver cost
- `driverRequested` - Boolean flag
- `weekdayTotal`, `weekendTotal`, `hourlyTotal`, `driverTotal` - Price breakdown
- `finalTotal` - Complete amount
- `guestFcmToken` - For push notifications

**Methods:**
```dart
CarBooking.fromFirestore()      // Create from Firestore doc
toFirestore()                    // Convert to Firestore format
isSameDayBooking                 // Check if single day
numberOfDays                     // Get booking length
```

---

### 2. **lib/services/car_booking_service.dart**
Business logic for booking operations.

**Key Methods:**

#### `calculatePricing()`
Calculates price breakdown based on:
- Booking dates (weekday vs weekend)
- Hourly rate (for same-day bookings)
- Driver charges (optional)

Returns:
```dart
{
  'weekdayTotal': int,
  'weekendTotal': int,
  'hourlyTotal': int,
  'driverTotal': int,
  'finalTotal': int,
}
```

#### `createCarBooking()`
Complete booking creation flow:
1. Validates authenticated user
2. Calculates pricing
3. Fetches guest FCM token
4. Saves to Firestore (car_bookings collection)
5. Mirrors in user's subcollection
6. Sends owner notification
7. Stores notification in Firestore

#### `getOwnerCarBookings(ownerId)`
Returns `Stream<List<CarBooking>>` - Real-time bookings for owner.

#### `getUnreadNotificationCount(ownerId)`
Returns `Stream<int>` - Real-time unread count.

#### `getBlockedDates(carId)`
Fetches blocked dates from property document.

---

### 3. **lib/screens/invoice_screen.dart**
Beautiful invoice display before payment.

**Features:**
- Dark header with car name and total
- Booking details (dates, duration, driver)
- Price breakdown (weekday, weekend, hourly, driver)
- Final total in green highlight
- Confirm & Pay button
- Cancel button

**Usage:**
```dart
Navigator.push(context, MaterialPageRoute(
  builder: (context) => InvoiceScreen(
    booking: carBooking,
    onConfirmPay: () {
      // Handle payment (Razorpay integration)
    },
  ),
));
```

---

### 4. **lib/screens/car_rentals_screen.dart** (Updated)
Enhanced with calendar booking widget.

**New Widget: `CarBookingCalendarWidget`**

Features:
- 60-day calendar view
- Color coding:
  - 🔴 Red = Blocked dates (unclickable)
  - 🟢 Green = Available dates
  - 🔵 Blue = Selected range
  - Gray = Past dates (unclickable)
- Fetches blocked dates from Firestore
- Validates date range before selection
- Shows error if blocked date in range: "This car is unavailable for one or more selected dates."

**Usage:**
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => CarBookingCalendarWidget(
    carId: 'car_id_here',
    onBookingComplete: () {
      // Handle booking completion
    },
  ),
);
```

---

### 5. **lib/screens/car_owner_dashboard_new.dart** (Updated)
Comprehensive owner dashboard with multiple tabs.

**Tabs:**
1. **My Vehicles** - Stats cards (earnings, bookings, cars, rentals)
2. **Recent Bookings** - Real-time list from Firestore
3. **Earnings** - Monthly, yearly, and total earnings

**Recent Bookings Card Shows:**
- Car name
- Booking ID
- Status badge (confirmed/pending/cancelled)
- Check-in to check-out dates
- Total price (in green)
- Driver requested badge (if applicable)

**Notification Bell:**
- Shows unread notification count in red badge
- Opens notifications panel showing all notifications
- Notifications marked as read/unread

---

## 🔄 Data Flow

### User Booking Flow

```
1. User opens Car Rentals Screen
   ↓
2. Taps on car card → Opens booking calendar
   ↓
3. Selects date range (system checks for blocked dates)
   ↓
4. System validates date range
   ↓
5. If valid:
   - Creates CarBooking object
   - Navigates to InvoiceScreen
   - Shows price breakdown
   ↓
6. User taps "Confirm & Pay"
   ↓
7. CarBookingService.createCarBooking() executes:
   - Saves to Firestore (car_bookings collection)
   - Mirrors in user's subcollection
   - Creates owner notification
   ↓
8. Owner Dashboard updates in real-time
   - New booking appears in Recent Bookings
   - Notification bell updates
   - Owner can see new booking details
```

---

## 🔐 Firestore Structure

### Collections & Documents

#### **car_bookings** (Main collection)
```json
{
  "carId": "swift_dzire",
  "carName": "Swift Dzire",
  "userId": "guest_uid",
  "ownerId": "owner_uid",
  "startDate": Timestamp,
  "endDate": Timestamp,
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
  "createdAt": Timestamp,
  "guestFcmToken": "fcm_token_here"
}
```

#### **users/{userId}/car_bookings** (User's subcollection)
Mirror of main booking (minimal fields for quick access).

#### **owner_notifications** (New collection)
```json
{
  "ownerId": "owner_uid",
  "propertyId": "car_id",
  "message": "New car booking from 10 Feb 2026 to 12 Feb 2026",
  "bookingId": "booking_id",
  "createdAt": Timestamp,
  "isRead": false,
  "type": "car_booking"
}
```

#### **properties/{carId}** (Existing, Updated)
```json
{
  "blockedDates": [Timestamp, Timestamp, ...],
  "hourlyPrice": 500,
  "weekendPrice": 2500,
  "driverHourlyCharge": 500,
  "minHours": 2,
  "carCategory": "SUV",
  ...
}
```

---

## 🚀 Integration Steps

### Step 1: Add Dependencies
Already present in your pubspec.yaml:
- `cloud_firestore`
- `firebase_auth`
- `firebase_storage`

### Step 2: Replace car_owner_dashboard.dart
```bash
# Backup old file
cp lib/screens/car_owner_dashboard.dart lib/screens/car_owner_dashboard.backup.dart

# Use new implementation
# OR rename new file
mv lib/screens/car_owner_dashboard_new.dart lib/screens/car_owner_dashboard.dart
```

### Step 3: Update Firestore Security Rules
Add permissions for notifications:
```firestore
match /owner_notifications/{document=**} {
  allow read: if request.auth != null && resource.data.ownerId == request.auth.uid;
  allow write: if request.auth != null;
}
```

### Step 4: Update CarRentalCard Widget
Add booking button integration:
```dart
// In CarRentalCard, add:
ElevatedButton(
  onPressed: () => _showBookingCalendar(context, car),
  child: const Text('Book Now'),
)

void _showBookingCalendar(BuildContext context, CarRental car) {
  showModalBottomSheet(
    context: context,
    builder: (context) => CarBookingCalendarWidget(
      carId: car.id,
      onBookingComplete: () {
        // Handle completion
      },
    ),
  );
}
```

### Step 5: Configure FCM Cloud Function
Create a Cloud Function to send FCM notifications:

```javascript
// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendOwnerNotification = functions.firestore
  .document('owner_notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    
    // Get owner's device tokens
    const userDoc = await admin
      .firestore()
      .collection('users')
      .doc(notification.ownerId)
      .get();
    
    const fcmTokens = userDoc.data()?.fcmTokens || [];
    
    if (fcmTokens.length === 0) return;
    
    // Send FCM notification
    return admin.messaging().sendMulticast({
      tokens: fcmTokens,
      notification: {
        title: "New Car Booking 🚗",
        body: notification.message,
      },
      data: {
        bookingId: notification.bookingId,
        type: "car_booking",
      },
    });
  });
```

---

## 🎨 UI/UX Features

### Calendar Widget Colors
- **Red (#FF4444)** - Blocked dates, unclickable
- **Green (#00AA00)** - Available dates
- **Blue (#0066FF)** - Selected range
- **Gray (#CCCCCC)** - Past dates

### Invoice Screen
- Dark header for visual appeal
- Green highlight for final total
- Clear price breakdown with labels
- Professional buttons with proper states

### Owner Dashboard
- Real-time updates via StreamBuilder
- Notification bell with badge counter
- Smooth animations on tab switches
- Empty states for better UX

---

## ✅ Testing Checklist

- [ ] User can view 60-day calendar
- [ ] Blocked dates are red and unclickable
- [ ] User can select date range
- [ ] Error shown if blocked date in range
- [ ] Invoice displays correct pricing
- [ ] Booking saved to Firestore
- [ ] Owner receives notification in real-time
- [ ] Notification bell shows unread count
- [ ] Clicking bell opens notifications panel
- [ ] Notifications are marked as read when viewed
- [ ] Recent Bookings section shows all bookings
- [ ] Each booking card displays correct info
- [ ] Driver badge shows when requested
- [ ] Status badges are color-coded correctly

---

## 🐛 Troubleshooting

### Problem: Blocked dates not showing as blocked
**Solution:**
1. Verify `blockedDates` field exists in Firestore
2. Check date format (should be Timestamp)
3. Ensure Firestore query is fetching correct car ID

### Problem: Notifications not appearing
**Solution:**
1. Verify Cloud Function is deployed
2. Check owner has FCM tokens in user document
3. Verify Firestore security rules allow notification writes
4. Check browser console for errors

### Problem: Date range validation not working
**Solution:**
1. Ensure blocked dates are properly loaded before selection
2. Check DateTime comparison logic in `_isRangeValid()`
3. Verify `_isDateBlocked()` date comparison accounts for timezone

### Problem: Price calculation incorrect
**Solution:**
1. Verify weekday/weekend prices are set in property document
2. Check that weekend detection (Saturday/Sunday) is correct
3. Verify driver charges calculation for multi-day bookings
4. Check if hourly price is being applied correctly

---

## 📚 Related Files Reference

### Existing models updated:
- `lib/models/car_rental.dart` - No changes needed

### New models created:
- `lib/models/car_booking.dart` ✅

### New services created:
- `lib/services/car_booking_service.dart` ✅

### New screens created:
- `lib/screens/invoice_screen.dart` ✅
- `lib/screens/car_owner_dashboard_new.dart` ✅ (rename to car_owner_dashboard.dart)

### Updated screens:
- `lib/screens/car_rentals_screen.dart` ✅ (added CarBookingCalendarWidget)

### Widget updates needed:
- `lib/widgets/car_rental_card.dart` - Add booking button

---

## 🔗 API Reference

### CarBookingService Static Methods

```dart
/// Calculate pricing breakdown
static Map<String, int> calculatePricing({
  required DateTime startDate,
  required DateTime endDate,
  required int pricePerDay,
  int? weekendPrice,
  int? hourlyPrice,
  int? driverHourlyCharge,
  bool driverRequested = false,
  int? hours,
})

/// Create booking and save to Firestore
static Future<CarBooking?> createCarBooking({
  required String carId,
  required String carName,
  required String ownerId,
  required DateTime startDate,
  required DateTime endDate,
  required int pricePerDay,
  int? weekendPrice,
  int? hourlyPrice,
  int? driverHourlyCharge,
  bool driverRequested = false,
  int? hours,
})

/// Get owner's bookings (real-time stream)
static Stream<List<CarBooking>> getOwnerCarBookings(String ownerId)

/// Get unread notification count (real-time)
static Stream<int> getUnreadNotificationCount(String ownerId)

/// Mark notification as read
static Future<void> markNotificationAsRead(String notificationId)

/// Get car details from Firestore
static Future<Map<String, dynamic>?> getCarDetails(String carId)

/// Get blocked dates for car
static Future<List<DateTime>> getBlockedDates(String carId)
```

---

## 🎓 Code Examples

### Example 1: Complete Booking Flow
```dart
// 1. User selects dates in calendar
final result = await showModalBottomSheet(
  context: context,
  builder: (context) => CarBookingCalendarWidget(
    carId: 'swift_dzire',
    onBookingComplete: () {},
  ),
);

if (result != null) {
  final startDate = result['startDate'] as DateTime;
  final endDate = result['endDate'] as DateTime;
  
  // 2. Create booking with pricing
  final pricing = CarBookingService.calculatePricing(
    startDate: startDate,
    endDate: endDate,
    pricePerDay: 2200,
    weekendPrice: 2500,
    driverHourlyCharge: 500,
    driverRequested: true,
  );
  
  // 3. Create CarBooking object
  final booking = CarBooking(
    carId: 'swift_dzire',
    carName: 'Swift Dzire',
    userId: currentUser.uid,
    ownerId: 'owner_uid',
    startDate: startDate,
    endDate: endDate,
    pricePerDay: 2200,
    weekendPrice: 2500,
    driverHourlyCharge: 500,
    driverRequested: true,
    weekdayTotal: pricing['weekdayTotal']!,
    weekendTotal: pricing['weekendTotal']!,
    driverTotal: pricing['driverTotal']!,
    hourlyTotal: 0,
    finalTotal: pricing['finalTotal']!,
    createdAt: DateTime.now(),
  );
  
  // 4. Show invoice
  await Navigator.push(context, MaterialPageRoute(
    builder: (context) => InvoiceScreen(
      booking: booking,
      onConfirmPay: () async {
        // 5. Create booking in Firestore
        final created = await CarBookingService.createCarBooking(
          carId: booking.carId,
          carName: booking.carName,
          ownerId: booking.ownerId,
          startDate: booking.startDate,
          endDate: booking.endDate,
          pricePerDay: booking.pricePerDay,
          weekendPrice: booking.weekendPrice,
          driverHourlyCharge: booking.driverHourlyCharge,
          driverRequested: booking.driverRequested,
        );
        
        if (created != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking confirmed!')),
          );
        }
      },
    ),
  ));
}
```

### Example 2: Display Owner's Bookings
```dart
StreamBuilder<List<CarBooking>>(
  stream: CarBookingService.getOwnerCarBookings(ownerId),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }
    
    final bookings = snapshot.data ?? [];
    
    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return ListTile(
          title: Text(booking.carName),
          subtitle: Text('₹${booking.finalTotal}'),
          trailing: Text(booking.status),
        );
      },
    );
  },
)
```

### Example 3: Show Unread Notifications
```dart
StreamBuilder<int>(
  stream: CarBookingService.getUnreadNotificationCount(ownerId),
  builder: (context, snapshot) {
    final unreadCount = snapshot.data ?? 0;
    
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {},
        ),
        if (unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$unreadCount'),
            ),
          ),
      ],
    );
  },
)
```

---

## 🚀 Next Steps

1. **Deploy Cloud Function** for FCM notifications
2. **Run all tests** from checklist above
3. **Get user feedback** on calendar UI
4. **Implement Razorpay** integration in InvoiceScreen
5. **Monitor Firestore** usage and optimize queries
6. **Set up analytics** for booking tracking

---

## 📞 Support

For questions or issues:
1. Check Firestore security rules
2. Verify collection names and field names
3. Check app logs for error messages
4. Verify Firebase is properly initialized

---

**Last Updated:** February 10, 2026
**Status:** ✅ Implementation Complete
