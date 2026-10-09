class NotificationItemModel {
  final int id;
  final String title;
  final String message;
  final int type;
  final bool isRead;
  final DateTime createdAt;
  final int? relatedPlaceId;

  NotificationItemModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.relatedPlaceId,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] is int ? json['type'] : (int.tryParse(json['type']?.toString() ?? '0') ?? 0),
      isRead: json['isRead'] == true,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      relatedPlaceId: json['relatedPlaceId'] is int
          ? json['relatedPlaceId']
          : int.tryParse(json['relatedPlaceId']?.toString() ?? ''),
    );
  }
}
