class SurveyModel {
  final String lessonId;
  final String trainerId;
  final String memberId;
  final double rating; // 1-5 arası
  final String comment;

  SurveyModel({
    required this.lessonId,
    required this.trainerId,
    required this.memberId,
    required this.rating,
    required this.comment,
  });

  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'trainerId': trainerId,
    'rating': rating,
    'comment': comment,
  };
}
