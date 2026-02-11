# Duffel Flight API - Architecture & Data Flow

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     FLUTTER APP (Skybase)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              UI Layer (Screens)                          │   │
│  ├──────────────────────────────────────────────────────────┤   │
│  │  • FlightSearchScreen                                    │   │
│  │    └─ Search form (airports, dates, passengers)         │   │
│  │    └─ Results ListView                                  │   │
│  │    └─ OfferCard widget                                  │   │
│  │                                                           │   │
│  │  • OrderCreationScreen                                  │   │
│  │    └─ Passenger info form                              │   │
│  │    └─ Contact info form                                │   │
│  │    └─ Confirmation screen                              │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              ▲                                    │
│                              │ Build Widgets                      │
│                              │                                    │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │           Service Layer (Business Logic)                │   │
│  ├──────────────────────────────────────────────────────────┤   │
│  │  • DuffelService                                         │   │
│  │    └─ searchFlights()      → POST /air/search_sessions  │   │
│  │    └─ getSearchResults()   → GET  /air/search_sessions  │   │
│  │    └─ createOrder()        → POST /orders               │   │
│  │    └─ getOrder()           → GET  /orders               │   │
│  │                                                           │   │
│  │  • Models (Data Transfer)                               │   │
│  │    └─ SearchFlightsResponse                            │   │
│  │    └─ Offer / Slice / Segment                          │   │
│  │    └─ Airline / Airport                                │   │
│  │    └─ PassengerData / OrderResponse                    │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              ▲                                    │
│                              │ HTTP Calls                         │
│                              │ JSON Serialization                 │
│                              │                                    │
└──────────────────────────────┼────────────────────────────────────┘
                               │
                               │ HTTPS
                               │
                ┌──────────────────────────────┐
                │  DUFFEL SANDBOX API           │
                ├──────────────────────────────┤
                │  https://api.duffel.com       │
                │                               │
                │  • Search Sessions            │
                │  • Flight Offers              │
                │  • Orders Management          │
                │  • Booking Details            │
                └──────────────────────────────┘
```

---

## 📡 Data Flow Diagrams

### Flow 1: Flight Search

```
User Input                API Call               Results Display
─────────────             ────────              ───────────────

User fills form    →    FlightSearchScreen    →    ListView
  • Departure             sends search params      displays
  • Arrival        →     to DuffelService    →    offers with
  • Dates                                          • Price
  • Passengers                                     • Route
                          ↓                        • Airline
                   Creates search session
                   (returns session ID)
                          ↓
                   System starts polling
                   every 1 second
                          ↓
                   Results appear
                          ↓
                   User selects offer
```

### Flow 2: Order Creation

```
Offer Selected            Form Submission           Order Created
───────────────           ────────────              ─────────────

User clicks     →    OrderCreationScreen    →    DuffelService
"Select & Continue"                              creates order
                      Form appears
                      ↓
User fills      →    • Title
passenger info        • Name
                      • Email
                      • Phone
                      • DOB
                      • Gender
                      ↓
User fills      →    • Contact Email
contact info          • Contact Phone
                      ↓
User clicks     →    Validation check
"Create Order"       ↓
                    API POST /orders
                    with all details
                      ↓
                    Order created
                      ↓
                    Show confirmation
                    with Order ID
```

### Flow 3: Data Persistence

```
Order Created              Firestore                User History
─────────────              ─────────               ─────────────

OrderResponse      →    Save to Firestore    →    StreamBuilder
  • Order ID             flight_bookings          fetches bookings
  • Total Amount    →    collection          →    displays to user
  • Currency             • userId
  • Status               • orderId
                         • totalPrice
                         • createdAt
                         
                              ↓
                         
                    Send FCM Notification
                         ↓
                    User receives push
```

---

## 🔄 Complete User Journey

```
START
  ↓
