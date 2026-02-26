import 'package:cloud_firestore/cloud_firestore.dart';

/// Model to track owner onboarding progress and status
class OwnerOnboardingModel {
  final String userId;
  String onboardingStatus; // "not_started" | "in_progress" | "completed"
  List<String> completedScreens; // ["screen_1", "screen_2", "screen_3"]
  bool propertyDetailsCompleted;
  bool propertiesAdded;
  String? activeRole; // "null" | "farmhouse" | "cOwner"
  String verificationStatus; // "pending_verification" | "verified" | "rejected"
  bool emailVerificationSent;
  bool emailVerified;
  DateTime? createdAt;
  DateTime? updatedAt;

  OwnerOnboardingModel({
    required this.userId,
    this.onboardingStatus = "not_started",
    this.completedScreens = const [],
    this.propertyDetailsCompleted = false,
    this.propertiesAdded = false,
    this.activeRole,
    this.verificationStatus = "pending_verification",
    this.emailVerificationSent = false,
    this.emailVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Check if a specific screen has been completed
  bool isScreenCompleted(String screenName) {
    return completedScreens.contains(screenName);
  }

  /// Mark a screen as completed
  void markScreenCompleted(String screenName) {
    if (!completedScreens.contains(screenName)) {
      completedScreens = [...completedScreens, screenName];
    }
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'onboarding_status': onboardingStatus,
      'completed_screens': completedScreens,
      'property_details_completed': propertyDetailsCompleted,
      'properties_added': propertiesAdded,
      'activeRole': activeRole,
      'verification_status': verificationStatus,
      'email_verification_sent': emailVerificationSent,
      'email_verified': emailVerified,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create from Firestore document
  factory OwnerOnboardingModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return OwnerOnboardingModel(
      userId: snapshot.id,
      onboardingStatus: data['onboarding_status'] ?? 'not_started',
      completedScreens: List<String>.from(data['completed_screens'] ?? []),
      propertyDetailsCompleted: data['property_details_completed'] ?? false,
      propertiesAdded: data['properties_added'] ?? false,
      activeRole: data['activeRole'],
      verificationStatus: data['verification_status'] ?? 'pending_verification',
      emailVerificationSent: data['email_verification_sent'] ?? false,
      emailVerified: data['email_verified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Factory constructor for initial creation
  factory OwnerOnboardingModel.empty(String userId) {
    return OwnerOnboardingModel(
      userId: userId,
      onboardingStatus: "not_started",
      completedScreens: [],
      propertyDetailsCompleted: false,
      propertiesAdded: false,
      activeRole: null,
      verificationStatus: "pending_verification",
      emailVerificationSent: false,
      emailVerified: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
