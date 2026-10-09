import 'place.dart';

class TripPlanModel {
  final int id;
  final int userId;
  final String planName;
  final DateTime startDate;
  final DateTime endDate;
  final int memberCount;
  final double budgetAmount;
  final DateTime createdAt;
  final List<TripPlanItemModel> items;

  TripPlanModel({
    required this.id,
    required this.userId,
    required this.planName,
    required this.startDate,
    required this.endDate,
    this.memberCount = 1,
    this.budgetAmount = 0.0,
    required this.createdAt,
    this.items = const [],
  });

  factory TripPlanModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<TripPlanItemModel> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .whereType<Map>()
          .map((i) => TripPlanItemModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
      parsedItems.sort((a, b) => a.sequence.compareTo(b.sequence));
    }

    return TripPlanModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['userId'] is int
          ? json['userId']
          : int.tryParse(json['userId']?.toString() ?? '0') ?? 0,
      planName: json['planName'] ?? 'ทริปไม่มีชื่อ',
      startDate: json['startDate'] != null
          ? (DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now())
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? (DateTime.tryParse(json['endDate'].toString()) ?? DateTime.now())
          : DateTime.now(),
      memberCount: json['memberCount'] is int ? json['memberCount'] : 1,
      budgetAmount: json['budgetAmount'] != null
          ? (double.tryParse(json['budgetAmount'].toString()) ?? 0.0)
          : 0.0,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      items: parsedItems,
    );
  }
}

class TripPlanItemModel {
  final int id;
  final int tripPlanId;
  final int placeId;
  final int dayNumber;
  final int sequence;
  final String? startTime;
  final String? endTime;
  final double estimatedCost;
  final PlaceModel? place;

  TripPlanItemModel({
    required this.id,
    required this.tripPlanId,
    required this.placeId,
    this.dayNumber = 1,
    this.sequence = 0,
    this.startTime,
    this.endTime,
    this.estimatedCost = 0.0,
    this.place,
  });

  factory TripPlanItemModel.fromJson(Map<String, dynamic> json) {
    PlaceModel? parsedPlace;
    if (json['place'] is Map) {
      parsedPlace = PlaceModel.fromJson(Map<String, dynamic>.from(json['place'] as Map));
    }

    return TripPlanItemModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      tripPlanId: json['tripPlanId'] is int
          ? json['tripPlanId']
          : int.tryParse(json['tripPlanId']?.toString() ?? '0') ?? 0,
      placeId: json['placeId'] is int
          ? json['placeId']
          : int.tryParse(json['placeId']?.toString() ?? '0') ?? 0,
      dayNumber: json['dayNumber'] is int ? json['dayNumber'] : 1,
      sequence: json['sequence'] is int ? json['sequence'] : 0,
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      estimatedCost: json['estimatedCost'] != null
          ? (double.tryParse(json['estimatedCost'].toString()) ?? 0.0)
          : (parsedPlace?.entranceFee ?? 0.0),
      place: parsedPlace,
    );
  }
}
