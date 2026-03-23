# PropertyDetailsScreen Loading Fix Guide

The screen is stuck on loading? Here's how to fix it:

## ✅ What Changed

1. **Error Handling Added** - Shows error message instead of infinite loading
2. **Better Logging** - Prints exact property ID being searched
3. **Retry Button** - Allows retrying failed loads
4. **Test Data Helper** - Quickly populate Firestore with sample data
5. **Parallel Image Upload** - Faster image uploads for reviews
6. **Resource Cleanup** - Properly disposes TextEditingControllers

---

## 🔧 Step-by-Step Fix

### Step 1: Check What Error Message Shows

Run the app and look at the error message on screen:

```
❌ Property not found. Please check the property ID.
  → Issue: propertyId value is invalid or missing

❌ Error loading property: ...
  → Issue: Firebase connection or Firestore rules problem

⏳ Still loading spinning...
  → Issue: Old code - run `flutter clean && flutter pub get`
```

### Step 2: Create Test Data in Firestore

**Option A: Using Test Data Helper (Easiest)**

Add this to any screen or main.dart temporarily:

```dart
import 'package:skybase/utils/test_data_helper.dart';

// In any async function:
final propertyIds = await TestDataHelper.createMultipleTestProperties();
print('Created properties: $propertyIds');
```

Then copy the first ID and pass it to PropertyDetailsScreen.

**Option B: Using Firebase Console**

1. Go to: https://console.firebase.google.com/u/0/project/farmigo-704ca/firestore
2. Create collection: `properties`
3. Add a document with this structure:

```json
{
  "name": "Test Farmhouse",
  "city": "Lonavala",
  "state": "Maharashtra",
  "description": "Beautiful farmhouse with amenities",
  "category": "Farmhouse",
  "pricePerNight": 5000,
  "averageRating": 4.5,
  "reviewCount": 12,
  "imageUrls": [
    "https://images.unsplash.com/photo-1570129477492-45a003cc3600?w=500"
  ],
  "highlights": ["WiFi", "Pool", "Garden"],
  "amenities": ["WiFi", "AC", "Kitchen"],
  "latitude": 18.7515,
  "longitude": 73.4008,
  "userId": "owner123",
  "ownerDetails": {
    "name": "John Doe",
    "image": "https://ui-avatars.com/api/?name=John",
    "contact": "+91-9876543210",
    "isVerified": true
  },
  "timings": {
    "checkInTime": "2:00 PM",
    "checkOutTime": "11:00 AM"
  },
  "policies": {
    "checkInPolicy": "From 2 PM",
    "checkOutPolicy": "Before 11 AM",
    "cancellationPolicy": "Free cancellation",
    "houseRules": "No smoking"
  },
  "nearbyAttractions": [
    {
      "name": "Tiger Point",
      "distance": 2.5,
      "imageUrl": "https://images.unsplash.com/..."
    }
  ],
  "isActive": true,
  "createdAt": <TIMESTAMP>
}
```

4. Note the Document ID (displayed at top)
5. Use this ID when navigating to PropertyDetailsScreen

### Step 3: Verify Navigation is Passing propertyId

In the file calling PropertyDetailsScreen, check:

```dart
// ❌ WRONG - No propertyId passed
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => PropertyDetailsScreen()),
);

// ✅ CORRECT - propertyId required
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => PropertyDetailsScreen(
      propertyId: 'YOUR_PROPERTY_ID_HERE',  // ← Use actual ID from step 2
      currentUserId: FirebaseAuth.instance.currentUser?.uid,
    ),
  ),
);
```

### Step 4: Check Firebase Firestore Rules

Go to: https://console.firebase.google.com/u/0/project/farmigo-704ca/firestore/rules

Must include:

```bash
allow read: if request.auth != null;  // Allow authenticated users to read
allow write: if request.auth.uid == resource.data.userId;  // Only owner can write
```

### Step 5: Verify Firebase Connection

In main.dart or initState, add:

```dart
// Test Firebase connection
try {
  final props = await FirebaseFirestore.instance
      .collection('properties')
      .limit(1)
      .get();
  print('✅ Firebase connected. Found ${props.docs.length} properties');
} catch (e) {
  print('❌ Firebase error: $e');
}
```

---

## 🐛 Debugging Checklist

- [ ] **propertyId is passed to PropertyDetailsScreen**
  - Check: Print widget.propertyId in initState
  
- [ ] **Test property exists in Firestore**
  - Check: Go to Firebase Console → Firestore → properties collection
  
- [ ] **Firestore rules allow reading**
  - Check: Go to Firebase Console → Firestore → Rules
  
- [ ] **User is authenticated** (if required by rules)
  - Check: FirebaseAuth.instance.currentUser is not null
  
- [ ] **Document ID matches exactly**
  - Check: Case-sensitive, no extra spaces
  
- [ ] **Latest code deployed**
  - Run: `flutter clean && flutter pub get && flutter run`

---

## 📊 Success Indicators

✅ You should see:
- [ ] Property name displays
- [ ] Images load (or default icon)
- [ ] Rating and review count show
- [ ] All 15 sections visible
- [ ] Chat button responds
- [ ] Share button works
- [ ] Book Now button works

---

## 🆘 If Still Not Working

### Check Logs

```bash
# Clear everything
flutter clean
flutter pub get

# Run with logs
flutter run -v

# Look for error messages starting with "❌" or "Error"
```

### Debug Property Loading

Add to PropertyDetailsScreen:

```dart
@override
void initState() {
  super.initState();
  print('🔍 PropertyDetailsScreen initialized');
  print('   propertyId: ${widget.propertyId}');
  print('   currentUserId: ${widget.currentUserId}');
  _loadProperty();
}
```

### Check Firestore Directly

```dart
// In Flutter app, temporarily add:
FirebaseFirestore.instance
    .collection('properties')
    .doc(widget.propertyId)
    .get()
    .then((doc) {
  print('Document exists: ${doc.exists}');
  print('Data: ${doc.data()}');
});
```

---

## 📝 Code Changes Summary

**PropertyDetailsScreen now includes:**

| Feature | Before | After |
|---------|--------|-------|
| Error Handling | ❌ None | ✅ Shows error message |
| Retry Logic | ❌ No | ✅ Retry button |
| Image Upload | ⏳ Sequential | ⚡ Parallel (faster) |
| Memory Leaks | ⚠️ TextController not disposed | ✅ Properly disposed |
| Similar Properties Tap | Empty handler | Opens selected property |
| Navigation | Similar properties section doesn't navigate | Now navigates properly |

---

## 🎯 Quick Test (< 2 minutes)

1. **Create test data:**
   ```dart
   await TestDataHelper.(
     propertyName: 'Quick Test Farmhouse',
   );
   ```

2. **Copy the returned property ID**

3. **Pass it to PropertyDetailsScreen:**
   ```dart
   PropertyDetailsScreen(propertyId: 'PASTE_ID_HERE')
   ```

4. **Run and verify it loads** ✅

---

## 📞 Support

- **Firebase Console:** https://console.firebase.google.com/u/0/project/farmigo-704ca
- **Firestore Docs:** https://firebase.flutter.dev/docs/firestore
- **Test Data Helper Location:** `lib/utils/test_data_helper.dart`

