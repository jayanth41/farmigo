import 'package:flutter/material.dart';
import '../navigation/app_routes.dart';
import '../widgets/app_drawer.dart';

/// Enum for bottom navigation tabs.
enum BottomTab { home, favorites, bookings, profile }

/// Maps BottomTab to AppRoutes for easy lookup.
const Map<BottomTab, String> _bottomTabRoute = {
  BottomTab.home: AppRoutes.home,
  BottomTab.favorites: AppRoutes.favorites,
  BottomTab.bookings: AppRoutes.bookings,
  BottomTab.profile: AppRoutes.profile,
};

/// MainScaffold encapsulates AppBar, Drawer and BottomNavigation with an
/// IndexedStack body to preserve state between tabs.
class MainScaffold extends StatefulWidget {
  /// The set of widgets to render for the bottom tabs. Must contain exactly
  /// four entries in the following order: home, favorites, bookings, profile.
  final Map<BottomTab, Widget> tabs;

  final bool isOwner;

  /// Optional initial tab shown when the scaffold first appears.
  final BottomTab initialTab;

  const MainScaffold({
    super.key,
    required this.tabs,
    this.initialTab = BottomTab.home,
    this.isOwner = false,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late BottomTab _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  int get _selectedIndex => BottomTab.values.indexOf(_selectedTab);

  void _selectTab(BottomTab tab) {
    if (_selectedTab == tab) return; // avoid duplicate navigation
    setState(() => _selectedTab = tab);
  }

  /// Handle drawer selections. If the label maps to one of the main tabs,
  /// switch the IndexedStack index. Otherwise navigate to the named route
  /// using pushReplacement to avoid stacking screens.
  void _onDrawerItemSelected(String label) {
    final route = AppRoutes.labelToRoute[label];
    if (route == null) return;

    // If route corresponds to one of the bottom tabs, switch tabs instead of
    // performing a new navigation. This preserves state in the IndexedStack.
    final bottomEntry = _bottomTabRoute.entries.firstWhere(
      (e) => e.value == route,
      orElse: () => const MapEntry(BottomTab.home, ''),
    );

    if (bottomEntry.value == route) {
      _selectTab(bottomEntry.key);
      return; // drawer will already be closed by the drawer item
    }

    // For non-tab routes, replace the current route so back button won't
    // duplicate screens.
    final navigator = Navigator.of(context);
    Future.microtask(() {
      if (!mounted) return;
      navigator.pushReplacementNamed(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    final children = BottomTab.values
        .map((t) => widget.tabs[t] ?? const SizedBox.shrink())
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        leadingWidth: 70,
      ),
      drawer: AppDrawer(
        activeItem: AppRoutes.routeToLabel(_bottomTabRoute[_selectedTab]),
        onItemSelected: _onDrawerItemSelected,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: children,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (idx) => _selectTab(BottomTab.values[idx]),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(widget.isOwner ? Icons.star : Icons.favorite_border),
            label: widget.isOwner ? 'Reviews' : 'Favorites',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Bookings'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
