import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/place.dart';
import '../models/trip_plan.dart';
import '../services/api_service.dart';

class TripTimelineItem {
  final TripPlanItemModel rawItem;
  final PlaceModel place;
  final int stepIndex;
  final double distanceKm;
  final int travelMinutes;
  final String arriveTime;
  final String leaveTime;
  final String operatingStatus; // 'open', 'closed', 'warning', 'hotel'
  final String statusMessage;

  TripTimelineItem({
    required this.rawItem,
    required this.place,
    required this.stepIndex,
    required this.distanceKm,
    required this.travelMinutes,
    required this.arriveTime,
    required this.leaveTime,
    required this.operatingStatus,
    required this.statusMessage,
  });
}

class TripProvider extends ChangeNotifier {
  List<TripPlanModel> _tripPlans = [];
  TripPlanModel? _currentPlan;
  int? _tripPlanId;
  bool _isLoading = false;
  int _activeStep = 0;
  String _tripStartTime = '08:00';
  double? _userLatitude;
  double? _userLongitude;
  bool _isUsingGps = false;

  List<TripPlanModel> get tripPlans => _tripPlans;
  TripPlanModel? get currentPlan => _currentPlan;
  int? get tripPlanId => _tripPlanId;
  bool get isLoading => _isLoading;
  int get activeStep => _activeStep;
  String get tripStartTime => _tripStartTime;
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;
  bool get isUsingGps => _isUsingGps;
  int get itemCount => _currentPlan?.items.length ?? 0;
  bool get isTripCompleted =>
      itemCount > 0 && _activeStep >= itemCount;

  void toggleGps({double? lat, double? lng}) {
    if (_isUsingGps) {
      _isUsingGps = false;
      _userLatitude = null;
      _userLongitude = null;
    } else {
      _isUsingGps = true;
      // Default to user's real or simulated location (Kanchanaburi center: 14.0228, 99.5328)
      _userLatitude = lat ?? 14.0228;
      _userLongitude = lng ?? 99.5328;
    }
    notifyListeners();
  }

  void setUserLocation(double lat, double lng) {
    _userLatitude = lat;
    _userLongitude = lng;
    _isUsingGps = true;
    notifyListeners();
  }

  void setStartTime(String time) {
    _tripStartTime = time;
    notifyListeners();
  }

  void handleCheckIn(int step) {
    if (step >= _activeStep) {
      _activeStep = step + 1;
      notifyListeners();
    }
  }

  void undoCheckIn() {
    if (_activeStep > 0) {
      _activeStep--;
      notifyListeners();
    }
  }

  void resetCheckIn() {
    _activeStep = 0;
    notifyListeners();
  }

