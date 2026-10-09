import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/place.dart';

enum MapTileType {
  googleRoad,
  googleSatellite,
  osm,
}

class MiniMapWidget extends StatefulWidget {
  final List<PlaceModel> places;
  final int activeStep;
  final double height;
  final bool showExpandButton;
  final LatLng? userLocation;
  final VoidCallback? onToggleGps;

  const MiniMapWidget({
    super.key,
    required this.places,
    this.activeStep = 0,
    this.height = 240,
    this.showExpandButton = true,
    this.userLocation,
    this.onToggleGps,
  });

  @override
  State<MiniMapWidget> createState() => _MiniMapWidgetState();
}

class _MiniMapWidgetState extends State<MiniMapWidget> {
  late final MapController _mapController;
  MapTileType _tileType = MapTileType.googleRoad;
  bool _isFollowingUser = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  String _getTileUrl() {
    switch (_tileType) {
      case MapTileType.googleRoad:
        // Official Google Maps Standard Street Vector Tiles
        return 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
      case MapTileType.googleSatellite:
        // Official Google Maps Hybrid Satellite Tiles with road labels
        return 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
      case MapTileType.osm:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  Color _getMarkerColor(String placeType) {
    switch (placeType) {
      case 'Attraction':
        return const Color(0xFF059669); // Emerald
      case 'Restaurant':
        return const Color(0xFFEA580C); // Orange
      case 'Accommodation':
        return const Color(0xFF9333EA); // Purple
      default:
        return const Color(0xFF2563EB); // Blue
    }
  }

  Future<void> _openGoogleMaps() async {
    if (widget.places.isEmpty) {
      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=กาญจนบุรี');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    // Determine Origin (User GPS or first place)
    String originStr = '';
    if (widget.userLocation != null) {
      originStr = '${widget.userLocation!.latitude},${widget.userLocation!.longitude}';
    } else if (widget.places.length > 1) {
      final first = widget.places.first;
      originStr = '${first.latitude},${first.longitude}';
    }

    // Determine Destination (Active step place or last place)
    final targetIndex = widget.activeStep < widget.places.length
        ? widget.activeStep
        : widget.places.length - 1;
    final target = widget.places[targetIndex];
    final destStr = '${target.latitude},${target.longitude}';

    String urlStr;
    if (originStr.isNotEmpty) {
      // Build Google Maps turn-by-turn navigation URL
      urlStr = 'https://www.google.com/maps/dir/?api=1&origin=$originStr&destination=$destStr&travelmode=driving';
    } else {
      // Direct place view / search in Google Maps
      urlStr = 'https://www.google.com/maps/search/?api=1&query=$destStr';
    }

    final uri = Uri.parse(urlStr);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _centerOnUser() {
    if (widget.userLocation != null) {
      _mapController.move(widget.userLocation!, 14.0);
      setState(() => _isFollowingUser = true);
    } else if (widget.onToggleGps != null) {
      widget.onToggleGps!();
    }
  }

  void _fitAllMarkers(List<LatLng> allPoints) {
    if (allPoints.isEmpty) return;
    if (allPoints.length == 1) {
      _mapController.move(allPoints.first, 14.0);
      return;
    }
    final bounds = LatLngBounds.fromPoints(allPoints);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      ),
    );
    setState(() => _isFollowingUser = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.places.isEmpty && widget.userLocation == null) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 40, color: Color(0xFF94A3B8)),
              SizedBox(height: 8),
              Text(
                'ยังไม่มีสถานที่ในแผนที่',
                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final points = <LatLng>[];
    if (widget.userLocation != null) {
      points.add(widget.userLocation!);
    }
    for (final p in widget.places) {
      points.add(LatLng(p.latitude, p.longitude));
    }

    final initialCenter = widget.userLocation ??
        (widget.places.isNotEmpty
            ? LatLng(widget.places.first.latitude, widget.places.first.longitude)
            : const LatLng(14.0228, 99.5328));

    return Container(
      height: widget.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // FlutterMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: points.length > 1 ? 11.0 : 13.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              // Google Maps / Tile Layer with zero-crash in-memory network provider
              TileLayer(
                key: ValueKey(_tileType),
                urlTemplate: _getTileUrl(),
                userAgentPackageName: 'com.example.kanapp',
                tileProvider: NetworkTileProvider(
                  cachingProvider: const DisabledMapCachingProvider(),
                ),
              ),

              // Polyline connecting Route
              if (points.length > 1) ...[
                // Outer polyline glow/border
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: points,
                      color: Colors.white.withValues(alpha: 0.9),
                      strokeWidth: 6.0,
                    ),
                    Polyline(
                      points: points,
                      color: const Color(0xFF2563EB),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              ],

              // Markers Layer
              MarkerLayer(
                markers: [
                  // 1. User GPS Position Marker
                  if (widget.userLocation != null)
                    Marker(
                      point: widget.userLocation!,
                      width: 50,
                      height: 50,
                      child: _buildUserLocationMarker(),
                    ),

                  // 2. Stops / Destination Markers
                  for (int i = 0; i < widget.places.length; i++) ...[
                    Marker(
                      point: LatLng(widget.places[i].latitude, widget.places[i].longitude),
                      width: 44,
                      height: 44,
                      child: _buildPin(
                        stepIndex: i + 1,
                        color: _getMarkerColor(widget.places[i].placeType),
                        isActive: i == widget.activeStep,
                        name: widget.places[i].name,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // Top-Left: Number of Stops / Mode Badge
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.alt_route_rounded, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.places.length} จุดหมาย',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (widget.userLocation != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.gps_fixed_rounded, size: 10, color: Color(0xFF059669)),
                          SizedBox(width: 2),
                          Text(
                            'GPS ทำงาน',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Top-Right: Map Layers & Actions
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Toggle Map Style (Road / Satellite)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_tileType == MapTileType.googleRoad) {
                        _tileType = MapTileType.googleSatellite;
                      } else if (_tileType == MapTileType.googleSatellite) {
                        _tileType = MapTileType.osm;
                      } else {
                        _tileType = MapTileType.googleRoad;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _tileType == MapTileType.googleSatellite
                              ? Icons.satellite_alt_rounded
                              : Icons.map_rounded,
                          size: 13,
                          color: const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _tileType == MapTileType.googleRoad
                              ? 'ดาวเทียม'
                              : (_tileType == MapTileType.googleSatellite ? 'OSM' : 'Google'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Reset Camera / Fit All Points
                GestureDetector(
                  onTap: () => _fitAllMarkers(points),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.fit_screen_rounded,
                      size: 16,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom-Left: Current GPS Location Button
          Positioned(
            bottom: 12,
            left: 12,
            child: GestureDetector(
              onTap: _centerOnUser,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: (widget.userLocation != null && _isFollowingUser)
                      ? const Color(0xFF2563EB)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ],
                  border: Border.all(
                    color: (widget.userLocation != null && _isFollowingUser)
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.userLocation != null
                          ? Icons.my_location_rounded
                          : Icons.location_searching_rounded,
                      size: 14,
                      color: (widget.userLocation != null && _isFollowingUser)
                          ? Colors.white
                          : const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.userLocation != null ? 'ตำแหน่งฉัน' : 'ระบุตำแหน่ง',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: (widget.userLocation != null && _isFollowingUser)
                            ? Colors.white
                            : const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom-Right: Open Turn-by-Turn Navigation in Google Maps
          Positioned(
            bottom: 12,
            right: 12,
            child: GestureDetector(
              onTap: _openGoogleMaps,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.navigation_rounded, size: 14, color: Color(0xFF0F172A)),
                    SizedBox(width: 5),
                    Text(
                      'เปิดนำทาง Google Maps',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // User GPS Pulsating Marker
  Widget _buildUserLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer halo
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
        ),
        // White border
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        // Inner blue dot
        Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            color: Color(0xFF2563EB),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  // Numbered Stop Pin
  Widget _buildPin({
    required int stepIndex,
    required Color color,
    required bool isActive,
    required String name,
  }) {
    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? Colors.white : color,
            width: isActive ? 2.5 : 3.0,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$stepIndex',
          style: TextStyle(
            color: isActive ? Colors.white : color,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
