# Property Details Screen - Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                     PROPERTY DETAILS SCREEN                          │
│                    (Main User Interface)                             │
└──────────┬────────────────────────────────────────────────────────────┘
           │
           ├─────────────────────────────────────────────────────────┐
           │                     APPBAR SECTION                       │
           ├──────────┬────────────────────────────────────────┬─────┤
           │          │                                        │     │
           │      Title   │   Share Button (share_plus)   │ Favorite
           │          │                                        │     │
           └──────────┴────────────────────────────────────────┴─────┘
           │
           ├─────────────────────────────────────────────────────────┐
           │              SCROLLABLE CONTENT (body)                   │
           │  SingleChildScrollView → Column                         │
           ├─────────────────────────────────────────────────────────┤
           │
           │  ┌──────────────────────────────────────────┐
           │  │  1. IMAGE GALLERY (PageView)             │
           │  │     [Img1] [Img2] [Img3]                │
           │  └──────────────────────────────────────────┘
           │
           │  ┌──────────────────────────────────────────┐
           │  │  2. TITLE & RATING                       │
           │  │     "Beach Villa" ⭐ 4.5 (42 reviews)    │
           │  │     📍 Goa, Maharashtra                 │
           │  └──────────────────────────────────────────┘
           │
           │  ┌──────────────────────────────────────────┐
           │  │  3. CHAT WITH OWNER BUTTON               │
           │  │     [💬 Chat with Owner]                │
           │  └──────────────────────────────────────────┘
           │
           │  ┌──────────────────────────────────────────┐
           │  │  4. MANAGED BY SECTION                   │
           │  │     👤 John Doe (Verified) ✓             │
           │  │     📞 +91-9999999999                    │
           │  └──────────────────────────────────────────┘
           │
           │  ┌──────────────────────────────────────────┐
           │  │  5. HIGHLIGHTS (Chips)                   │
           │  │     [Pool] [WiFi] [Kitchen] [Parking]   │
           │  └──────────────────────────────────────────┘
           │
           │  ┌──────────────────────────────────────────┐
           │  │  6. WHY CHOOSE US (Grid)                 │
           │  │     🎯 24/7  🔒 Secure  ✓ Verified  💰 Value
           │  └──────────────────────────────────────────┘
           │
           │  ┌──────────────────────────────────────────┐
           │  │  7. PRICE OVERVIEW                       │
           │  │     ₹5,000/night (Including taxes)      │
           │  └──────────────────────────────────────────┘
           │
           │  ┌──────────────────────────────────────────┐
           │  │  8. TIMINGS                              │
           │  │     🔓 Check-in: 2:00 PM │ 🔒 Out: 11 AM│
           │  └──────────────────────────────────────────┘
           │
           │  ┌──────────────────────────────────────────┐
           │  │  9. AMENITIES (Tags)                     │
           │  │     [AC] [WiFi] [Kitchen] [Parking]     │
           │  └──────────────────────────────────────────┘
           │
           │  ┌──────────────────────────────────────────┐
           │  │  10. DESCRIPTION                         │
           │  │     "Beautiful beachfront property with" │
           │  │      "stunning ocean views and modern"   │
           │  │      "amenities..."                      │
           │  └──────────────────────────────────────────┘
           │
           │  ┌──────────────────────────────────────────┐
           │  │  11. GOOGLE MAP                          │
           │  │     ┌─────────────────────┐             │
           │  │     │                     │  📍         │
           │  │     │                     │             │
           │  │     │     (Map View)      │             │
           │  │     │                     │             │
           │  │     └─────────────────────┘             │
           │  └──────────────────────────────────────────┘
           │
           │  ┌──────────────────────────────────────────┐
           │  │  12. NEARBY ATTRACTIONS (Scroll Horizontal)
           │  │     [🏖️ Beach | 🍴 Restaurant | ...] │
           │  └──────────────────────────────────────────┘
           │
           │  ┌──────────────────────────────────────────┐
           │  │  13. FAQs (Expandable)                   │
           │  │     ▶ When is check-in?                 │
           │  │       ▼ Answer text...                  │
           │  │     ▶ Is WiFi included?                 │
           │  │     ▶ Pet policy?                       │
           │  └──────────────────────────────────────────┘
           │
           │  ┌──────────────────────────────────────────┐
           │  │  14. POLICIES & RULES                    │
           │  │     📋 Check-in Policy                  │
           │  │     📋 Check-out Policy                 │
           │  │     ⛔ Cancellation Policy (Highlighted) │
           │  │     🏠 House Rules                       │
           │  └──────────────────────────────────────────┘
           │
           │  ┌──────────────────────────────────────────┐
           │  │  15. REVIEWS                             │
           │  │     [Add Review Button]                 │
           │  │     ┌─────────────────────────────┐    │
           │  │     │ 👤 Alice ⭐⭐⭐⭐⭐            │    │
           │  │     │ Great property! [📸 Photos] │    │
           │  │     │ Mar 1, 2026              (❤️ 3) │    │
           │  │     └─────────────────────────────┘    │
           │  │     ┌─────────────────────────────┐    │
           │  │     │ 👤 Bob ⭐⭐⭐⭐              │    │
           │  │     │ Nice stay, clean...            │    │
           │  │     └─────────────────────────────┘    │
           │  └──────────────────────────────────────────┘
           │
           │  ┌──────────────────────────────────────────┐
           │  │  16. SIMILAR PROPERTIES (Scroll Horizontal)
           │  │     [Property 1] [Property 2] [Prop 3] │
           │  │     ₹4,500  ⭐4.3                       │
           │  └──────────────────────────────────────────┘
           │
           └─────────────────────────────────────────────────────────┘
           │
           └─────────────────────────────────────────────────────────┐
                       FIXED BOTTOM NAV BAR                          │
              ────────────────────────────────────────────────────    │
              │ ₹5,000/night              [📕 Book Now] │           │
              │ Including taxes                          │           │
              ────────────────────────────────────────────────────    │
           └─────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════

