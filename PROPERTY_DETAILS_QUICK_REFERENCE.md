# Property Details Screen - Quick Reference Guide

## Quick Start

### 1. Navigate to Property Details
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PropertyDetailsScreen(
      propertyId: '12345',
      currentUserId: 'user123',
    ),
  ),
);
```

### 2. Access Services Directly
```dart
// Get property
final propertyService = PropertyService();
final property = await propertyService.getPropertyById('propertyId');

// Get FAQs
final faqService = FAQService();
final faqs = await faqService.getFAQsByPropertyId('propertyId');

// Add review
final reviewService = ReviewServiceComplete();
await reviewService.addReview(
  propertyId: 'propertyId',
  userId: 'userId',
  userName: 'John Doe',
  userImage: 'imageUrl',
  rating: 5,
  reviewText: 'Great property!',
  imageUrls: [],
);

// Start chat
final chatService = ChatService();
final chat = await chatService.getOrCreateChat(
  propertyId: 'propertyId',
  userId: 'userId',
  ownerId: 'ownerId',
);
```

## File Structure

```
lib/
├── models/
│   ├── property_model.dart       (PropertyModel, NearbyAttraction)
│   ├── faq_model.dart            (FAQModel)
│   ├── review_model.dart         (ReviewModel)
│   └── chat_model.dart           (ChatModel, ChatMessage)
│
├── services/
│   ├── property_service.dart     (PropertyService)
│   ├── faq_service.dart          (FAQService)
│   ├── review_service_complete.dart (ReviewServiceComplete)
│   └── chat_service.dart         (ChatService)
│
└── screens/
    ├── property_details_screen.dart  (Main property display)
    └── chat_screen.dart              (Real-time messaging)
```

## Component Overview

### PropertyDetailsScreen
**Purpose**: Display comprehensive property information

**Key Methods**:
- `_loadProperty()` - Load property data
- `_buildImageGallery()` - Image PageView
- `_buildTitleSection()` - Title + rating
- `_buildMapSection()` - Google Maps
- `_buildFAQsSection()` - FAQs
- `_buildReviewsSection()` - Reviews
- `_buildFixedBottomBar()` - Book Now button

**Parameters**:
- `propertyId` (required): Property ID
- `currentUserId` (optional): Current user ID

### ChatScreen
**Purpose**: Real-time messaging between user and property owner

**Key Methods**:
- `_sendMessage()` - Send a message
- `_formatTime()` - Format message timestamps

**Parameters**:
- `chatId` (required): Chat ID
- `currentUserId` (required): Current user ID
- `propertyName` (required): Property name
- `ownerName` (required): Owner name

## Models

### PropertyModel
```dart
PropertyModel(
  id: '123',
  userId: 'owner123',
  name: 'Beach House',
  description: 'Beautiful beach property...',
  category: 'Farmhouse',
  city: 'Goa',
  state: 'Goa',
  latitude: 15.2993,
  longitude: 73.8243,
  pricePerNight: 5000,
  bedrooms: 3,
  bathrooms: 2,
  maxGuests: 6,
  minStay: 1,
  imageUrls: ['url1', 'url2'],
  highlights: ['Pool', 'WiFi'],
  amenities: ['AC', 'WiFi', 'Parking'],
  policies: {
    'checkInPolicy': 'After 2 PM',
    'checkOutPolicy': 'Before 11 AM',
    'cancellationPolicy': 'Free cancellation before 48 hours',
    'houseRules': 'No parties, No smoking',
  },
  timings: {
    'checkInTime': '2:00 PM',
    'checkOutTime': '11:00 AM',
  },
  nearbyAttractions: [
    NearbyAttraction(
      name: 'Beach',
      distance: 0.5,
      imageUrl: 'url',
      type: 'Beach',
    ),
  ],
  averageRating: 4.5,
  reviewCount: 12,
  instantBooking: true,
  isActive: true,
  createdAt: DateTime.now(),
  ownerDetails: {
    'name': 'John Doe',
    'image': 'imageUrl',
    'contact': '+91-9999999999',
    'isVerified': true,
  },
)
```

### ReviewModel
```dart
ReviewModel(
  id: 'rev123',
  propertyId: 'prop123',
  userId: 'user123',
  userName: 'Alice',
  userImage: 'imageUrl',
  rating: 5,
  reviewText: 'Wonderful property!',
  imageUrls: ['photo1', 'photo2'],
  createdAt: DateTime.now(),
  helpfulCount: 3,
)
```

### ChatModel / ChatMessage
```dart
ChatModel(
  id: 'chat123',
  propertyId: 'prop123',
  userId: 'user123',
  ownerId: 'owner123',
  participants: ['user123', 'owner123'],
  createdAt: DateTime.now(),
  lastMessageTime: DateTime.now(),
  lastMessagePreview: 'Are you available?',
)

