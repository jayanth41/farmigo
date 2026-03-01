class ReviewModel {
  final String id;
  final String propertyId;
  final String userId;
  final String userName;
  final String userImage;
  final int rating;
  final String reviewText;
  final List<String> imageUrls;
  final DateTime createdAt;
  final int helpfulCount;

  ReviewModel({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.rating,
    required this.reviewText,
    this.imageUrls = const [],
    required this.createdAt,
    this.helpfulCount = 0,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      propertyId: json['propertyId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userImage: json['userImage'] ?? '',
      rating: json['rating'] ?? 0,
      reviewText: json['reviewText'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      helpfulCount: json['helpfulCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'rating': rating,
      'reviewText': reviewText,
      'imageUrls': imageUrls,
      'createdAt': createdAt.toIso8601String(),
      'helpfulCount': helpfulCount,
    };
  }
}