SERVICE ARCHITECTURE
═══════════════════════════════════════════════════════════════════════

PropertyDetailsScreen
│
├─→ PropertyService
│   ├─ getPropertyById()
│   ├─ getAllProperties()
│   ├─ getPropertiesByCategory()
│   ├─ getPropertiesByCity()
│   ├─ getSimilarProperties()
│   └─ updateProperty()
│   │
│   └─→ Firebase Firestore
│       └─ /properties/{id}
│
├─→ FAQService
│   ├─ getFAQsByPropertyId()
│   ├─ addFAQ()
│   ├─ updateFAQ()
│   └─ deleteFAQ()
│   │
│   └─→ Firebase Firestore
│       └─ /properties/{id}/faqs/{faqId}
│
├─→ ReviewServiceComplete
│   ├─ getReviewsByPropertyId()
│   ├─ addReview()
│   ├─ deleteReview()
│   └─ markAsHelpful()
│   │
│   └─→ Firebase Firestore
│       ├─ /properties/{id}/reviews/{reviewId}
│       └─ Updates: averageRating, reviewCount
│
├─→ ChatService
│   ├─ getOrCreateChat()
│   ├─ getMessages() [Stream]
│   ├─ sendMessage()
│   └─ getUserChats() [Stream]
│   │
│   └─→ Firebase Firestore
│       ├─ /chats/{chatId}
│       └─ /chats/{chatId}/messages/{msgId}
│
└─→ Google Maps Flutter
    └─ GoogleMap Widget
        └─ LatLng(latitude, longitude)

═══════════════════════════════════════════════════════════════════════

DATA MODEL HIERARCHY
═══════════════════════════════════════════════════════════════════════

PropertyModel
├─ id: String
├─ userId: String
├─ name: String
├─ description: String
├─ category: String
├─ city: String
├─ state: String
├─ latitude: double
├─ longitude: double
├─ pricePerNight: double
├─ bedrooms: int
├─ bathrooms: int
├─ maxGuests: int
├─ minStay: int
├─ imageUrls: List<String>
├─ highlights: List<String>
├─ amenities: List<String>
├─ policies: Map
│  ├─ checkInPolicy: String
│  ├─ checkOutPolicy: String
│  ├─ cancellationPolicy: String
│  └─ houseRules: String
├─ timings: Map
│  ├─ checkInTime: String
│  └─ checkOutTime: String
├─ nearbyAttractions: List<NearbyAttraction>
│  ├─ name: String
│  ├─ distance: double
│  ├─ imageUrl: String?
│  └─ type: String?
├─ averageRating: double
├─ reviewCount: int
├─ instantBooking: bool
├─ isActive: bool
├─ createdAt: DateTime
└─ ownerDetails: Map?
   ├─ name: String
   ├─ image: String
   ├─ contact: String
   └─ isVerified: bool