[1] FLIGHT SEARCH PAGE
  ├─ User enters:
  │  ├─ Departure Airport (LAX)
  │  ├─ Arrival Airport (JFK)
  │  ├─ Departure Date (Feb 25)
  │  ├─ Return Date (optional)
  │  └─ Passengers (1-5)
  │
  ├─ SEARCH ACTION
  │  ├─ API: POST /air/search_sessions
  │  ├─ Returns: Session ID
  │  ├─ Polling: Every 1 second for 30 seconds
  │  └─ Receives: List of Offers
  │
  ├─ RESULTS DISPLAY
  │  ├─ ListView shows up to 10 offers
  │  ├─ Each card shows:
  │  │  ├─ Price (green)
  │  │  ├─ Route (LAX → JFK)
  │  │  ├─ Offer ID (truncated)
  │  │  └─ Select Button
  │  │
  │  └─ User selects best offer
  │      ↓
[2] ORDER CREATION PAGE
  ├─ PASSENGER INFORMATION
  │  ├─ Title: Mr/Ms/Mrs/Dr
  │  ├─ First Name
  │  ├─ Last Name
  │  ├─ Email
  │  ├─ Phone Number
  │  ├─ Date of Birth (picker)
  │  └─ Gender: Male/Female
  │
  ├─ CONTACT INFORMATION
  │  ├─ Contact Email
  │  └─ Contact Phone
  │
  ├─ VALIDATION
  │  ├─ All fields required
  │  ├─ Email format check
  │  ├─ Phone number check
  │  └─ Date format check (YYYY-MM-DD)
  │
  ├─ CREATE ORDER ACTION
  │  ├─ API: POST /orders
  │  │   with:
  │  │   ├─ Offer ID
  │  │   ├─ Passenger data
  │  │   ├─ Contact email
  │  │   └─ Contact phone
  │  │
  │  ├─ Returns: OrderResponse
  │  │   with:
  │  │   ├─ Order ID
  │  │   ├─ Total Price
  │  │   ├─ Status
  │  │   └─ Creation Time
  │  │
  │  └─ Save to Firestore
  │      flight_bookings collection
  │
[3] CONFIRMATION PAGE
  ├─ SUCCESS MESSAGE
  │  ├─ Green checkmark
  │  └─ "Order Created Successfully"
  │
  ├─ ORDER DETAILS CARD
  │  ├─ Order ID
  │  ├─ Total: USD XXX
  │  ├─ Status: pending
  │  └─ Created: timestamp
  │
  ├─ FLIGHT DETAILS CARD
  │  ├─ Price: USD XXX
  │  └─ Route: LAX → JFK
  │
  └─ BACK TO SEARCH BUTTON
     └─ Returns to [1]

END (Booking Complete!)
```

---

## 🔐 Authentication & Security Flow

```
                  Environment Setup
                  ─────────────────
                         ↓
                  .env file with token
                  DUFFEL_ACCESS_TOKEN
                         ↓
              flutter_dotenv loads it
                         ↓
              DuffelService receives it
                         ↓
            Included in every API call
                         ↓
        Authorization: Bearer {token}
                         ↓
            Request validated by API
                         ↓
          Response returned (or error)
```

---

## 📊 Data Model Relationships

```
SearchFlightsResponse
  ├─ id: String
  ├─ type: String
  └─ createdAt: String

Offer (Main Model)
  ├─ id: String
  ├─ totalAmount: double
  ├─ totalCurrency: String
  ├─ slices: List<Slice> ────┐
  ├─ airlines: List<Airline>  │
  └─ airports: List<Airport>  │
                              │
Slice                     <───┘
  ├─ id: String
  ├─ departureAirportIata: String
  ├─ arrivalAirportIata: String
  ├─ departureAt: String
  ├─ arrivalAt: String
  └─ segments: List<Segment> ────┐
                                  │
Segment                      <───┘
  ├─ id: String
  ├─ departureAirportIata: String
  ├─ arrivalAirportIata: String
  ├─ departureAt: String
  ├─ arrivalAt: String
  └─ operatingCarrierCode: String

Airline
  ├─ iataCode: String
  └─ name: String

Airport
  ├─ iataCode: String
  ├─ name: String
  └─ city: String

PassengerData
  ├─ title: String
  ├─ firstName: String
  ├─ lastName: String
  ├─ email: String
  ├─ phoneNumber: String
  ├─ dateOfBirth: String
  └─ gender: String

OrderResponse
  ├─ id: String
  ├─ type: String
  ├─ totalAmount: double
  ├─ totalCurrency: String
  ├─ createdAt: String
  └─ status: String
