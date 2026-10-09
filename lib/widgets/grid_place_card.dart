import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/place.dart';
import '../providers/auth_provider.dart';
import '../providers/place_provider.dart';
import '../providers/trip_provider.dart';
import '../screens/place_detail_screen.dart';

class GridPlaceCard extends StatelessWidget {
  final PlaceModel place;

  const GridPlaceCard({
    super.key,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    final placeProvider = context.watch<PlaceProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isFav = placeProvider.isFavorite(place.id);

    Color typeColor;
    String typeText;
    switch (place.placeType) {
      case 'Attraction':
        typeColor = const Color(0xFF059669);
        typeText = 'ที่เที่ยว';
        break;
      case 'Restaurant':
        typeColor = const Color(0xFFEA580C);
        typeText = 'ร้านอาหาร';
        break;
      case 'Accommodation':
        typeColor = const Color(0xFF9333EA);
        typeText = 'ที่พัก';
        break;
      default:
        typeColor = const Color(0xFF2563EB);
        typeText = 'สถานที่';
    }

    final isFree = place.entranceFee <= 0 && place.placeType == 'Attraction';
    final priceLabel = isFree
        ? 'เข้าชมฟรี'
        : (place.placeType == 'Accommodation' && place.entranceFee > 0
            ? '฿${place.entranceFee.toStringAsFixed(0)}/คืน'
            : (place.entranceFee > 0
                ? '฿${place.entranceFee.toStringAsFixed(0)}'
                : 'ราคาตามเมนู'));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
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
                builder: (ctx) => PlaceDetailScreen(place: place),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Image with Category & Heart Overlay
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 11,
                    child: Image.network(
                      place.primaryImageUrl,
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

                  // Top-Left Category Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10),
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
                            typeText,
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
                          size: 15,
                          color: isFav ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),

                  // Bottom-Right Star Rating
                  Positioned(
                    bottom: 6,
                    right: 6,
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

              // 2. Info Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Place Name
                          Text(
                            place.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),

                          // Location / Address
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  place.address ?? 'กาญจนบุรี',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Price and Add to Trip Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Price
                          Expanded(
                            child: Text(
                              priceLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isFree
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Quick Add to Trip button
                          GestureDetector(
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded, size: 12, color: Color(0xFF2563EB)),
                                  SizedBox(width: 2),
                                  Text(
                                    'ทริป',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
