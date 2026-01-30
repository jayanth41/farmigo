import 'package:flutter/material.dart';
import '../widgets/properties_grid.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';

class AllPropertiesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> properties;
  const AllPropertiesScreen({super.key, required this.properties});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('All farmhouses', style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: ListView(
          children: [
            PropertiesGrid(properties: properties),
          ],
        ),
      ),
    );
  }
}
