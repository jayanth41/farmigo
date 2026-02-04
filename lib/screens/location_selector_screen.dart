import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/location_controller.dart';

class LocationSelectorScreen extends StatefulWidget {
  const LocationSelectorScreen({super.key});

  @override
  State<LocationSelectorScreen> createState() => _LocationSelectorScreenState();
}

class _LocationSelectorScreenState extends State<LocationSelectorScreen> with SingleTickerProviderStateMixin {
  final LocationController locCtrl = Get.find<LocationController>();
  final TextEditingController _search = TextEditingController();
  late AnimationController _anim;

  final List<String> popularCities = [
    'Mumbai', 'Delhi', 'Bengaluru', 'Hyderabad', 'Chennai', 'Kolkata', 'Pune', 'Ahmedabad', 'Surat', 'Jaipur', 'Lucknow', 'Nagpur', 'Indore', 'Coimbatore', 'Visakhapatnam', 'Bhopal', 'Thiruvananthapuram', 'Kochi', 'Vadodara', 'Vijayawada'
  ];

  // Lightweight fallback city->state map for common cities
  final Map<String, String> _cityStates = {
    'Mumbai': 'Maharashtra',
    'Delhi': 'Delhi',
    'Bengaluru': 'Karnataka',
    'Hyderabad': 'Telangana',
    'Chennai': 'Tamil Nadu',
    'Kolkata': 'West Bengal',
    'Pune': 'Maharashtra',
    'Ahmedabad': 'Gujarat',
    'Surat': 'Gujarat',
    'Jaipur': 'Rajasthan',
    'Lucknow': 'Uttar Pradesh',
    'Nagpur': 'Maharashtra',
    'Indore': 'Madhya Pradesh',
    'Coimbatore': 'Tamil Nadu',
    'Visakhapatnam': 'Andhra Pradesh',
    'Bhopal': 'Madhya Pradesh',
    'Thiruvananthapuram': 'Kerala',
    'Kochi': 'Kerala',
    'Vadodara': 'Gujarat',
    'Vijayawada': 'Andhra Pradesh',
    'Anajpur': 'Telangana',
  };

  // A sample larger city list (can be extended)
  final List<String> allCities = [
    'Mumbai','Delhi','Bengaluru','Hyderabad','Chennai','Kolkata','Pune','Ahmedabad','Surat','Jaipur','Lucknow','Nagpur','Indore','Coimbatore','Visakhapatnam','Bhopal','Thiruvananthapuram','Kochi','Vadodara','Vijayawada','Nashik','Agra','Faridabad','Meerut','Rajkot','Kalyan','Vasai-Virar','Varanasi','Srinagar','Aurangabad','Dhanbad','Amritsar','Navi Mumbai','Ranchi','Howrah','Jabalpur','Gwalior','Jodhpur','Madurai','Raipur','Kota','Guwahati','Chandigarh','Dehradun','Shimla','Panaji','Dispur','Imphal','Shillong','Aizawl','Kohima','Agartala','Itanagar'
  ];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 240));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _search.dispose();
    super.dispose();
  }

  void _selectCity(String city) {
    final state = _cityStates[city] ?? locCtrl.selectedState.value;
    locCtrl.setLocation(city: city, state: state);
    Navigator.of(context).pop();
  }

  Future<void> _autoDetect() async {
    final res = await locCtrl.detectCurrentLocation();
    if (res != null) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location set to $res')));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not detect location')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          return Opacity(
            opacity: Curves.easeOut.transform(_anim.value),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Choose your city', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Search for your city',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _autoDetect,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Auto detect location'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        // open state selector if user wants
                        locCtrl.openStateSelector(context);
                      },
                      child: const Text('Change state'),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text('Popular cities', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: popularCities.map((c) {
                    return ActionChip(
                      label: Text(c),
                      onPressed: () => _selectCity(c),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('All cities', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: allCities.where((c) => c.toLowerCase().contains(_search.text.toLowerCase())).length,
                  itemBuilder: (context, idx) {
                    final filtered = allCities.where((c) => c.toLowerCase().contains(_search.text.toLowerCase())).toList();
                    final city = filtered[idx];
                    return ListTile(
                      title: Text(city),
                      onTap: () => _selectCity(city),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
