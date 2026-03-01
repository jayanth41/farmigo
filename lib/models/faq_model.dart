class FAQModel {
  final String id;
  final String propertyId;
  final String question;
  final String answer;
  final int order;

  FAQModel({
    required this.id,
    required this.propertyId,
    required this.question,
    required this.answer,
    this.order = 0,
  });

  factory FAQModel.fromJson(Map<String, dynamic> json) {
    return FAQModel(
      id: json['id'] ?? '',
      propertyId: json['propertyId'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'question': question,
      'answer': answer,
      'order': order,
    };
  }
}
