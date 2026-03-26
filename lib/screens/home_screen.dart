import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:get/get.dart';
import '../services/user_service.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/location_controller.dart';
import 'favorites_screen.dart';
import 'bookings_screen.dart';
import 'profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:get/get.dart';
import '../services/user_service.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/location_controller.dart';
import '../data/farmhouses_data.dart';
import 'favorites_screen.dart';
import 'bookings_screen.dart';
import 'profile_screen.dart';
import 'all_properties_screen.dart';
import 'owner_dashboard.dart';
import '../navigation/app_routes.dart';
import '../widgets/category_tabs.dart';
import '../widgets/offers_carousel.dart';
import '../widgets/app_drawer.dart';
import '../widgets/properties_grid.dart';
import 'filters_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:audioplayers/audioplayers.dart';
import 'notification_screen.dart';
import '../controllers/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../filters/filters_provider.dart';
import '../controllers/app_location_controller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/category.dart';
import 'location_selector_screen.dart';
import 'category_results_screen.dart';
import 'flight_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late LocationController locationController = Get.put(LocationController());
  // Subscribe to selected city changes so we can re-apply filters when user
  // chooses a different city from the LocationSelector.
  StreamSubscription<String>? _citySubscription;
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  // Animated placeholder state
  final List<String> _searchPlaceholders = [
    'Search farmhouses',
    'Search villas',
    'Search hotels',
    'Search flights',
    'Search car rentals',
    'Search hourly rentals',
  ];
  int _placeholderIndex = 0;
  String _searchPlaceholder = 'Search farmhouses';
  Timer? _placeholderTimer;

  // Bottom nav temporary border visibility
  bool _showBottomBorder = false;
  Timer? _bottomBorderTimer;
  late FavoritesController favoritesController;
  Map<String, dynamic>? _profile;
  bool _isProfileLoading = true;
  bool _didPromptForProfile = false;
  FiltersProvider? _filtersProvider;

  // Async location fetch state to avoid calling location APIs in build()
  Future<String?>? _locationFuture;

  // Location & Category selectors
  final String _selectedState = 'all';
  final String _selectedCategory = 'All';

  // Advanced filter state (shared with filters screen)
  RangeValues _priceRange = const RangeValues(0, 10000);
  double _maxDistance = 100;
  bool _luxuryOnly = false;
  double _minRating = 0;
  final Map<String, bool> _amenities = {
    'Pool': false,
    'WiFi': false,
    'Kitchen': false,
    'Breakfast': false,
  };
  final Map<String, bool> _propertyTypes = {
    'Farmhouse': false,
    'Villa': false,
    'Hotel': false,
    'Flights': false,
    'Car Rentals': false,
    'Hourly Rentals': false,
  };
  String _sortOption = 'Relevance';

  // Filtered list for search results
  List<Map<String, dynamic>> _filteredFarmhouses = [];

  // Firestore loaded properties
  List<Map<String, dynamic>> _allProperties = [];

  // Notification / animation state
  late final AnimationController _bellController;
  late final Animation<double> _bellAnimation;
  late final AudioPlayer _audioPlayer;
  // Local notifications plugin removed temporarily to avoid AGP/plugin
  // compatibility issues; we fall back to a simple sound alert.
  int _prevTotalUnread = 0;
  bool _seenFirstUnreadSnapshot = false;
  bool _fcmInitialized = false;

  @override
  void initState() {
    super.initState();
    _listenProperties();
    _searchController.addListener(_onSearchChanged);

    // Initialize FavoritesController
    if (!Get.isRegistered<FavoritesController>()) {
      Get.put(FavoritesController());
    }
    favoritesController = Get.find<FavoritesController>();

    // Initialize LocationController
    if (!Get.isRegistered<LocationController>()) {
      Get.put(LocationController());
    }
    locationController = Get.find<LocationController>();
    // Listen to city changes and re-apply filters so the UI updates
    // immediately when the user selects a city.
    try {
      _citySubscription = locationController.selectedCity.listen((_) {
        if (!mounted) return;
        _applyFilters();
      });
    } catch (_) {}

    // Load user profile from the app's user service (Firestore) if available
    loadProfile();

    // Subscribe to global filters provider updates after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final provider = Provider.of<FiltersProvider>(context, listen: false);
        _filtersProvider = provider;
        provider.addListener(_onGlobalFiltersChanged);
      } catch (_) {
        // Provider might not be available in some contexts; ignore.
      }
    });

    // Start animated placeholder cycling — show one phrase at a time
    _searchPlaceholder = _searchPlaceholders.first;
    _placeholderTimer = Timer.periodic(const Duration(seconds: 3), (t) {
      _placeholderIndex = (_placeholderIndex + 1) % _searchPlaceholders.length;
      setState(() {
        _searchPlaceholder = _searchPlaceholders[_placeholderIndex];
      });
    });
    // Init bell animation & notification tools
    _bellController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _bellAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(CurvedAnimation(parent: _bellController, curve: Curves.elasticOut));
    _bellController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _bellController.reverse();
    });

    _audioPlayer = AudioPlayer();
    _initFCM();
  }

  /// Listen to Firestore properties collection and keep local caches updated.
  void _listenProperties() {
    // Listen to all property documents and filter/normalize client-side.
    // Some projects use `isActive: true`, others use `status: 'active'` —
    // to be robust we fetch all and accept either indicator.
    FirebaseFirestore.instance
        .collection('properties')
        .snapshots()
        .listen((snapshot) {
      debugPrint('Firestore properties snapshot received: ${snapshot.docs.length} docs');
      // Map and normalize, then filter active documents.
      final mapped = snapshot.docs.map((d) {
        final raw = d.data();
        final Map<String, dynamic> m = Map<String, dynamic>.from(raw);
        // Ensure canonical keys expected by the UI
        m['id'] = d.id;
        // name normalization
        if ((m['propertyName'] == null || m['propertyName'].toString().isEmpty) && m['name'] != null) {
          m['propertyName'] = m['name'];
        }
        // city normalization
        if ((m['city'] == null || m['city'].toString().isEmpty) && m['location'] != null) {
          m['city'] = m['location'];
        }
        // price normalization
        if (m['pricePerNight'] == null && m['price'] != null) {
          m['pricePerNight'] = m['price'];
        }
        // photoUrls normalization: accept photoUrls (list) or image/imageUrl/images
        if (m['photoUrls'] == null) {
          if (m['images'] is List && (m['images'] as List).isNotEmpty) {
            m['photoUrls'] = List<String>.from((m['images'] as List).map((e) => e.toString()));
          } else if (m['imageUrl'] != null && m['imageUrl'].toString().isNotEmpty) {
            m['photoUrls'] = [m['imageUrl'].toString()];
          } else if (m['image'] != null && m['image'].toString().isNotEmpty) {
            m['photoUrls'] = [m['image'].toString()];
          } else {
            m['photoUrls'] = <String>[];
          }
        }
        // Also set imageUrl to first photo for UI components that expect it
        try {
          if ((m['imageUrl'] == null || (m['imageUrl'] as String).isEmpty) && m['photoUrls'] is List && (m['photoUrls'] as List).isNotEmpty) {
            m['imageUrl'] = (m['photoUrls'] as List).first.toString();
          }
        } catch (_) {}
        // amenities normalization: accept map {WiFi: true} or list ['WiFi']
        if (m['amenities'] is Map) {
          try {
            final map = Map<String, dynamic>.from(m['amenities']);
            m['amenities'] = map.entries.where((e) => e.value == true).map((e) => e.key).toList();
          } catch (_) {
            m['amenities'] = <String>[];
          }
        } else if (m['amenities'] is List) {
          m['amenities'] = List<String>.from((m['amenities'] as List).map((e) => e.toString()));
        } else {
          m['amenities'] = <String>[];
        }

        return m;
      }).toList();

      // Filter for active properties: prefer isActive boolean, fall back to status string
      final data = mapped.where((m) {
        try {
          if (m.containsKey('isActive')) {
            return m['isActive'] == true;
          }
          if (m.containsKey('status')) {
            final s = m['status']?.toString().toLowerCase() ?? '';
            return s == 'active' || s == 'enabled' || s == 'true';
          }
          // If neither field exists, assume active to avoid hiding docs unexpectedly.
          return true;
        } catch (_) {
          return false;
        }
      }).toList();
      debugPrint('Properties after isActive/status filter: ${data.length}');
      // Log first few properties for debug
      for (var i = 0; i < (data.length < 5 ? data.length : 5); i++) {
        try {
          debugPrint('Property[$i] name=${data[i]['propertyName']} city=${data[i]['city']} image=${(data[i]['photoUrls'] is List && data[i]['photoUrls'].isNotEmpty) ? data[i]['photoUrls'][0] : data[i]['imageUrl']} price=${data[i]['pricePerNight']}');
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() {
        _allProperties = List<Map<String, dynamic>>.from(data);
        // Initialize filtered list to all properties by default so "Featured"
        // sections show results when no filters are applied.
        _filteredFarmhouses = List<Map<String, dynamic>>.from(_allProperties);
      });
      debugPrint('Loaded properties: ${_allProperties.length}');
      _applyFilters();
      debugPrint('Filtered properties after load: ${_filteredFarmhouses.length}');
    });
  }

  Future<void> _initFCM() async {
    try {
      // Request permissions (iOS)
      await FirebaseMessaging.instance.requestPermission();

      // Note: flutter_local_notifications plugin removed temporarily.
      // We still request FCM permission and handle messages below.

      // Save token for current user and log it for diagnostics
      final user = FirebaseAuth.instance.currentUser;
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('[HomeScreen][FCM] token=$token user=${user?.uid}');
      if (user != null && token != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'fcmToken': token,
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('[HomeScreen][FCM] failed to write token to Firestore: $e');
        }
      }

      // Foreground message handling: play a short sound and optionally show
      // an in-app cue (SnackBar) when a notification arrives.
      FirebaseMessaging.onMessage.listen((message) async {
        final notif = message.notification;
        debugPrint('[HomeScreen][FCM] onMessage received: message=${message.messageId} notification=${notif?.title}/${notif?.body} data=${message.data}');
        if (notif != null) {
          try {
            await _playNotificationSound();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(notif.title ?? notif.body ?? 'New message'),
              duration: const Duration(seconds: 2),
            ));
          } catch (e) {
            debugPrint('[HomeScreen][FCM] onMessage handler error: $e');
          }
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('[HomeScreen][FCM] onMessageOpenedApp: message=${message.messageId} data=${message.data}');
        try {
          if (!mounted) return;
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationScreen()));
        } catch (e) {
          debugPrint('[HomeScreen][FCM] onMessageOpenedApp navigation error: $e');
        }
      });

      _fcmInitialized = true;
    } catch (e) {
      // ignore errors for now
    }
  }

  Future<void> _playNotificationSound() async {
    try {
      // Try simple system alert first (no extra asset required)
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {
      // ignore
    }
  }

  Future<void> loadProfile() async {
    setState(() => _isProfileLoading = true);
    debugPrint('[HomeScreen] loadProfile: fetching profile...');
    final data = await UserService().fetchUserProfile();
    debugPrint('[HomeScreen] loadProfile: fetch returned: $data');
    if (!mounted) return;
    setState(() {
      _profile = data;
      _isProfileLoading = false;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && (_profile == null || _profile!['profile_completed'] == false) && !_didPromptForProfile) {
      _didPromptForProfile = true;
      debugPrint('[HomeScreen] profile incomplete for user ${user.uid}; not auto-navigating to EditProfile.');
    }
  }

  void _onDrawerItemSelected(String label) async {
    if (label.toLowerCase() == 'logout') {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      if (!mounted) return;
      try {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } catch (_) {
        try {
          Navigator.of(context).pushReplacementNamed('/login');
        } catch (_) {}
      }
      return;
    }

    if (label == AppRoutes.labelProfile || label == 'Profile') {
      if (_profile == null) return;
      if (!mounted) return;
      try {
        await Navigator.pushNamed(context, AppRoutes.profile);
      } catch (e) {
        debugPrint('Failed to open profile: $e');
      }
      await loadProfile();
      return;
    }

    if (label == 'Owner Dashboard' || label == 'Owner Panel') {
      if (!mounted) return;
      Future.microtask(() {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OwnerDashboard()),
        );
      });
      return;
    }

    final route = AppRoutes.labelToRoute[label];
    if (route == null || route.isEmpty) return;

    Future.microtask(() {
      try {
        if (!mounted) return;
        if (route == AppRoutes.home) {
          try {
            Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
          } catch (e) {
            debugPrint('Fallback home navigation error: $e');
          }
          return;
        }

        try {
          Get.toNamed(route);
        } catch (e) {
          debugPrint('Get.toNamed failed: $e');
          try {
            if (!mounted) return;
            Navigator.of(context).pushNamed(route);
          } catch (e2) {
            debugPrint('Navigator.pushNamed failed: $e2');
          }
        }
      } catch (e) {
        debugPrint('Drawer action scheduling error: $e');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    try {
      _filtersProvider?.removeListener(_onGlobalFiltersChanged);
    } catch (_) {}
    try {
      _citySubscription?.cancel();
    } catch (_) {}
    _placeholderTimer?.cancel();
    _bottomBorderTimer?.cancel();
    _bellController.dispose();
    try {
      _audioPlayer.dispose();
    } catch (_) {}
    super.dispose();
  }

  Category _currentCategory() {
    final s = _selectedCategory.toLowerCase();
    if (s.contains('farm')) return Category.farmhouse;
    if (s.contains('villa')) return Category.villa;
    if (s.contains('hotel')) return Category.hotel;
    if (s.contains('flight') || s.contains('flights')) return Category.flights;
    if (s.contains('car')) return Category.car;
    if (s.contains('hour')) return Category.hourly;
    return Category.all;
  }

  void _onGlobalFiltersChanged() {
    final provider = _filtersProvider;
    if (provider == null) return;
    final cat = _currentCategory();
    final raw = provider.getRaw(cat);
    if (raw == null) return;

    setState(() {
      if (raw.containsKey('priceRange') && raw['priceRange'] is RangeValues) {
        _priceRange = raw['priceRange'] as RangeValues;
      }
      if (raw.containsKey('maxDistance') && raw['maxDistance'] is double) {
        _maxDistance = raw['maxDistance'] as double;
      }
      if (raw.containsKey('luxuryOnly') && raw['luxuryOnly'] is bool) {
        _luxuryOnly = raw['luxuryOnly'] as bool;
      }
      if (raw.containsKey('minRating') && raw['minRating'] is double) {
        _minRating = raw['minRating'] as double;
      }
      if (raw.containsKey('amenities') && raw['amenities'] is Map) {
        try {
          _amenities.addAll(Map<String, bool>.from(raw['amenities']));
        } catch (_) {}
      }
      // Backwards/alternate key names: some screens used 'houseAmenities' or
      // 'house_amenities' previously. Accept those as well to avoid silent
      // breakages when key names change in the filters UI.
      if (raw.containsKey('houseAmenities') && raw['houseAmenities'] is Map) {
        try {
          _amenities.addAll(Map<String, bool>.from(raw['houseAmenities']));
        } catch (_) {}
      }
      if (raw.containsKey('house_amenities') && raw['house_amenities'] is Map) {
        try {
          _amenities.addAll(Map<String, bool>.from(raw['house_amenities']));
        } catch (_) {}
      }
      if (raw.containsKey('propertyTypes') && raw['propertyTypes'] is Map) {
        try {
          _propertyTypes.addAll(Map<String, bool>.from(raw['propertyTypes']));
        } catch (_) {}
      }
      // Accept alternative naming for property types if used elsewhere
      if (raw.containsKey('property_types') && raw['property_types'] is Map) {
        try {
          _propertyTypes.addAll(Map<String, bool>.from(raw['property_types']));
        } catch (_) {}
      }
      if (raw.containsKey('sortOption') && raw['sortOption'] is String) {
        _sortOption = raw['sortOption'] as String;
      }
    });

    _applyFilters();
  }

  void _onSearchChanged() => _applyFilters();

  Future<String?> _fetchLocationOnce() async {
    if (_locationFuture != null) return _locationFuture!;
    _locationFuture = () async {
      try {
        try {
          final appLoc = Provider.of<AppLocationController>(context, listen: false);
          await appLoc.initialize();
          final name = appLoc.locationName;
          if (name.isNotEmpty && name != 'Fetching location...' && name != 'Location unavailable') {
            return name;
          }
          final p = await appLoc.getCurrentPosition();
          if (p != null) {
            return appLoc.locationName;
          }
        } catch (e) {
          debugPrint('AppLocationController not available or failed: $e');
        }

        await locationController.checkLocationStatus();
        if (!locationController.isLocationEnabled.value) {
          await locationController.requestLocationPermission();
        }

        if (!locationController.isLocationEnabled.value) {
          return 'Location disabled';
        }

        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best).timeout(const Duration(seconds: 10));
        try {
          final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final city = p.locality ?? '';
            final state = p.administrativeArea ?? '';
            if (city.isNotEmpty && state.isNotEmpty) return '$city, $state';
            if (city.isNotEmpty) return city;
          }
        } catch (e) {
          debugPrint('Reverse geocode fallback error: $e');
        }

        return '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      } catch (_) {
        return null;
      }
    }();

    return _locationFuture!;
  }

  void _showLocationSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (bc) {
        final TextEditingController ctl = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(bc).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<String?>(
              future: _fetchLocationOnce(),
              builder: (context, snap) {
                final loading = snap.connectionState == ConnectionState.waiting;
                final detected = snap.data;
                if (detected != null && detected.isNotEmpty) ctl.text = detected;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Edit location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    if (loading) const Text('Fetching location...')
                    else if (detected == 'Location disabled') const Text('Location disabled')
                    else if (detected == null) const Text('Could not detect location')
                    else const SizedBox.shrink(),
                    const SizedBox(height: 8),
                    TextField(
                      controller: ctl,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter location name or coordinates',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.of(bc).pop(), child: const Text('Cancel')),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            try {
                              final locCtrl = Provider.of<AppLocationController>(ctx, listen: false);
                              locCtrl.setLocationName(ctl.text.trim());
                            } catch (_) {}
                            Navigator.of(bc).pop();
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Location saved')));
                          },
                          child: const Text('Save'),
                        )
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _openLocationSelector(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bc) => const LocationSelectorScreen(),
    );
  }

  // Returns a list of up to 6 search suggestions based on name/location.
  List<String> _getSearchSuggestions(String query) {
    if (query.isEmpty) return [];

    final q = query.toLowerCase();
    final suggestions = <String>{};

    for (final farm in _allProperties) {
      final name = (farm['propertyName'] as String?)?.toLowerCase() ?? '';
      final location = (farm['city'] as String?)?.toLowerCase() ?? '';

      if (name.contains(q)) suggestions.add(farm['propertyName']);
      if (location.contains(q)) suggestions.add(farm['city']);

      if (suggestions.length >= 6) break;
    }

    return suggestions.toList();
  }

  Widget _buildHighlightedText(String text, String query) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final start = lowerText.indexOf(lowerQuery);

    if (start < 0 || query.isEmpty) return Text(text);

    final end = start + query.length;

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 14),
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: const TextStyle(
              color: Color.fromARGB(255, 41, 70, 92),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    final selectedState = _selectedState.toLowerCase();
    final selectedCategory = _selectedCategory.toLowerCase();

    setState(() {
      _filteredFarmhouses = _allProperties.where((farm) {
        debugPrint('HomeScreen: total properties loaded = ${_allProperties.length}');
        final name = (farm['propertyName'] as String?)?.toLowerCase() ?? '';
        final location = (farm['city'] as String?)?.toLowerCase() ?? '';
        // Selected city from LocationController
        String selectedCity = '';
        try {
          selectedCity = locationController.selectedCity.value.toLowerCase();
        } catch (_) {}
        // If a city is selected, only show properties from that city
        if (selectedCity.isNotEmpty && !location.contains(selectedCity)) {
          return false;
        }
        final price = (farm['pricePerNight'] is num)
            ? (farm['pricePerNight'] as num).toDouble()
            : 0.0;
        double distance = 0;
        try {
          if (farm['distance'] != null) {
            final raw = farm['distance'].toString();
            distance = double.tryParse(raw.split(' ').first) ?? 0;
          }
        } catch (_) {
          distance = 0;
        }

        bool matchesSearch = true;
        if (query.isNotEmpty) {
          matchesSearch = name.contains(query) || location.contains(query);
        }

        if (!(price >= _priceRange.start && price <= _priceRange.end)) {
          return false;
        }
        if (distance > _maxDistance) return false;
        if (_luxuryOnly && price < 3500) return false;

        final rating = (farm['rating'] is double) ? (farm['rating'] as double) : 0.0;
        if (rating < _minRating) return false;

        List<String> farmAmenities = [];
        try {
          if (farm['amenities'] is Map) {
            final map = Map<String, dynamic>.from(farm['amenities']);
            farmAmenities = map.entries
                .where((e) => e.value == true)
                .map((e) => e.key)
                .toList();
          } else if (farm['amenities'] is List) {
            farmAmenities = (farm['amenities'] as List).cast<String>();
          }
        } catch (_) {
          farmAmenities = [];
        }
        for (final entry in _amenities.entries) {
          if (entry.value && !farmAmenities.contains(entry.key)) {
            return false;
          }
        }

        final farmPropertyType =
            (farm['propertyType'] ?? farm['property_type'] ?? '').toString().toLowerCase();
        bool propertyTypeMatches = true;
        bool anyPropertyTypeSelected = _propertyTypes.values.any((v) => v);

        if (anyPropertyTypeSelected) {
          propertyTypeMatches = _propertyTypes.entries.any((entry) =>
              entry.value && farmPropertyType.contains(entry.key.toLowerCase()));
        }
        if (!propertyTypeMatches) return false;

        final farmState = (farm['state'] as String?)?.toLowerCase() ?? '';
        final farmCategory = (farm['category'] as String?)?.toLowerCase() ?? '';

        if (selectedState.isNotEmpty &&
            selectedState != 'all' &&
            farmState != selectedState) {
          return false;
        }
        if (selectedCategory.isNotEmpty &&
            selectedCategory != 'all' &&
            farmCategory != selectedCategory) {
          return false;
        }

        debugPrint('HomeScreen: property passed filters -> ${farm['propertyName']}');
        return matchesSearch;
      }).toList();

      switch (_sortOption) {
        case 'Price: Low to High':
          _filteredFarmhouses.sort((a, b) =>
              ((a['pricePerNight'] is num ? (a['pricePerNight'] as num).toDouble() : 0.0))
                  .compareTo(
                      (b['pricePerNight'] is num ? (b['pricePerNight'] as num).toDouble() : 0.0)));
          break;
        case 'Price: High to Low':
          _filteredFarmhouses.sort((a, b) =>
              ((b['pricePerNight'] is num ? (b['pricePerNight'] as num).toDouble() : 0.0))
                  .compareTo(
                      (a['pricePerNight'] is num ? (a['pricePerNight'] as num).toDouble() : 0.0)));
          break;
        case 'Distance':
          double dist(Map<String, dynamic> f) {
            double distance = 0;
            try {
              if (f['distance'] != null) {
                final raw = f['distance'].toString();
                distance = double.tryParse(raw.split(' ').first) ?? 0;
              }
            } catch (_) {
              distance = 0;
            }
            return distance;
          }
          _filteredFarmhouses.sort((a, b) => dist(a).compareTo(dist(b)));
          break;
        case 'Rating':
          double r(Map<String, dynamic> f) =>
              (f['rating'] is double) ? (f['rating'] as double) : 0.0;
          _filteredFarmhouses.sort((a, b) => r(b).compareTo(r(a)));
          break;
        case 'Relevance':
        default:
          break;
      }
    });
    debugPrint('Filtered properties (post _applyFilters): ${_filteredFarmhouses.length}');
  }

  @override
  Widget build(BuildContext context) {
    final hasAncestorScaffold = Scaffold.maybeOf(context) != null;

    if (hasAncestorScaffold) {
      return _buildBody();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        title: const Text(''),
        automaticallyImplyLeading: false,
      ),
      drawer: AppDrawer(
        profile: _profile,
        isProfileLoading: _isProfileLoading,
        onItemSelected: _onDrawerItemSelected,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildBody(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFF2F4B5F),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.15),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, "Home", 0),
              _buildNavItem(Icons.favorite, "Favorites", 1),
              _buildNavItem(Icons.calendar_today, "Bookings", 2),
              _buildNavItem(Icons.person, "Profile", 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _homePage();
      case 1:
        return const FavoritesScreen();
      case 2:
        return const BookingsScreen();
      case 3:
        if (_profile == null) {
          return const _GuestProfileView();
        }
        return const ProfileScreen();
      default:
        return _homePage();
    }
  }

  Widget _homePage() {
    return Column(
      children: [
        Container(
          // reduced vertical padding to make header more compact while still
          // covering the status bar area
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 4,
            16,
            8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.onPrimary),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                            children: [
                              TextSpan(text: 'SKY', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                              TextSpan(text: 'BASE', style: TextStyle(color: const Color(0xFFB9C5CC))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _openLocationSelector(context),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.95),
                                ),
                                const SizedBox(width: 6),
                                Builder(builder: (ctx) {
                                  try {
                                    final appLoc = Provider.of<AppLocationController>(ctx);
                                    final name = appLoc.locationName;
                                    return Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.92),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  } catch (_) {
                                    return Obx(() {
                                      final name = locationController.selectedLocationName;
                                      if (locationController.selectedCity.value.isNotEmpty) {
                                        return Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.92),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        );
                                      }
                                      return FutureBuilder<String?>(
                                        future: _fetchLocationOnce(),
                                        builder: (context, snap) {
                                          if (snap.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
                                          final val = snap.data;
                                          return Text(
                                            val ?? 'Location unavailable',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.92),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          );
                                        },
                                      );
                                    });
                                  }
                                }),
                                const SizedBox(width: 6),
                                Icon(Icons.keyboard_arrow_down, size: 16, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.95)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chat_bubble_outline, color: Theme.of(context).colorScheme.onPrimary),
                    onPressed: () {},
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseAuth.instance.currentUser != null
                        ? FirebaseFirestore.instance
                            .collection('chats')
                            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                            .snapshots()
                        : const Stream.empty(),
                    builder: (context, snapshot) {
                      int totalUnread = 0;
                      if (snapshot.hasData) {
                        try {
                          totalUnread = snapshot.data!.docs.fold<int>(0, (sum, doc) {
                            final v = doc.data();
                            if (v is Map<String, dynamic>) {
                              return sum + (v['unreadCountUser'] is int ? v['unreadCountUser'] as int : int.tryParse('${v['unreadCountUser']}') ?? 0);
                            }
                            // For QueryDocumentSnapshot without generic type
                            try {
                              final map = doc.data() as Map<String, dynamic>;
                              return sum + (map['unreadCountUser'] is int ? map['unreadCountUser'] as int : int.tryParse('${map['unreadCountUser']}') ?? 0);
                            } catch (_) {
                              return sum;
                            }
                          });
                        } catch (_) {
                          totalUnread = 0;
                        }
                      }

                      // Detect increases and trigger animation/sound once per increase
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        try {
                          if (!_seenFirstUnreadSnapshot) {
                            _seenFirstUnreadSnapshot = true;
                            _prevTotalUnread = totalUnread;
                          } else if (totalUnread > _prevTotalUnread) {
                            // animate and play sound
                            try {
                              _bellController.forward(from: 0);
                            } catch (_) {}
                            try {
                              _playNotificationSound();
                            } catch (_) {}
                          }
                          _prevTotalUnread = totalUnread;
                        } catch (_) {}
                      });

                      return IconButton(
                        onPressed: () {
                          // Navigate to notifications screen; NotificationScreen will clear unread counts
                          try {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationScreen()));
                          } catch (_) {}
                        },
                        icon: ScaleTransition(
                          scale: _bellAnimation,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(Icons.notifications_none, color: Theme.of(context).colorScheme.onPrimary),
                              if (totalUnread > 0)
                                Positioned(
                                  right: -2,
                                  top: -6,
                                  child: CircleAvatar(
                                    radius: 9,
                                    backgroundColor: Colors.red,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 1),
                                      child: Text(
                                        totalUnread > 99 ? '99+' : totalUnread.toString(),
                                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Builder(builder: (ctx) {
                final cs = Theme.of(ctx).colorScheme;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: TextField(
                    controller: _searchController,
                    cursorColor: cs.primary,
                    style: TextStyle(color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: _searchPlaceholder,
                      hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.65)),
                      filled: true,
                      fillColor: cs.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      prefixIcon: Icon(Icons.search, color: cs.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        Expanded(
          child: _searchController.text.isNotEmpty
              ? ListView(
                  padding: const EdgeInsets.only(bottom: 120),
                  children: [
                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Search results',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color.fromARGB(255, 41, 70, 92),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    ..._getSearchSuggestions(_searchController.text).map((s) {
                      final query = _searchController.text;
                      final titleWidget = _buildHighlightedText(s, query);
                      return ListTile(
                        leading: const Icon(Icons.search),
                        title: titleWidget,
                        onTap: () {
                          _searchController.text = s;
                          _searchController.selection = TextSelection.fromPosition(
                            TextPosition(offset: s.length),
                          );
                          _applyFilters();
                        },
                      );
                    }),

                    const SizedBox(height: 8),

                    PropertiesGrid(properties: _filteredFarmhouses),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 120),
                  children: [
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello 👋 ${_profile != null && _profile!['name'] != null ? _profile!['name'] : 'Guest'}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Where would you like to go...?',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: const Color.fromARGB(255, 41, 70, 92),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    const SizedBox(height: 8.5),
                    CategoryGrid(
                      selectedCategory: _selectedCategory,
                      onTap: (c) {
                        final cat = CategoryExt.fromLabel(c);

                        if (cat == Category.flights) {
                          debugPrint('[HomeScreen] Flights tapped → opening FlightSearchScreen');
                          Get.to(() => const FlightSearchScreen());
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryResultsScreen(
                              category: cat,
                              allProperties: _allProperties,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Last minute deals', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color:  Color.fromARGB(255, 41, 70, 92))),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 160,
                      child: StreamBuilder(
                        // Build the query dynamically so we can apply the selected
                        // city filter when the user has chosen a city.
                        stream: (() {
                          try {
                            final selectedCity = locationController.selectedCity.value.trim();
                            Query query = FirebaseFirestore.instance
                                .collection('properties')
                                .where('isLastMinuteDeal', isEqualTo: true)
                                .where('isActive', isEqualTo: true)
                                .where('lastMinuteValidTill', isGreaterThan: Timestamp.now());

                            if (selectedCity.isNotEmpty) {
                              // Only include deals for the selected city
                              query = query.where('city', isEqualTo: selectedCity);
                            }

                            query = query.orderBy('lastMinuteValidTill').orderBy('lastMinuteDiscount', descending: true);
                            return query.snapshots();
                          } catch (e) {
                            debugPrint('Failed to build deals query with city filter: $e');
                            return FirebaseFirestore.instance
                                .collection('properties')
                                .where('isLastMinuteDeal', isEqualTo: true)
                                .where('isActive', isEqualTo: true)
                                .where('lastMinuteValidTill', isGreaterThan: Timestamp.now())
                                .orderBy('lastMinuteValidTill')
                                .orderBy('lastMinuteDiscount', descending: true)
                                .snapshots();
                          }
                        })(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No last minute deals available',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          final deals = snapshot.data!.docs;

                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: deals.length > 6 ? 6 : deals.length,
                            itemBuilder: (context, index) {
                final raw = deals[index].data();
                final Map<String, dynamic> data = (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};
                final discount = data['lastMinuteDiscount'] ?? 0;
                final Timestamp? validTillTs = (data['lastMinuteValidTill'] is Timestamp)
                  ? data['lastMinuteValidTill'] as Timestamp
                  : null;

                              if (validTillTs == null) return const SizedBox.shrink();

                              return StreamBuilder<int>(
                                stream: Stream.periodic(const Duration(seconds: 30), (x) => x),
                                builder: (context, _) {
                                  final now = DateTime.now();
                                  final validTill = validTillTs.toDate();
                                  final remaining = validTill.difference(now);

                                  if (remaining.isNegative) {
                                    // Auto hide when expired
                                    return const SizedBox.shrink();
                                  }

                                  final hours = remaining.inHours;
                                  final minutes = remaining.inMinutes % 60;

                                  return Container(
                                    width: 260,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Card(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data['propertyName'] ?? 'Property',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(data['location'] ?? ''),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Expires in ${hours}h ${minutes}m',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.red,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Spacer(),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Builder(builder: (_) {
                                                  final originalPrice = (data['price'] ?? 0) as num;
                                                  final discountVal = (data['lastMinuteDiscount'] ?? 0) as num;
                                                  final discountedPrice = discountVal > 0
                                                      ? (originalPrice - (originalPrice * discountVal / 100)).round()
                                                      : originalPrice;

                                                  return Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      if (discountVal > 0)
                                                        Text(
                                                          '₹$originalPrice',
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey,
                                                            decoration: TextDecoration.lineThrough,
                                                          ),
                                                        ),
                                                      Text(
                                                        '₹$discountedPrice',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }),
                                                if (discount > 0)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: const Color.fromARGB(255, 41, 70, 92),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      '$discount% OFF',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Recommended', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color.fromARGB(255, 41, 70, 92))),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Featured Properties",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.filter_alt, size: 20, color: Color.fromARGB(255, 41, 70, 92)),
                            onPressed: () {
                              final cat = () {
                                final s = _selectedCategory.toLowerCase();
                                if (s.contains('farm')) return Category.farmhouse;
                                if (s.contains('villa')) return Category.villa;
                                if (s.contains('hotel')) return Category.hotel;
                                if (s.contains('flight') || s.contains('flights')) return Category.flights;
                                if (s.contains('car')) return Category.car;
                                if (s.contains('hour')) return Category.hourly;
                                return Category.all;
                              }();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FiltersScreen(
                                    category: cat,
                                    onFiltersApplied: (filters) {
                                      setState(() {
                                        _priceRange = filters['priceRange'] ?? _priceRange;
                                        _maxDistance = filters['maxDistance'] ?? _maxDistance;
                                        _luxuryOnly = filters['luxuryOnly'] ?? _luxuryOnly;
                                        _minRating = filters['minRating'] ?? _minRating;
                                        // Accept both old and new key names for amenities/property types
                                        final Map<String, dynamic> amenitiesFromCallback = Map<String, dynamic>.from(
                                            (filters['amenities'] ?? filters['houseAmenities'] ?? filters['house_amenities'] ?? <String, dynamic>{}) as Map);
                                        final Map<String, dynamic> propertyTypesFromCallback = Map<String, dynamic>.from(
                                            (filters['propertyTypes'] ?? filters['property_types'] ?? <String, dynamic>{}) as Map);

                                        try {
                                          _amenities.addAll(Map<String, bool>.from(amenitiesFromCallback));
                                        } catch (_) {}
                                        try {
                                          _propertyTypes.addAll(Map<String, bool>.from(propertyTypesFromCallback));
                                        } catch (_) {}

                                        _sortOption = filters['sortOption'] ?? _sortOption;
                                      });
                                      _applyFilters();
                                    },
                                    initialFilters: {
                                      'priceRange': _priceRange,
                                      'maxDistance': _maxDistance,
                                      'luxuryOnly': _luxuryOnly,
                                      'minRating': _minRating,
                                      'amenities': _amenities,
                                      'propertyTypes': _propertyTypes,
                                      'sortOption': _sortOption,
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AllPropertiesScreen(
                                    properties: _filteredFarmhouses,
                                  ),
                                ),
                              );
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('View all'),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios, size: 14),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    PropertiesGrid(properties: _filteredFarmhouses),

                    const SizedBox(height: 12),
                    // Additional horizontal property cards to appear below Recommended
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Explore more properties', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color:  Color.fromARGB(255, 41, 70, 92))),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _filteredFarmhouses.isNotEmpty ? (_filteredFarmhouses.length > 6 ? 6 : _filteredFarmhouses.length) : 0,
                        itemBuilder: (context, index) {
                          final item = _filteredFarmhouses[index];
                          return Container(
                            width: 260,
                            margin: const EdgeInsets.only(right: 12),
                            child: Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 110,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      image: (item['photoUrls'] is List && item['photoUrls'].isNotEmpty)
                                          ? DecorationImage(image: NetworkImage(item['photoUrls'][0]), fit: BoxFit.cover)
                                          : null,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['propertyName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Text(item['city'] ?? ''),
                                        const SizedBox(height: 6),
                                        Text('₹${(item['pricePerNight'] ?? 0).toString()}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Small dummy cards below Recommended
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('You might also like', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _filteredFarmhouses.isNotEmpty ? (_filteredFarmhouses.length > 3 ? 3 : _filteredFarmhouses.length) : 3,
                        itemBuilder: (context, index) {
                          final item = _filteredFarmhouses.isNotEmpty ? _filteredFarmhouses[index] : {
                            'name': 'Cozy Retreat',
                            'location': 'Nearby',
                            'price': 2500,
                          };
                          return Container(
                            width: 200,
                            margin: const EdgeInsets.only(right: 12),
                            child: Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name'] ?? 'Cozy Retreat', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(item['location'] ?? 'Nearby'),
                                    const Spacer(),
                                    Text('₹${(item['price'] ?? 0).toString()}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _navIcon(IconData iconData, int index) {
    final selected = _selectedIndex == index;
    final bgColor = selected ? Theme.of(context).colorScheme.primary : Colors.transparent;
    final iconColor = selected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: 20, color: iconColor),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        if (_selectedIndex == index) return;
        setState(() => _selectedIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFF2F4B5F) : Colors.white,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFF2F4B5F) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Custom Bottom Navigation (if any) ---
  // If you have a custom nav bar Row, restore the original items:
  // children: [
  //   _buildNavItem(Icons.home, "Home", 0),
  //   _buildNavItem(Icons.favorite, "Favorites", 1),
  //   _buildNavItem(Icons.calendar_today, "Bookings", 2),
  //   _buildNavItem(Icons.person, "Profile", 3),
  // ],
}

class _GuestProfileView extends StatelessWidget {
  const _GuestProfileView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 72, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            const SizedBox(height: 12),
            Text('You are browsing as a guest', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Some features like editing your profile require an account. Please login to access them.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/login');
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profile;
  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile['name'] ?? '');
    _phoneController = TextEditingController(text: widget.profile['phone'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final profileHasId = widget.profile.containsKey('id') && 
        (widget.profile['id'] != null && 
         widget.profile['id'].toString().isNotEmpty);

    bool success = false;
    if (profileHasId) {
      success = await UserService().updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
    } else {
      try {
        await UserService().createUserIfNotExists(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );
        success = true;
      } catch (_) {
        success = false;
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController, 
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController, 
              decoration: const InputDecoration(labelText: 'Phone'), 
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _save, 
              child: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ) 
                : const Text('Save'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}