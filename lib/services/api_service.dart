import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/place.dart';
import '../models/notification_item.dart';
import '../models/trip_plan.dart';

class ApiService {
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'current_user';

  static Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  static Future<void> saveAuthSession(UserModel user, String token) async {
    final prefs = await _getPrefs();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<String?> getToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(_tokenKey);
  }

  static Future<UserModel?> getCurrentUser() async {
    final prefs = await _getPrefs();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(userJson));
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearAuthSession() async {
    final prefs = await _getPrefs();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ==========================================
  // AUTHENTICATION
  // ==========================================
  static Future<UserModel> login(String username, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Users/Login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final user = UserModel.fromJson(data);
      if (user.token != null) {
        await saveAuthSession(user, user.token!);
      }
      return user;
    } else {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ');
    }
  }

  static Future<UserModel> register(
    String username,
    String password,
    String email,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Users/Register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final user = UserModel.fromJson(data);
      if (user.token != null) {
        await saveAuthSession(user, user.token!);
      }
      return user;
    } else {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['message'] ?? 'สมัครสมาชิกไม่สำเร็จ');
    }
  }

  // ==========================================
  // PLACES
  // ==========================================
  static Future<List<PlaceModel>> getPlaces() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Places');
    final response = await http.get(url, headers: await _authHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
      return list
          .whereType<Map<String, dynamic>>()
          .map((item) => PlaceModel.fromJson(item))
          .toList();
    } else {
      throw Exception('ไม่สามารถดึงข้อมูลสถานที่ได้');
    }
  }

  static Future<PlaceModel?> getPlaceById(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Places/$id');
    final response = await http.get(url, headers: await _authHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return PlaceModel.fromJson(data);
    }
    return null;
  }

  // ==========================================
  // FAVORITES
  // ==========================================
  static Future<List<int>> getUserFavoritePlaceIds(int userId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Favorites/User/$userId');
    final response = await http.get(url, headers: await _authHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
      return list
          .map<int>((item) => (item['placeId'] is int ? item['placeId'] : int.tryParse(item['placeId'].toString())) ?? 0)
          .where((id) => id > 0)
          .toList();
    }
    return [];
  }

  static Future<bool> addFavorite(int userId, int placeId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Favorites');
    final response = await http.post(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({
        'userId': userId,
        'placeId': placeId,
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> removeFavorite(int userId, int placeId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Favorites/User/$userId/Place/$placeId');
    final response = await http.delete(url, headers: await _authHeaders());
    return response.statusCode == 204 || response.statusCode == 200;
  }

  // ==========================================
  // NOTIFICATIONS
  // ==========================================
  static Future<List<NotificationItemModel>> getNotifications() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Notifications');
    final response = await http.get(url, headers: await _authHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
      return list
          .whereType<Map<String, dynamic>>()
          .map((item) => NotificationItemModel.fromJson(item))
          .toList();
    }
    return [];
  }

  static Future<int> getUnreadNotificationCount() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Notifications/unread-count');
    final response = await http.get(url, headers: await _authHeaders());

    if (response.statusCode == 200) {
      return int.tryParse(response.body.trim()) ?? 0;
    }
    return 0;
  }

  static Future<void> markNotificationAsRead(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Notifications/$id/read');
    await http.put(url, headers: await _authHeaders());
  }

  static Future<void> markAllNotificationsAsRead() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Notifications/read-all');
    await http.put(url, headers: await _authHeaders());
  }

  static Future<bool> deleteNotification(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Notifications/$id');
    final response = await http.delete(url, headers: await _authHeaders());
    return response.statusCode == 204 || response.statusCode == 200;
  }

  // ==========================================
  // TRIP PLANS
  // ==========================================
  static Future<List<TripPlanModel>> getUserTripPlans(int userId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/TripPlans/User/$userId');
    final response = await http.get(url, headers: await _authHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
      return list
          .whereType<Map<String, dynamic>>()
          .map((item) => TripPlanModel.fromJson(item))
          .toList();
    }
    return [];
  }

  static Future<TripPlanModel?> getTripPlanById(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/TripPlans/$id');
    final response = await http.get(url, headers: await _authHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return TripPlanModel.fromJson(data);
    }
    return null;
  }

  static Future<TripPlanModel?> createTripPlan({
    required int userId,
    required String planName,
    required DateTime startDate,
    required DateTime endDate,
    int memberCount = 1,
    double budgetAmount = 0.0,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/TripPlans');
    final response = await http.post(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({
        'userId': userId,
        'planName': planName,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'memberCount': memberCount,
        'budgetAmount': budgetAmount,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return TripPlanModel.fromJson(data);
    }
    return null;
  }

  static Future<bool> updateTripPlan(int id, Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/TripPlans/$id');
    final response = await http.put(
      url,
      headers: await _authHeaders(),
      body: jsonEncode(data),
    );
    return response.statusCode == 204 || response.statusCode == 200;
  }

  static Future<bool> deleteTripPlan(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/TripPlans/$id');
    final response = await http.delete(url, headers: await _authHeaders());
    return response.statusCode == 204 || response.statusCode == 200;
  }

  // ==========================================
  // TRIP PLAN ITEMS
  // ==========================================
  static Future<TripPlanItemModel?> createTripPlanItem({
    required int tripPlanId,
    required int placeId,
    int dayNumber = 1,
    int sequence = 0,
    String? startTime,
    String? endTime,
    double? estimatedCost,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/TripPlanItems');
    final response = await http.post(
      url,
      headers: await _authHeaders(),
      body: jsonEncode({
        'tripPlanId': tripPlanId,
        'placeId': placeId,
        'dayNumber': dayNumber,
        'sequence': sequence,
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (estimatedCost != null) 'estimatedCost': estimatedCost,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return TripPlanItemModel.fromJson(data);
    }
    return null;
  }

  static Future<bool> updateTripPlanItem(int id, Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/TripPlanItems/$id');
    final response = await http.put(
      url,
      headers: await _authHeaders(),
      body: jsonEncode(data),
    );
    return response.statusCode == 204 || response.statusCode == 200;
  }

  static Future<bool> deleteTripPlanItem(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/TripPlanItems/$id');
    final response = await http.delete(url, headers: await _authHeaders());
    return response.statusCode == 204 || response.statusCode == 200;
  }
}