ChatMessage(
  id: 'msg123',
  chatId: 'chat123',
  senderId: 'user123',
  senderName: 'Alice',
  message: 'When is check-in?',
  timestamp: DateTime.now(),
  isRead: false,
)
```

## Services API

### PropertyService
```dart
// Get single property
PropertyModel? property = await propertyService.getPropertyById(id);

// Get all properties
List<PropertyModel> all = await propertyService.getAllProperties();

// Filter by category
List<PropertyModel> beach = await propertyService.getPropertiesByCategory('Beach');

// Filter by city
List<PropertyModel> goa = await propertyService.getPropertiesByCity('Goa');

// Get similar properties
List<PropertyModel> similar = await propertyService.getSimilarProperties(
  category: 'Farmhouse',
  city: 'Goa',
  currentPropertyId: 'current123',
  limit: 5,
);

// Update property
await propertyService.updateProperty('id', {'pricePerNight': 6000});
```

### FAQService
```dart
// Get FAQs for property
List<FAQModel> faqs = await faqService.getFAQsByPropertyId(propertyId);

// Add FAQ
await faqService.addFAQ(
  propertyId: 'prop123',
  question: 'Is WiFi free?',
  answer: 'Yes, WiFi is free',
);

// Update FAQ
await faqService.updateFAQ(
  propertyId: 'prop123',
  faqId: 'faq123',
  question: 'Is WiFi available?',
  answer: 'Yes, high-speed WiFi',
);

// Delete FAQ
await faqService.deleteFAQ('prop123', 'faq123');
```

### ReviewServiceComplete
```dart
// Get reviews
List<ReviewModel> reviews = await reviewService.getReviewsByPropertyId(propertyId);

// Add review (auto-updates rating)
await reviewService.addReview(
  propertyId: 'prop123',
  userId: 'user123',
  userName: 'Alice',
  userImage: 'url',
  rating: 5,
  reviewText: 'Great!',
  imageUrls: [],
);

// Mark as helpful
await reviewService.markAsHelpful('prop123', 'rev123');

// Delete review (auto-updates rating)
await reviewService.deleteReview('prop123', 'rev123');
```

### ChatService
```dart
// Create or get existing chat
ChatModel? chat = await chatService.getOrCreateChat(
  propertyId: 'prop123',
  userId: 'user123',
  ownerId: 'owner123',
);

// Get messages (Stream)
Stream<List<ChatMessage>> messages = chatService.getMessages('chat123');

// Send message
await chatService.sendMessage(
  chatId: 'chat123',
  senderId: 'user123',
  senderName: 'Alice',
  message: 'Hello!',
);

// Get user chats (Stream)
Stream<List<ChatModel>> userChats = chatService.getUserChats('user123');
```

## Configuration

### Google Maps
1. Get API key from Google Cloud Console
2. Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY" />
```

3. Add to `ios/Runner/Info.plist`:
```xml
<key>GMSApiKey</key>
<string>YOUR_API_KEY</string>
```

### Firestore Security Rules
```rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /properties/{propertyId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == resource.data.userId;
      
      match /faqs/{faqId} {
        allow read: if request.auth != null;
        allow write: if request.auth.uid == get(/databases/$(database)/documents/properties/$(propertyId)).data.userId;
      }
      
      match /reviews/{reviewId} {
        allow read: if request.auth != null;
        allow create: if request.auth.uid == request.resource.data.userId;
        allow update, delete: if request.auth.uid == resource.data.userId;
      }
    }
    
    match /chats/{chatId} {
      allow read, write: if request.auth.uid in resource.data.participants;
      
      match /messages/{messageId} {
        allow read: if request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
        allow create: if request.auth.uid == request.resource.data.senderId;
      }
    }
  }
}
```

## Troubleshooting

### Property not loading
- Check Firestore has property document
- Verify propertyId is correct
- Check Firebase rules allow read access

### Google Map shows blank
- Verify API key is configured
- Check location coordinates (latitude/longitude)
- Ensure authentication is valid

### Chat not working
- Check participants array in chat document
- Verify user ID matches in participants
- Check Firestore rules allow write to messages

### Reviews not updating rating
- Ensure review document is properly structured
- Check propertyId matches
- Verify ReviewServiceComplete is used

## Performance Tips

1. **Cache properties**: Store property data locally
2. **Lazy load images**: Use cached_network_image
3. **Paginate reviews**: Load reviews in batches
4. **Optimize queries**: Use document IDs not full queries
5. **Stream management**: Unsubscribe when widget disposes

## Security Best Practices

1. Always validate user ID before allowing edits
2. Use Firestore rules to enforce permissions
3. Sanitize user input before storing
4. Validate image URLs before displaying
5. Check ownership before allowing deletions

---

**Last Updated**: March 2026
**Version**: 1.0
**Status**: Production Ready ✅
