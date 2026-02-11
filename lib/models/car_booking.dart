import 'package:cloud_firestore/cloud_firestore.dart';

class CarBooking {
  final String? id;
  final String carId;
  final String carName;
  final String userId;
  final String ownerId;
  final DateTime startDate;
  final DateTime endDate;
  final int? hours; // Only for same-day bookings
  final int pricePerDay;
  final int? weekendPrice;
  final int? hourlyPrice;
  final int? driverHourlyCharge;
  final bool driverRequested;
  final int weekdayTotal;
  final int weekendTotal;
  final int driverTotal;
  final int hourlyTotal;
  final int finalTotal;
  final String status; // 'pending', 'confirmed', 'cancelled'
  final DateTime createdAt;
  final String? guestFcmToken;

  CarBooking({
    this.id,
    required this.carId,
    required this.carName,
    required this.userId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    this.hours,
    required this.pricePerDay,
    this.weekendPrice,
    this.hourlyPrice,
    this.driverHourlyCharge,
    required this.driverRequested,
    required this.weekdayTotal,
    required this.weekendTotal,
    required this.driverTotal,
    required this.hourlyTotal,
    required this.finalTotal,
    this.status = 'confirmed',
    required this.createdAt,
    this.guestFcmToken,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'carId': carId,
      'carName': carName,
      'userId': userId,
      'ownerId': ownerId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'hours': hours,
      'pricePerDay': pricePerDay,
      'weekendPrice': weekendPrice,
      'hourlyPrice': hourlyPrice,
      'driverHourlyCharge': driverHourlyCharge,
      'driverRequested': driverRequested,
      'weekdayTotal': weekdayTotal,
      'weekendTotal': weekendTotal,
      'driverTotal': driverTotal,
      'hourlyTotal': hourlyTotal,
      'finalTotal': finalTotal,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (guestFcmToken != null) 'guestFcmToken': guestFcmToken,
    };
  }

  /// Create from Firestore document
  factory CarBooking.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CarBooking(
      id: doc.id,
      carId: data['carId'] ?? '',
      carName: data['carName'] ?? '',
      userId: data['userId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      hours: data['hours'] as int?,
      pricePerDay: data['pricePerDay'] ?? 0,
      weekendPrice: data['weekendPrice'] as int?,
      hourlyPrice: data['hourlyPrice'] as int?,
      driverHourlyCharge: data['driverHourlyCharge'] as int?,
      driverRequested: data['driverRequested'] ?? false,
      weekdayTotal: data['weekdayTotal'] ?? 0,
      weekendTotal: data['weekendTotal'] ?? 0,
      driverTotal: data['driverTotal'] ?? 0,
      hourlyTotal: data['hourlyTotal'] ?? 0,
      finalTotal: data['finalTotal'] ?? 0,
      status: data['status'] ?? 'confirmed',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      guestFcmToken: data['guestFcmToken'] as String?,
    );
  }

  /// Get number of days in booking
  int get numberOfDays {
    return endDate.difference(startDate).inDays;
  }

  /// Check if booking spans multiple days
  bool get isSameDayBooking {
    return startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day;
  }
}
