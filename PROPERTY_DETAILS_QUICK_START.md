# ⚡ QUICK START - PropertyDetailsScreen (5 Minutes)

## 🎯 What You Have
✅ PropertyDetailsScreen - FULLY IMPLEMENTED & ERROR-FREE
✅ All 4 services (Property, FAQ, Review, Chat)
✅ All Firestore rules
✅ Firebase integration complete

## 🔴 What You NEED (3 Steps to Go Live)

### Step 1: Get Google Maps API Key (3 minutes)

**1. Go to:** https://console.cloud.google.com
**2. Project:** farmigo-704ca (select it at top)
**3. Search box:** Type "Maps SDK for Android"
**4. Click:** Enable Maps SDK for Android
**5. Search again:** Type "Maps SDK for iOS"  
**6. Click:** Enable Maps SDK for iOS
**7. Left menu:** Credentials
**8. Blue button:** Create Credentials → API Key
**9. Copy:** Your new API Key (looks like: `AIzaSyD_...`)

### Step 2: Add API Key to Android (1 minute)

**File:** `android/app/src/main/AndroidManifest.xml`

**Find this line (around line 37):**
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE" />
```

**Replace with (use your actual key):**
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyD_PUT_YOUR_KEY_HERE" />
```

### Step 3: Add API Key to iOS (1 minute)

**File:** `ios/Runner/Info.plist`

**Add these 4 lines inside the root `<dict>` (before `</dict>`):**
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show properties on the map</string>
<key>GoogleMapsAPIKey</key>
<string>AIzaSyD_PUT_YOUR_KEY_HERE</string>
```

---

## ✨ Done! Test It

```bash
flutter clean
flutter pub get
flutter run -d chrome
```

**Click a property card → PropertyDetailsScreen loads with all 15 sections!**

---

## 🧪 Quick Test Checklist

- [ ] App loads without crashing
- [ ] Property details display
- [ ] Amenities show as tags
- [ ] Map displays (if you added API key correctly)
- [ ] FAQs can expand/collapse
- [ ] Bottom "Book Now" bar stays fixed
- [ ] Can scroll through all sections smoothly

---

## ⚠️ Common Issue: "Map is blank"

**Cause:** Google Maps API key not added or wrong key

**Fix:**
1. Double-check you copied the FULL API key (it's long)
2. Verify you pasted it in the right files:
   - AndroidManifest.xml
   - Info.plist (iOS)
3. Run `flutter clean && flutter pub get`
4. Restart the app

---

## 📋 What Works Without API Key

✅ Images  
✅ Title & rating  
✅ Owner info  
✅ Amenities  
✅ Highlights  
✅ Price  
✅ Timings  
✅ FAQs  
✅ Reviews  
✅ Chat button  
✅ Book Now button  
✅ Share button  

❌ **Only Maps needs API key**

---

## 📁 Files You Edited

Just 2 files to modify:
1. `android/app/src/main/AndroidManifest.xml` ← Add API key here
2. `ios/Runner/Info.plist` ← Add API key here

**Everything else is already done!**

---

## ✅ Verification

Run this command to check for errors:
```bash
flutter analyze
```

Should show: **0 errors** ✅

---

**That's it! You're ready to ship! 🚀**