  Future<void> loadUserTrips(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final plans = await ApiService.getUserTripPlans(userId);
      _tripPlans = plans;

      if (plans.isNotEmpty) {
        // Keep current plan if exists, else first
        final targetId = _tripPlanId ?? plans.first.id;
        final match = plans.firstWhere(
          (p) => p.id == targetId,
          orElse: () => plans.first,
        );
        _tripPlanId = match.id;
        _currentPlan = await ApiService.getTripPlanById(match.id);
      } else {
        _tripPlanId = null;
        _currentPlan = null;
      }
    } catch (e) {
      if (kDebugMode) print('Error loading user trips: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> switchTrip(int planId) async {
    _tripPlanId = planId;
    _isLoading = true;
    _activeStep = 0;
    notifyListeners();

    try {
      _currentPlan = await ApiService.getTripPlanById(planId);
    } catch (e) {
      if (kDebugMode) print('Error switching trip: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createNewTrip({
    required int userId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final created = await ApiService.createTripPlan(
        userId: userId,
        planName: name,
        startDate: startDate,
        endDate: endDate,
      );
      if (created != null) {
        await loadUserTrips(userId);
        await switchTrip(created.id);
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('Error creating trip: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> deleteCurrentTrip(int userId) async {
    if (_tripPlanId == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final ok = await ApiService.deleteTripPlan(_tripPlanId!);
      if (ok) {
        _tripPlanId = null;
        _currentPlan = null;
        _activeStep = 0;
        await loadUserTrips(userId);
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('Error deleting trip: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> addPlaceToTrip(int userId, PlaceModel place) async {
    // If no trip exists, create default trip
    if (_tripPlanId == null) {
      final now = DateTime.now();
      final defaultPlan = await ApiService.createTripPlan(
        userId: userId,
        planName: 'ทริปท่องเที่ยวกาญจนบุรี',
        startDate: now,
        endDate: now.add(const Duration(days: 1)),
      );
      if (defaultPlan != null) {
        _tripPlanId = defaultPlan.id;
        _currentPlan = defaultPlan;
      } else {
        return false;
      }
    }

    final currentItems = _currentPlan?.items ?? [];
    final nextSeq = currentItems.length;

    try {
      final item = await ApiService.createTripPlanItem(
        tripPlanId: _tripPlanId!,
        placeId: place.id,
        sequence: nextSeq,
        estimatedCost: place.entranceFee > 0
            ? place.entranceFee
            : (place.placeType == 'Accommodation' ? 1200 : 150),
      );

      if (item != null) {
        _currentPlan = await ApiService.getTripPlanById(_tripPlanId!);
        notifyListeners();
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('Error adding place to trip: $e');
    }
    return false;
  }

  Future<void> removeTripItem(int itemId) async {
    try {
      await ApiService.deleteTripPlanItem(itemId);
      if (_tripPlanId != null) {
        _currentPlan = await ApiService.getTripPlanById(_tripPlanId!);
        if (_activeStep > 0 && _activeStep > itemCount) {
          _activeStep = itemCount;
        }
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('Error removing item: $e');
    }
  }

  Future<void> updateItemCost(int itemId, double newCost) async {
    try {
      await ApiService.updateTripPlanItem(itemId, {
        'estimatedCost': newCost,
      });
      if (_tripPlanId != null) {
        _currentPlan = await ApiService.getTripPlanById(_tripPlanId!);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('Error updating item cost: $e');
    }
  }

  Future<void> reorderItem(int oldIndex, int newIndex) async {
    if (_currentPlan == null) return;
    final items = List<TripPlanItemModel>.from(_currentPlan!.items);
    if (oldIndex < 0 || oldIndex >= items.length || newIndex < 0 || newIndex >= items.length) return;

    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);

    // Update sequences
    for (int i = 0; i < items.length; i++) {
      await ApiService.updateTripPlanItem(items[i].id, {'sequence': i});
    }

    if (_tripPlanId != null) {
      _currentPlan = await ApiService.getTripPlanById(_tripPlanId!);
      notifyListeners();
    }
  }

  // ==========================================
  // CALCULATIONS & SMART TIMELINE
  // ==========================================
  static double getDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371.0; // Earth radius in km
    final double dLat = (lat2 - lat1) * pi / 180.0;
    final double dLon = (lon2 - lon1) * pi / 180.0;
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) * cos(lat2 * pi / 180.0) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  List<TripTimelineItem> get timelineItems {
    if (_currentPlan == null || _currentPlan!.items.isEmpty) return [];

    final result = <TripTimelineItem>[];
    final parts = _tripStartTime.split(':');
    int currentMinutes =
        (int.tryParse(parts[0]) ?? 8) * 60 + (int.tryParse(parts[1]) ?? 0);

    for (int i = 0; i < _currentPlan!.items.length; i++) {
      final item = _currentPlan!.items[i];
      final place = item.place;
      if (place == null) continue;

      double dist = 0.0;
      int travelMins = 0;

      if (i > 0) {
        final prevPlace = _currentPlan!.items[i - 1].place;
        if (prevPlace != null) {
          final lat1 = prevPlace.latitude;
          final lon1 = prevPlace.longitude;
          final lat2 = place.latitude;
          final lon2 = place.longitude;
          dist = getDistanceKm(lat1, lon1, lat2, lon2);
          travelMins = max(5, (dist * 1.3).round());
        }
      } else if (_isUsingGps && _userLatitude != null && _userLongitude != null) {
        dist = getDistanceKm(_userLatitude!, _userLongitude!, place.latitude, place.longitude);
        travelMins = max(5, (dist * 1.3).round());
      }

      currentMinutes += travelMins;
      final arriveMins = currentMinutes;

      // Stay duration
      int stayMins = 90;
      if (place.placeType == 'Restaurant') {
        stayMins = 60;
      } else if (place.placeType == 'Accommodation') {
        stayMins = 600; // Overnight
      }

      currentMinutes += stayMins;
      final leaveMins = currentMinutes;

      // Format Times
      final arriveTimeStr = _minsToStr(arriveMins);
      final leaveTimeStr = place.placeType == 'Accommodation'
          ? 'พักค้างคืน'
          : _minsToStr(leaveMins);

      // Status check
      String status = 'open';
      String message = 'เปิดบริการตามปกติ';

      if (place.placeType == 'Accommodation') {
        status = 'hotel';
        message = 'บริการเช็คอินตลอด 24 ชม.';
      } else if (place.openingTime != null && place.closingTime != null) {
        final openMins = _timeStrToMins(place.openingTime!);
        final closeMins = _timeStrToMins(place.closingTime!);

        if (arriveMins % 1440 >= closeMins) {
          status = 'closed';
          message = 'ปิดทำการแล้ว (ปิด ${place.closingTime} น.)';
        } else if (arriveMins % 1440 < openMins) {
          status = 'warning';
          message = 'ยังไม่เปิด (เปิด ${place.openingTime} น.)';
        } else if (leaveMins % 1440 > closeMins) {
          status = 'warning';
          message = 'ปิดก่อนเที่ยวเสร็จ (ปิด ${place.closingTime} น.)';
        }
      }

      result.add(TripTimelineItem(
        rawItem: item,
        place: place,
        stepIndex: i,
        distanceKm: dist,
        travelMinutes: travelMins,
        arriveTime: arriveTimeStr,
        leaveTime: leaveTimeStr,
        operatingStatus: status,
        statusMessage: message,
      ));
    }

    return result;
  }

  double get attractionCost => _currentPlan?.items
          .where((i) => i.place?.placeType == 'Attraction')
          .fold<double>(0.0, (sum, i) => sum + i.estimatedCost) ??
      0.0;

  double get restaurantCost => _currentPlan?.items
          .where((i) => i.place?.placeType == 'Restaurant')
          .fold<double>(0.0, (sum, i) => sum + i.estimatedCost) ??
      0.0;

  double get accommodationCost => _currentPlan?.items
          .where((i) => i.place?.placeType == 'Accommodation')
          .fold<double>(0.0, (sum, i) => sum + i.estimatedCost) ??
      0.0;

  double get totalCost =>
      attractionCost + restaurantCost + accommodationCost;

  String _minsToStr(int mins) {
    final h = (mins % 1440) ~/ 60;
    final m = mins % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} น.';
  }

  int _timeStrToMins(String timeStr) {
    try {
      final p = timeStr.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    } catch (_) {
      return 0;
    }
  }
}
