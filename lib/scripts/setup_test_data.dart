// Run this script to populate test data in Firebase:
// dart lib/scripts/setup_test_data.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:skybase/utils/test_data_helper.dart';
import 'firebase_options.dart';

Future<void> main() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('🔄 Setting up test data...\n');

    // Option 1: Create multiple test properties
    print('1️⃣ Creating 5 test properties...');
    final propertyIds = await TestDataHelper.createMultipleTestProperties();

    if (propertyIds.isNotEmpty) {
      print('\n✅ Test data created successfully!');
      print('\n🔗 Use these property IDs to test the app:');
      for (int i = 0; i < propertyIds.length; i++) {
        print('   ${i + 1}. ${propertyIds[i]}');
      }

      print('\n📱 How to test:');
      print('   1. Copy the first property ID above');
      print('   2. Pass it to PropertyDetailsScreen when navigating');
      print('   3. The screen should now load properly\n');
    } else {
      print('\n❌ Failed to create test data');
      print('   Check Firebase connection and Firestore rules\n');
    }

    // Print all properties for verification
    print('📋 Current properties in Firestore:');
    await TestDataHelper.printAllProperties();

    exit(0);
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}
