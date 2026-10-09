import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/place.dart';
import '../providers/auth_provider.dart';
import '../providers/place_provider.dart';
import '../providers/trip_provider.dart';
import '../screens/place_detail_screen.dart';

class CompactPlaceCard extends StatelessWidget {
  final PlaceModel place;
  final double width;

  const CompactPlaceCard({
    super.key,
    required this.place,
    this.width = 210,
  });

  @override
  Widget build(BuildContext context) {
    final placeProvider = context.watch<PlaceProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isFav = placeProvider.isFavorite(place.id);

    Color typeColor;
    switch (place.placeType) {
      case 'Attraction':
        typeColor = const Color(0xFF059669);
        break;
      case 'Restaurant':
        typeColor = const Color(0xFFEA580C);
        break;
      case 'Accommodation':
        typeColor = const Color(0xFF9333EA);
        break;
      default:
        typeColor = const Color(0xFF2563EB);
    }

    final isFree = place.entranceFee <= 0 && place.placeType == 'Attraction';
    final priceText = isFree
        ? 'เข้าชมฟรี'
        : (place.entranceFee > 0
            ? '฿${place.entranceFee.toStringAsFixed(0)}'
            : 'ราคาตามเมนู');

    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => PlaceDetailScreen(place: place),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Image with overlays
              Stack(
                children: [
                  SizedBox(
                    height: 125,
                    width: double.infinity,
                    child: Image.network(
                      place.primaryImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.landscape_rounded, color: Color(0xFF94A3B8), size: 36),
                      ),
                    ),
                  ),

                  // Gradient
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top-Left Category Chip
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: typeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            place.placeType == 'Attraction'
                                ? 'ที่เที่ยว'
                                : place.placeType == 'Restaurant'
                                    ? 'ร้านอาหาร'
                                    : 'ที่พัก',
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Top-Right Favorite Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        if (!authProvider.isAuthenticated) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('กรุณาเข้าสู่ระบบเพื่อบันทึกรายการโปรด')),
                          );
                          return;
                        }
                        placeProvider.toggleFavorite(authProvider.currentUser!.id, place.id);
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 16,
                          color: isFav ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),

                  // Bottom-Right Rating Badge
                  Positioned(
                    bottom: 6,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 12, color: Color(0xFFFBBF24)),
                          SizedBox(width: 2),
                          Text(
                            '4.8',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 2. Info Area
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            place.address ?? 'กาญจนบุรี',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          priceText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: isFree ? const Color(0xFF059669) : const Color(0xFF1E3A8A),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            if (!authProvider.isAuthenticated) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('กรุณาเข้าสู่ระบบเพื่อจัดทริป')),
                              );
                              return;
                            }
                            final ok = await context
                                .read<TripProvider>()
                                .addPlaceToTrip(authProvider.currentUser!.id, place);
                            if (context.mounted && ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('เพิ่ม "${place.name}" ลงในแผนเดินทางแล้ว!'),
                                  backgroundColor: const Color(0xFF2563EB),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded, size: 12, color: Color(0xFF2563EB)),
                                SizedBox(width: 2),
                                Text(
                                  'จัดทริป',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
