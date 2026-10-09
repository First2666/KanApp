import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/place.dart';
import '../providers/place_provider.dart';
import '../screens/place_detail_screen.dart';

class NearbyPlacesWidget extends StatefulWidget {
  final PlaceModel currentPlace;

  const NearbyPlacesWidget({
    super.key,
    required this.currentPlace,
  });

  @override
  State<NearbyPlacesWidget> createState() => _NearbyPlacesWidgetState();
}

class _NearbyPlacesWidgetState extends State<NearbyPlacesWidget> {
  String _activeTab = 'attractions'; // 'attractions', 'accommodations', 'restaurants'

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // Radius of Earth in km
    final dLat = (lat2 - lat1) * pi / 180.0;
    final dLon = (lon2 - lon1) * pi / 180.0;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) * cos(lat2 * pi / 180.0) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  String _getPriceText(PlaceModel place, String tab) {
    if (tab == 'attractions') {
      if (place.entranceFee <= 0) return 'เข้าชมฟรี';
      return 'ค่าเข้า ฿${place.entranceFee.toStringAsFixed(0)}';
    } else if (tab == 'accommodations') {
      if (place.entranceFee > 0) return 'เริ่มต้น ฿${place.entranceFee.toStringAsFixed(0)}';
      return 'ที่พักริมน้ำ';
    } else {
      if (place.entranceFee > 0) return 'เฉลี่ย ฿${place.entranceFee.toStringAsFixed(0)}';
      return 'ราคาตามเมนู';
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeProvider = context.watch<PlaceProvider>();
    final allPlaces = placeProvider.places;

    final curLat = widget.currentPlace.latitude;
    final curLng = widget.currentPlace.longitude;

    // Calculate distance to all other places
    final otherPlacesWithDist = allPlaces
        .where((p) => p.id != widget.currentPlace.id)
        .map((p) {
          final dist = _calculateDistance(curLat, curLng, p.latitude, p.longitude);
          return _PlaceWithDistance(place: p, distanceKm: dist);
        })
        .toList();

    // Group & Sort by distance ascending
    final nearbyAttractions = otherPlacesWithDist
        .where((p) => p.place.placeType == 'Attraction')
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    final nearbyAccommodations = otherPlacesWithDist
        .where((p) => p.place.placeType == 'Accommodation')
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    final nearbyRestaurants = otherPlacesWithDist
        .where((p) => p.place.placeType == 'Restaurant')
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    List<_PlaceWithDistance> activeList;
    Color activeColor;
    if (_activeTab == 'accommodations') {
      activeList = nearbyAccommodations.take(6).toList();
      activeColor = const Color(0xFF4F46E5);
    } else if (_activeTab == 'restaurants') {
      activeList = nearbyRestaurants.take(6).toList();
      activeColor = const Color(0xFFF59E0B);
    } else {
      activeList = nearbyAttractions.take(6).toList();
      activeColor = const Color(0xFF2563EB);
    }

    if (otherPlacesWithDist.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Section Header (Matching Web PlaceDetailView)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Color(0xFF2563EB),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'สถานที่และร้านใกล้เคียง',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'คัดสรรจุดน่าสนใจ ที่พัก และร้านอาหารใกล้เคียง โดยเรียงตามระยะทางจริง',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // 2. Tabs Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTabPill(
                id: 'attractions',
                label: 'ที่เที่ยวใกล้เคียง',
                count: nearbyAttractions.length,
                icon: Icons.explore_rounded,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              _buildTabPill(
                id: 'accommodations',
                label: 'ที่พักใกล้เคียง',
                count: nearbyAccommodations.length,
                icon: Icons.hotel_rounded,
                color: const Color(0xFF4F46E5),
              ),
              const SizedBox(width: 8),
              _buildTabPill(
                id: 'restaurants',
                label: 'ร้านอาหารใกล้เคียง',
                count: nearbyRestaurants.length,
                icon: Icons.restaurant_rounded,
                color: const Color(0xFFEA580C),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 3. Nearby Places Cards List (Horizontal Carousel for compact height)
        if (activeList.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: const Text(
              'ไม่มีข้อมูลในหมวดหมู่นี้ในระยะใกล้เคียง',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          )
        else
          SizedBox(
            height: 195,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: activeList.length,
              itemBuilder: (context, idx) {
                return _buildNearbyCard(context, activeList[idx], _activeTab, activeColor);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTabPill({
    required String id,
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _activeTab == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 5),
            Text(
              '$label ($count)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyCard(
    BuildContext context,
    _PlaceWithDistance item,
    String tab,
    Color themeColor,
  ) {
    final p = item.place;
    final distText = item.distanceKm < 1
        ? 'ห่าง ${(item.distanceKm * 1000).toStringAsFixed(0)} ม.'
        : 'ห่าง ${item.distanceKm.toStringAsFixed(1)} กม.';
    final priceText = _getPriceText(p, tab);

    return Container(
      width: 175,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => PlaceDetailScreen(place: p),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Thumbnail Image with Distance Badge
              Stack(
                children: [
                  SizedBox(
                    height: 105,
                    width: double.infinity,
                    child: Image.network(
                      p.primaryImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(
                          Icons.landscape_rounded,
                          color: Color(0xFF94A3B8),
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.navigation_rounded,
                            size: 10,
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            distText,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 2. Info Content
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            priceText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: themeColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceWithDistance {
  final PlaceModel place;
  final double distanceKm;

  _PlaceWithDistance({
    required this.place,
    required this.distanceKm,
  });
}
