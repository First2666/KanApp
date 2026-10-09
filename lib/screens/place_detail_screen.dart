import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/place.dart';
import '../providers/auth_provider.dart';
import '../providers/place_provider.dart';
import '../providers/trip_provider.dart';
import '../widgets/mini_map.dart';
import '../widgets/nearby_places_widget.dart';

class PlaceDetailScreen extends StatefulWidget {
  final PlaceModel place;

  const PlaceDetailScreen({super.key, required this.place});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  int _currentImageIndex = 0;
  late final PageController _pageController;
  final ScrollController _thumbScrollController = ScrollController();

  List<String> get _images {
    final list = <String>[];
    for (final img in widget.place.images) {
      final u = img.fullUrl;
      if (u.isNotEmpty && !list.contains(u)) {
        list.add(u);
      }
    }
    if (list.isEmpty) {
      list.add(widget.place.primaryImageUrl);
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbScrollController.dispose();
    super.dispose();
  }

  void _onSelectImage(int index) {
    final images = _images;
    if (index < 0 || index >= images.length) return;
    setState(() {
      _currentImageIndex = index;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    _scrollToThumb(index);
  }

  void _scrollToThumb(int index) {
    if (!_thumbScrollController.hasClients) return;
    const itemWidth = 68.0 + 8.0;
    final offset = (index * itemWidth) - 100.0;
    _thumbScrollController.animateTo(
      offset.clamp(0.0, _thumbScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _openLightbox(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => _FullscreenGalleryViewer(
          images: _images,
          initialIndex: initialIndex,
          placeName: widget.place.name,
        ),
      ),
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final images = _images;
    final placeProvider = context.watch<PlaceProvider>();
    final authProvider = context.watch<AuthProvider>();
    final tripProvider = context.watch<TripProvider>();
    final isFav = placeProvider.isFavorite(place.id);

    final isFree = place.entranceFee <= 0 && place.placeType == 'Attraction';
    final priceLabel = isFree
        ? 'เข้าชมฟรี'
        : (place.entranceFee > 0
            ? '฿${place.entranceFee.toStringAsFixed(0)}'
            : 'ราคาตามเมนู');

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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // 1. Collapsible Interactive Image Banner
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  child: IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF64748B),
                    ),
                    onPressed: () {
                      if (!authProvider.isAuthenticated) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('กรุณาเข้าสู่ระบบเพื่อบันทึกรายการโปรด'),
                          ),
                        );
                        return;
                      }
                      placeProvider.toggleFavorite(
                        authProvider.currentUser!.id,
                        place.id,
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Main Swipable Photo Carousel
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (idx) {
                      setState(() => _currentImageIndex = idx);
                      _scrollToThumb(idx);
                    },
                    itemBuilder: (context, idx) {
                      return GestureDetector(
                        onTap: () => _openLightbox(context, idx),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              images[idx],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: const Color(0xFFE2E8F0),
                                child: const Center(
                                  child: Icon(Icons.landscape, size: 64, color: Colors.grey),
                                ),
                              ),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: const Color(0xFFF1F5F9),
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              },
                            ),
                            // Dark gradient overlay for text readability
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.35),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.75),
                                  ],
                                  stops: const [0.0, 0.45, 1.0],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Chevrons on Hero Image (Left & Right)
                  if (images.length > 1 && _currentImageIndex > 0)
                    Positioned(
                      left: 12,
                      top: 135,
                      child: _buildArrowButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: () => _onSelectImage(_currentImageIndex - 1),
                      ),
                    ),
                  if (images.length > 1 && _currentImageIndex < images.length - 1)
                    Positioned(
                      right: 12,
                      top: 135,
                      child: _buildArrowButton(
                        icon: Icons.chevron_right_rounded,
                        onTap: () => _onSelectImage(_currentImageIndex + 1),
                      ),
                    ),

                  // Image Counter Badge & Fullscreen Hint
                  if (images.length > 1)
                    Positioned(
                      bottom: 58,
                      right: 18,
                      child: GestureDetector(
                        onTap: () => _openLightbox(context, _currentImageIndex),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_library_rounded, size: 13, color: Colors.white),
                              const SizedBox(width: 5),
                              Text(
                                '${_currentImageIndex + 1}/${images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.fullscreen_rounded, size: 15, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Place Name Headline
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Text(
                      place.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 10),
                        ],
                      ),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Details Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Thumbnail Gallery Strip (Matching User Example) ---
                  if (images.length > 1) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.collections_rounded, size: 16, color: Color(0xFF2563EB)),
                              const SizedBox(width: 6),
                              Text(
                                'รูปภาพสถานที่ (${images.length} รูป)',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => _openLightbox(context, _currentImageIndex),
                                child: const Row(
                                  children: [
                                    Icon(Icons.zoom_in_rounded, size: 15, color: Color(0xFF2563EB)),
                                    SizedBox(width: 3),
                                    Text(
                                      'ดูรูปเต็มจอ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              // Left Chevron Button
                              InkWell(
                                onTap: _currentImageIndex > 0
                                    ? () => _onSelectImage(_currentImageIndex - 1)
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 32,
                                  height: 68,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex > 0
                                        ? const Color(0xFFF1F5F9)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.chevron_left_rounded,
                                    size: 24,
                                    color: _currentImageIndex > 0
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Thumbnails Scrollable Row
                              Expanded(
                                child: SizedBox(
                                  height: 68,
                                  child: ListView.separated(
                                    controller: _thumbScrollController,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: images.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                                    itemBuilder: (context, idx) {
                                      final isSelected = idx == _currentImageIndex;
                                      return GestureDetector(
                                        onTap: () => _onSelectImage(idx),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 68,
                                          height: 68,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xFF2563EB)
                                                  : const Color(0xFFE2E8F0),
                                              width: isSelected ? 3 : 1.5,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(9),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                Image.network(
                                                  images[idx],
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(
                                                    color: const Color(0xFFF1F5F9),
                                                    child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                                                  ),
                                                ),
                                                if (!isSelected)
                                                  Container(
                                                    color: Colors.black.withValues(alpha: 0.15),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Right Chevron Button
                              InkWell(
                                onTap: _currentImageIndex < images.length - 1
                                    ? () => _onSelectImage(_currentImageIndex + 1)
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 32,
                                  height: 68,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex < images.length - 1
                                        ? const Color(0xFFF1F5F9)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    size: 24,
                                    color: _currentImageIndex < images.length - 1
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Badges Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          place.typeLabel,
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        priceLabel,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isFree
                              ? const Color(0xFF059669)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Location & Time Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Color(0xFFEF4444),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ตำแหน่งที่ตั้ง',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    place.address ?? 'กาญจนบุรี',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (place.openingTime != null) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.access_time_filled,
                                  color: Color(0xFF2563EB),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'เวลาทำการ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${place.openingTime} - ${place.closingTime ?? ""}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'รายละเอียดสถานที่',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    place.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF475569),
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Categories & Tags
                  if (place.categories.isNotEmpty) ...[
                    const Text(
                      'หมวดหมู่',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: place.categories
                          .map((cat) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFDBEAFE),
                                  ),
                                ),
                                child: Text(
                                  cat,
                                  style: const TextStyle(
                                    color: Color(0xFF1D4ED8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (place.tags.isNotEmpty) ...[
                    const Text(
                      'แท็กยอดนิยม',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: place.tags
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Mini-Map Section
                  const Text(
                    'ตำแหน่งที่ตั้ง & แผนที่',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  MiniMapWidget(
                    places: [place],
                    height: 220,
                    showExpandButton: true,
                    userLocation: tripProvider.isUsingGps && tripProvider.userLatitude != null
                        ? LatLng(tripProvider.userLatitude!, tripProvider.userLongitude!)
                        : null,
                    onToggleGps: () {
                      tripProvider.toggleGps();
                    },
                  ),
                  const SizedBox(height: 28),

                  // Nearby Places Section (สถานที่และร้านใกล้เคียง)
                  NearbyPlacesWidget(currentPlace: place),
                  const SizedBox(height: 28),

                  // Action Buttons Row: จัดลงทริป + บันทึกโปรด
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                            label: const Text(
                              'จัดลงทริป',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () async {
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
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            icon: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 20,
                              color: isFav ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                            ),
                            label: Text(
                              isFav ? 'บันทึกแล้ว' : 'บันทึก',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isFav ? const Color(0xFFEF4444) : const Color(0xFF334155),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isFav ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
                              ),
                              backgroundColor: isFav ? const Color(0xFFFEF2F2) : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              if (!authProvider.isAuthenticated) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('กรุณาเข้าสู่ระบบเพื่อบันทึกรายการโปรด')),
                                );
                                return;
                              }
                              placeProvider.toggleFavorite(
                                authProvider.currentUser!.id,
                                place.id,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// Fullscreen Interactive Lightbox Modal Viewer
// ---------------------------------------------------------
class _FullscreenGalleryViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String placeName;

  const _FullscreenGalleryViewer({
    required this.images,
    required this.initialIndex,
    required this.placeName,
  });

  @override
  State<_FullscreenGalleryViewer> createState() => _FullscreenGalleryViewerState();
}

class _FullscreenGalleryViewerState extends State<_FullscreenGalleryViewer> {
  late int _currentIndex;
  late final PageController _pageController;
  final ScrollController _thumbController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.images.length) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _scrollToThumb(index);
  }

  void _scrollToThumb(int index) {
    if (!_thumbController.hasClients) return;
    const itemWidth = 56.0 + 8.0;
    final target = (index * itemWidth) - 100.0;
    _thumbController.animateTo(
      target.clamp(0.0, _thumbController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. PageView for Fullscreen Images with Zoom
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (idx) {
                setState(() => _currentIndex = idx);
                _scrollToThumb(idx);
              },
              itemBuilder: (context, idx) {
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      widget.images[idx],
                      fit: BoxFit.contain,
                      loadingBuilder: (ctx, child, prog) {
                        if (prog == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                      errorBuilder: (ctx, err, stack) => const Center(
                        child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
                      ),
                    ),
                  ),
                );
              },
            ),

            // 2. Navigation Chevrons on Screen Sides
            if (widget.images.length > 1 && _currentIndex > 0)
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 32),
                      onPressed: () => _goTo(_currentIndex - 1),
                    ),
                  ),
                ),
              ),

            if (widget.images.length > 1 && _currentIndex < widget.images.length - 1)
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 32),
                      onPressed: () => _goTo(_currentIndex + 1),
                    ),
                  ),
                ),
              ),

            // 3. Top Header Bar (Close button, title, page indicator)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white24,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.placeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Bottom Thumbnails Strip
            if (widget.images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  alignment: Alignment.center,
                  child: ListView.separated(
                    controller: _thumbController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final isSelected = idx == _currentIndex;
                      return GestureDetector(
                        onTap: () => _goTo(idx),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF2563EB) : Colors.white24,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.images[idx],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

