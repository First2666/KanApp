import '../config/api_config.dart';

class PlaceImageModel {
  final int id;
  final String imageUrl;
  final bool isPrimary;

  PlaceImageModel({
    required this.id,
    required this.imageUrl,
    this.isPrimary = false,
  });

  String get fullUrl {
    if (imageUrl.contains('localhost:5088')) {
      return imageUrl.replaceFirst(RegExp(r'https?://localhost:5088'), ApiConfig.serverBaseUrl);
    }
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    final cleanPath = imageUrl.startsWith('/') ? imageUrl : '/$imageUrl';
    return '${ApiConfig.serverBaseUrl}$cleanPath';
  }

  factory PlaceImageModel.fromJson(Map<String, dynamic> json) {
    return PlaceImageModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      imageUrl: json['imageUrl'] ?? json['url'] ?? '',
      isPrimary: json['isPrimary'] == true,
    );
  }
}

class PlaceModel {
  final int id;
  final String name;
  final String description;
  final String placeType; // "Attraction", "Restaurant", "Accommodation"
  final double latitude;
  final double longitude;
  final double entranceFee;
  final String? openingTime;
  final String? closingTime;
  final String? address;
  final List<PlaceImageModel> images;
  final List<String> categories;
  final List<String> tags;

  PlaceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.placeType,
    required this.latitude,
    required this.longitude,
    required this.entranceFee,
    this.openingTime,
    this.closingTime,
    this.address,
    required this.images,
    required this.categories,
    required this.tags,
  });

  String get primaryImageUrl {
    if (images.isEmpty) {
      return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800';
    }
    final primary = images.firstWhere(
      (img) => img.isPrimary,
      orElse: () => images.first,
    );
    return primary.fullUrl;
  }

  String get typeLabel {
    switch (placeType) {
      case 'Attraction':
        return 'สถานที่ท่องเที่ยว';
      case 'Restaurant':
        return 'ร้านอาหาร / คาเฟ่';
      case 'Accommodation':
        return 'ที่พัก / โรงแรม';
      default:
        return 'สถานที่';
    }
  }

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] as List? ?? [];
    final imageList = rawImages
        .whereType<Map>()
        .map((img) => PlaceImageModel.fromJson(Map<String, dynamic>.from(img)))
        .toList();

    final rawCats = json['categoryNames'] as List? ?? [];
    final catList = rawCats.map((c) => c.toString()).toList();

    final rawTags = json['tagNames'] as List? ?? [];
    final tagList = rawTags.map((t) => t.toString()).toList();

    String? locAddress;
    if (json['location'] is Map) {
      locAddress = json['location']['address']?.toString();
    }

    String pType = json['placeType']?.toString() ?? '';
    if (pType.isEmpty && json['\$type'] != null) {
      final t = json['\$type'].toString().toLowerCase();
      if (t.contains('restaurant')) {
        pType = 'Restaurant';
      } else if (t.contains('accommodation')) {
        pType = 'Accommodation';
      } else {
        pType = 'Attraction';
      }
    }
    if (pType.isEmpty) pType = 'Attraction';

    double fee = 0.0;
    if (json['entranceFee'] is num) {
      fee = (json['entranceFee'] as num).toDouble();
    } else if (json['pricePerNight'] is num) {
      fee = (json['pricePerNight'] as num).toDouble();
    } else if (json['averageCost'] is num) {
      fee = (json['averageCost'] as num).toDouble();
    }

    return PlaceModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      placeType: pType,
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : 0.0,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : 0.0,
      entranceFee: fee,
      openingTime: json['openingTime']?.toString(),
      closingTime: json['closingTime']?.toString(),
      address: locAddress ?? json['address']?.toString() ?? 'กาญจนบุรี',
      images: imageList,
      categories: catList,
      tags: tagList,
    );
  }
}
