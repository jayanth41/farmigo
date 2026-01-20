class AppRoutes {
  // Main tabs
  static const String home = '/';
  static const String favorites = '/favorites';
  static const String bookings = '/bookings';
  static const String profile = '/profile';

  // Category / content screens
  static const String farmhouses = '/farmhouses';
  static const String villas = '/villas';
  static const String hotels = '/hotels';
  static const String flights = '/flights';
  static const String carRentals = '/car_rentals';

  // Other screens
  static const String offers = '/offers';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String helpSupport = '/help_support';
  static const String privacy = '/privacy';

  // Labels used in Drawer (centralized to avoid magic strings)
  static const String labelHome = 'Home';
  static const String labelFavorites = 'My Favorites';
  static const String labelBookings = 'My Bookings';
  static const String labelProfile = 'Profile';

  static const String labelFarmhouses = 'Farmhouses';
  static const String labelVillas = 'Villas';
  static const String labelHotels = 'Hotels';
  static const String labelFlights = 'Flights';
  static const String labelCarRentals = 'Car Rentals';

  static const String labelOffers = 'Offers & Deals';
  static const String labelNotifications = 'Notifications';
  static const String labelSettings = 'Settings';
  static const String labelHelp = 'Help & Support';
  static const String labelPrivacy = 'Privacy Policy';

  static final Map<String, String> labelToRoute = {
    labelHome: home,
    labelFavorites: favorites,
    labelBookings: bookings,
    labelProfile: profile,

    labelFarmhouses: farmhouses,
    labelVillas: villas,
    labelHotels: hotels,
    labelFlights: flights,
    labelCarRentals: carRentals,

    labelOffers: offers,
    labelNotifications: notifications,
    labelSettings: settings,
    labelHelp: helpSupport,
    labelPrivacy: privacy,
  };

  static String? routeToLabel(String? route) {
    if (route == null) return null;
    final entry = labelToRoute.entries.firstWhere(
      (e) => e.value == route,
      orElse: () => const MapEntry('', ''),
    );
    return entry.key.isEmpty ? null : entry.key;
  }
}
