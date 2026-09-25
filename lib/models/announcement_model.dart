class AnnouncementModel {
  final int id;
  final String title;
  final String content;
  final String? imageUrl;
  final String targetRole;
  final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.targetRole,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      imageUrl: json['imageUrl'],
      targetRole: json['targetRole'] ?? 'ALL',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