```

---

## 🔄 State Management Flow

```
FlightSearchScreen State
├─ _offers: List<Offer>
├─ _sessionId: String?
├─ _isLoading: bool
├─ _errorMessage: String?
└─ Controllers:
   ├─ _departureController
   ├─ _arrivalController
   ├─ _departureDateController
   ├─ _returnDateController
   └─ _passengersController

OrderCreationScreen State
├─ _createdOrder: OrderResponse?
├─ _isLoading: bool
├─ _errorMessage: String?
└─ Controllers:
   ├─ Passenger info (6)
   └─ Contact info (2)
```

---

## 🚀 API Call Sequence

```
SEQUENCE 1: Search Flow
─────────────────────

Client                          Server
───────                         ──────

POST /air/search_sessions ──────→
  {slices, passengers}
                            ←──── 201 Created
                                {session_id}

GET /air/search_sessions/{id}   →
/offers (polling)
                            ←──── 200 OK
                                {offers[]}

(repeat polling until results)

SEQUENCE 2: Order Creation
──────────────────────────

POST /orders ──────────────────→
  {offers, passengers, contact}
                            ←──── 201 Created
                                {order_data}

GET /orders/{id} (optional)───→
                            ←──── 200 OK
                                {order_data}
```

---

## 📱 Screen Navigation

```
                    ┌─────────────────┐
                    │   Main App      │
                    └────────┬────────┘
                             │
                    ┌────────┴─────────┐
                    │                  │
            ┌───────▼───────┐    ┌────▼─────────┐
            │ Flight Search │    │ Other Screens│
            │   Screen      │    │ (Dashboard,  │
            │               │    │  etc.)       │
            └───────┬───────┘    └──────────────┘
                    │
                    │ on Select Offer
                    │
            ┌───────▼──────────────┐
            │ Order Creation       │
            │ Screen               │
            │ - Passenger Form     │
            │ - Contact Form       │
            └───────┬──────────────┘
                    │
                    │ on Create Order
                    │
            ┌───────▼──────────────┐
            │ Confirmation         │
            │ Screen               │
            │ - Order Details      │
            │ - Back Button        │
            └───────┬──────────────┘
                    │
                    │ Back to Search
                    │
                    └─────────────────→ [FlightSearchScreen]
```

---

## 🎯 Error Handling Paths

```
START
  ├─ [Search]
  │  ├─ Empty fields? → Show validation error
  │  ├─ API error? → Display error message
  │  ├─ Timeout? → "No results found" after 30s
  │  └─ Success? → Show offers
  │
  ├─ [Order Creation]
  │  ├─ Empty fields? → Show validation error
  │  ├─ Invalid email? → Show error
  │  ├─ Invalid phone? → Show error
  │  ├─ API error? → Display error message
  │  └─ Success? → Show confirmation
  │
  └─ [Confirmation]
     └─ Back button → Return to search
```

---

## 📈 Performance Considerations

```
Operation              Time        Strategy
─────────────         ────        ────────

Search Creation       ~200ms       Cached session ID
Result Polling        1-30s        Smart polling
                                   (1s intervals)

Order Creation        ~500ms       Validation before
                                   API call

JSON Parsing          ~50ms        Efficient model
                                   deserialization

Total User Flow       ~5-35s       Depends on
                                   polling results
```

---

## 🔗 Integration Points with Skybase

```
                    Duffel Flight API
                           ↑
                           │
                  DuffelService
                           ↑
                           │
            ┌──────────────┴──────────────┐
            │                             │
    FlightSearchScreen          OrderCreationScreen
            │                             │
            └──────────────┬──────────────┘
                           │
            ┌──────────────┴──────────────┐
            │                             │
        Firebase              FCM Notifications
    (flight_bookings)        (user notification)
        Storage
            │                             │
            └──────────────┬──────────────┘
                           │
                  Skybase Dashboard
                    (Show bookings)
```

---

**This architecture ensures:**
- ✅ Clean separation of concerns
- ✅ Easy to test and maintain
- ✅ Scalable for future features
- ✅ Secure token handling
- ✅ Efficient API usage
- ✅ Great user experience
