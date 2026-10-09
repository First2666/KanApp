import 'package:flutter/foundation.dart';
import '../models/place.dart';
import '../services/api_service.dart';

class PlaceProvider extends ChangeNotifier {
  List<PlaceModel> _places = [];
  Set<int> _favoriteIds = {};
  bool _isLoading = false;
  String _selectedCategory = 'All'; // 'All', 'Attraction', 'Restaurant', 'Accommodation'
  String _searchQuery = '';

  List<PlaceModel> get places => _places;
  Set<int> get favoriteIds => _favoriteIds;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  List<PlaceModel> get filteredPlaces {
    return _places.where((p) {
      final matchesCategory =
          _selectedCategory == 'All' || p.placeType == _selectedCategory;
      final matchesQuery = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.address ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<PlaceModel> get favoritePlaces {
    return _places.where((p) => _favoriteIds.contains(p.id)).toList();
  }

  bool isFavorite(int placeId) {
    return _favoriteIds.contains(placeId);
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchPlaces() async {
    _isLoading = true;
    notifyListeners();

    try {
      _places = await ApiService.getPlaces();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching places: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFavorites(int userId) async {
    try {
      final ids = await ApiService.getUserFavoritePlaceIds(userId);
      _favoriteIds = ids.toSet();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching favorites: $e');
      }
    }
  }

  Future<void> toggleFavorite(int userId, int placeId) async {
    final currentlyFavorite = _favoriteIds.contains(placeId);

    // Optimistic UI update
    if (currentlyFavorite) {
      _favoriteIds.remove(placeId);
    } else {
      _favoriteIds.add(placeId);
    }
    notifyListeners();

    try {
      if (currentlyFavorite) {
        final success = await ApiService.removeFavorite(userId, placeId);
        if (!success) {
          _favoriteIds.add(placeId);
          notifyListeners();
        }
      } else {
        final success = await ApiService.addFavorite(userId, placeId);
        if (!success) {
          _favoriteIds.remove(placeId);
          notifyListeners();
        }
      }
    } catch (e) {
      // Revert if error
      if (currentlyFavorite) {
        _favoriteIds.add(placeId);
      } else {
        _favoriteIds.remove(placeId);
      }
      notifyListeners();
    }
  }
}