ReviewModel
├─ id: String
├─ propertyId: String
├─ userId: String
├─ userName: String
├─ userImage: String
├─ rating: int
├─ reviewText: String
├─ imageUrls: List<String>
├─ createdAt: DateTime
└─ helpfulCount: int

ChatModel
├─ id: String
├─ propertyId: String
├─ userId: String
├─ ownerId: String
├─ participants: List<String>
├─ createdAt: DateTime
├─ lastMessageTime: DateTime
└─ lastMessagePreview: String

ChatMessage
├─ id: String
├─ chatId: String
├─ senderId: String
├─ senderName: String
├─ message: String
├─ timestamp: DateTime
└─ isRead: bool

═══════════════════════════════════════════════════════════════════════

FIRESTORE COLLECTION STRUCTURE
═══════════════════════════════════════════════════════════════════════

Database
│
├─ properties/
│  └─ {propertyId}/
│     ├─ id, userId, name, description, category, city, state
│     ├─ latitude, longitude, pricePerNight, bedrooms, bathrooms
│     ├─ maxGuests, minStay, imageUrls[], highlights[], amenities[]
│     ├─ policies{}, timings{}, nearbyAttractions[], ownerDetails{}
│     ├─ averageRating, reviewCount, instantBooking, isActive, createdAt
│     │
│     ├─ faqs/ [Subcollection]
│     │  └─ {faqId}/
│     │     ├─ question, answer, order
│     │
│     └─ reviews/ [Subcollection]
│        └─ {reviewId}/
│           ├─ userId, userName, userImage, rating, reviewText
│           ├─ imageUrls[], createdAt, helpfulCount
│
└─ chats/
   └─ {chatId}/
      ├─ propertyId, userId, ownerId, participants[]
      ├─ createdAt, lastMessageTime, lastMessagePreview
      │
      └─ messages/ [Subcollection]
         └─ {messageId}/
            ├─ senderId, senderName, message, timestamp, isRead

═══════════════════════════════════════════════════════════════════════
```

## Component Integration Flow

```
User Action → PropertyDetailsScreen
                    ↓
        ┌───────────────────────────────────────┐
        │   Load Property Data (onInitState)    │
        └───────────┬───────────────────────────┘
                    ↓
          PropertyService.getPropertyById()
                    ↓
            Firebase Firestore
                    ↓
        Display Property Data (setState)
                    ↓
        ┌───────────────────────────────────────┐
        │   Build UI Sections in Order          │
        ├───────────────────────────────────────┤
        │ 1. Gallery    6. Why Choose Us  11. Map
        │ 2. Title      7. Price         12. Attractions
        │ 3. Chat Btn   8. Timings       13. FAQs
        │ 4. Managed By 9. Amenities     14. Policies
        │ 5. Highlights 10. Description  15. Reviews
        │                                16. Similar
        │ 17. Fixed Bottom Bar
        └───────────────────────────────────────┘

Chat Flow:
User Clicks Chat → getOrCreateChat() → ChatScreen
                                            ↓
                                    ChatService
                                            ↓
                                    Firestore Streams
                                            ↓
                                    Show Messages
```

## State Management Flow

```
PropertyDetailsScreen
│
├─ State Variables:
│  ├─ property: PropertyModel
│  ├─ isLoading: bool
│  └─ FAQs/Reviews/Similar: FutureBuilder
│
├─ On Init:
│  └─ _loadProperty()
│       ├─ Fetch property
│       ├─ setState() → isLoading = false
│       └─ Rebuild UI
│
├─ User Interactions:
│  ├─ Share → Share.share()
│  ├─ Favorites → setState() + save
│  ├─ Chat → openChat() → ChatScreen
│  ├─ Review → _showReviewDialog() → addReview()
│  └─ Book Now → _handleBookNow()
│
└─ Data Updates:
   └─ Triggered by service responses
      ├─ Reviews update averageRating
      ├─ FAQs load dynamically
      └─ Similar properties calculated
```

---

**Architecture Version**: 1.0
**Last Updated**: March 1, 2026
**Status**: Complete ✅
