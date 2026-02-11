# Block Dates Feature - Implementation Complete ✅

## Summary
Successfully moved "Block Dates" functionality outside the "Add Vehicle" option in the car owner dashboard. Now appears as a separate button in the AppBar next to "+ Add Vehicle".

## Changes Made

### File: `lib/screens/car_owner_dashboard_new.dart`

#### **Change 1: Added "Block Dates" Button in AppBar**

**Location:** Lines 74-88 (AppBar actions)

**Added:**
```dart
Padding(
  padding: const EdgeInsets.all(4.0),
  child: ElevatedButton(
    onPressed: () {
      // Navigate to Block Dates Screen
      _showBlockDatesSheet(context);
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    ),
    child: const Text(
      'Block Dates',
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  ),
),
```

This button appears **BEFORE** the "+ Add Vehicle" button (orange color to distinguish it).

---

#### **Change 2: Added `_showBlockDatesSheet()` Method**

**Location:** After `_buildTabPill()` method (around line 202)

**Added:**
```dart
void _showBlockDatesSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => BlockDatesSheet(ownerId: _ownerId),
  );
}
```

---

#### **Change 3: Added `BlockDatesSheet` Widget Class**

**Location:** After `_CarOwnerDashboardState` class ends (around line 743+)

**Added:**
```dart
class BlockDatesSheet extends StatefulWidget {
  final String ownerId;

  const BlockDatesSheet({super.key, required this.ownerId});

  @override
  State<BlockDatesSheet> createState() => _BlockDatesSheetState();
}

class _BlockDatesSheetState extends State<BlockDatesSheet> {
  String? _selectedCarId;
  List<DateTime> _blockedDates = [];
  final List<Map<String, String>> _cars = [];

  @override
  void initState() {
    super.initState();
    _fetchUserCars();
  }

  Future<void> _fetchUserCars() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('cars')
          .where('ownerId', isEqualTo: widget.ownerId)
          .get();

      setState(() {
        _cars.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          _cars.add({
            'id': doc.id,
            'name': data['carName'] as String? ?? 'Unknown Car',
          });
        }
      });
    } catch (e) {
      debugPrint('Error fetching cars: $e');
    }
  }

  Future<void> _blockDates() async {
    if (_selectedCarId == null || _blockedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a car and dates')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('cars').doc(_selectedCarId).update({
        'blockedDates': FieldValue.arrayUnion(
          _blockedDates.map((date) => Timestamp.fromDate(date)).toList(),
        ),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dates blocked successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _selectDates() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _blockedDates.clear();
        DateTime current = picked.start;
        while (current.isBefore(picked.end) || current == picked.end) {
          _blockedDates.add(current);
          current = current.add(const Duration(days: 1));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Block Dates for Your Car',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // Car Selection
            const Text(
              'Select Car',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedCarId,
              isExpanded: true,
              hint: const Text('Choose a car'),
              items: _cars.map((car) {
                return DropdownMenuItem<String>(
                  value: car['id'],
                  child: Text(car['name'] ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCarId = value),
            ),
            const SizedBox(height: 16),

            // Date Selection
            const Text(
              'Select Dates to Block',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _selectDates,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _blockedDates.isEmpty
                    ? 'Pick dates'
                    : '${_blockedDates.length} days selected',
              ),
            ),
            if (_blockedDates.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_blockedDates.first.toString().split(' ')[0]} to ${_blockedDates.last.toString().split(' ')[0]}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_blockedDates.length} days',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _blockDates,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Block Dates'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
```

---

## Features

### Block Dates Sheet Includes:
1. **Car Selection** - Dropdown to select which car to block dates for
2. **Date Range Picker** - Select date range (365 days in future max)
3. **Visual Preview** - Shows selected date range and number of days
4. **Firestore Integration** - Saves blocked dates to car's `blockedDates` array using `arrayUnion`
5. **User Feedback** - Snackbar notifications for success/error states

### UI Layout:
- **AppBar Buttons** (Left to Right):
  - Notification Bell (existing)
  - 🟠 **Block Dates** (NEW - orange button)
  - ⬛ **+ Add Vehicle** (existing - black button)

---

## Compilation Status
✅ **No Errors** - File compiles successfully

---

## How It Works

1. User clicks **"Block Dates"** button in AppBar
2. Bottom sheet modal opens with `BlockDatesSheet` widget
3. User selects a car from dropdown
4. User selects date range using date picker
5. System shows preview of selected dates
6. User clicks "Block Dates" button to save
7. Dates are added to car's `blockedDates` array in Firestore
8. CarRentalsScreen will prevent booking on these dates (red color coding)

