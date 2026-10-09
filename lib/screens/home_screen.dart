import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/place.dart';
import '../providers/auth_provider.dart';
import '../providers/place_provider.dart';
import '../services/api_service.dart';
import '../widgets/brand_logo.dart';
import '../widgets/compact_place_card.dart';
import '../widgets/grid_place_card.dart';
import 'notifications_screen.dart';
import 'place_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int index)? onSelectTab;

  const HomeScreen({
    super.key,
    this.onSelectTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _spotlightController = PageController();
  int _unreadCount = 0;
  int _currentSpotlightPage = 0;
  String _activeMood = 'all';
  int _currentPage = 1;
  static const int _itemsPerPage = 4; // 2 items per row x 2 rows = 4 items per page

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final count = await ApiService.getUnreadNotificationCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    _spotlightController.dispose();
    super.dispose();
  }

  List<PlaceModel> _filterByMood(List<PlaceModel> list, String mood) {
    if (mood == 'all') return list;
    return list.where((p) {
      final text = '${p.name} ${p.description} ${p.tags.join(' ')} ${p.categories.join(' ')}'.toLowerCase();
      if (mood == 'nature') {
        return text.contains('น้ำตก') ||
            text.contains('ธรรมชาติ') ||
            text.contains('อุทยาน') ||
            text.contains('ป่า') ||
            text.contains('ถ้ำ');
      } else if (mood == 'cafe') {
        return p.placeType == 'Restaurant' ||
            text.contains('คาเฟ่') ||
            text.contains('กาแฟ') ||
            text.contains('อาหาร');
      } else if (mood == 'history') {
        return text.contains('ประวัติศาสตร์') ||
            text.contains('สงคราม') ||
            text.contains('สะพาน') ||
            text.contains('ทางรถไฟ') ||
            text.contains('วัด') ||
            text.contains('เมืองเก่า');
      } else if (mood == 'river') {
        return text.contains('แคว') ||
            text.contains('แม่น้ำ') ||
            text.contains('แพ') ||
            text.contains('ริมน้ำ') ||
            text.contains('เขื่อน');
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final placeProvider = context.watch<PlaceProvider>();
    final allPlaces = placeProvider.places;
    final isSearching = placeProvider.searchQuery.isNotEmpty || placeProvider.selectedCategory != 'All' || _activeMood != 'all';

    final filteredPlaces = _filterByMood(placeProvider.filteredPlaces, _activeMood);
    final totalPages = (filteredPlaces.isEmpty) ? 1 : (filteredPlaces.length / _itemsPerPage).ceil();
    final currentPage = _currentPage.clamp(1, totalPages);
    final startIndex = (currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filteredPlaces.length);
    final pagedPlaces = (startIndex < filteredPlaces.length)
        ? filteredPlaces.sublist(startIndex, endIndex)
        : <PlaceModel>[];

    final attractions = allPlaces.where((p) => p.placeType == 'Attraction').toList();
    final restaurants = allPlaces.where((p) => p.placeType == 'Restaurant').toList();
    final accommodations = allPlaces.where((p) => p.placeType == 'Accommodation').toList();
    final spotlightPlaces = allPlaces.take(4).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF2563EB),
          onRefresh: () async {
            await placeProvider.fetchPlaces();
            await _fetchUnreadCount();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Top Bar & Greeting Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Brand & Action Icons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const BrandLogo(size: 36),
                          Row(
                            children: [
                              // Quick Jump to Favorites
                              _buildHeaderIconButton(
                                icon: Icons.favorite_border_rounded,
                                color: const Color(0xFF64748B),
                                onTap: () => widget.onSelectTab?.call(2),
                              ),
                              const SizedBox(width: 8),
                              // Notification Bell with badge
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  _buildHeaderIconButton(
                                    icon: Icons.notifications_none_rounded,
                                    color: const Color(0xFFD97706),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (ctx) => const NotificationsScreen(),
                                        ),
                                      ).then((_) => _fetchUnreadCount());
                                    },
                                  ),
                                  if (_unreadCount > 0)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                        child: Text(
                                          _unreadCount > 9 ? '9+' : '$_unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Inspiring Welcome Text & Weather Tag
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ค้นพบมนต์เสน่ห์เมืองกาญจน์',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'วันนี้อยากไปเที่ยวที่ไหนดีครับ?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Weather pill (White & Bright)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.wb_sunny_rounded, size: 14, color: Color(0xFFF59E0B)),
                                SizedBox(width: 4),
                                Text(
                                  '29°C กาญจนบุรี',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Modern Floating Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'ค้นหาที่เที่ยว, คาเฟ่ริมน้ำ, ที่พัก...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.search_rounded,
                                color: Color(0xFF2563EB),
                                size: 18,
                              ),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.cancel_rounded, size: 18, color: Color(0xFF94A3B8)),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _currentPage = 1);
                                      placeProvider.setSearchQuery('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          ),
                          onChanged: (val) {
                            setState(() => _currentPage = 1);
                            placeProvider.setSearchQuery(val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            
              // 3. Mood Tabs (Filter Pills with Icons & Bright Vibrant Tone)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildMoodPill(
                          id: 'all',
                          label: 'ทั้งหมด',
                          icon: Icons.auto_awesome_rounded,
                          color: const Color(0xFF2563EB),
                        ),
                        _buildMoodPill(
                          id: 'nature',
                          label: 'ธรรมชาติ & น้ำตก',
                          icon: Icons.forest_rounded,
                          color: const Color(0xFF059669),
                        ),
                        _buildMoodPill(
                          id: 'cafe',
                          label: 'คาเฟ่ & ชิลล์',
                          icon: Icons.local_cafe_rounded,
                          color: const Color(0xFFEA580C),
                        ),
                        _buildMoodPill(
                          id: 'history',
                          label: 'ประวัติศาสตร์',
                          icon: Icons.account_balance_rounded,
                          color: const Color(0xFF7C3AED),
                        ),
                        _buildMoodPill(
                          id: 'river',
                          label: 'ริมแม่น้ำ & ล่องแพ',
                          icon: Icons.water_rounded,
                          color: const Color(0xFF0284C7),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // -----------------------------------------------------------------
              // IF SEARCHING OR FILTER APPLIED -> SHOW SEARCH RESULTS VIEW
              // -----------------------------------------------------------------
              if (isSearching) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                placeProvider.selectedCategory == 'Attraction'
                                    ? Icons.explore_rounded
                                    : placeProvider.selectedCategory == 'Restaurant'
                                        ? Icons.restaurant_rounded
                                        : placeProvider.selectedCategory == 'Accommodation'
                                            ? Icons.hotel_rounded
                                            : Icons.filter_list_rounded,
                                size: 14,
                                color: const Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                placeProvider.selectedCategory == 'Attraction'
                                    ? 'ที่เที่ยวทั้งหมด (${filteredPlaces.length})'
                                    : placeProvider.selectedCategory == 'Restaurant'
                                        ? 'ร้านอาหารทั้งหมด (${filteredPlaces.length})'
                                        : placeProvider.selectedCategory == 'Accommodation'
                                            ? 'ที่พักทั้งหมด (${filteredPlaces.length})'
                                            : 'พบ ${filteredPlaces.length} สถานที่',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            placeProvider.setSearchQuery('');
                            placeProvider.setCategory('All');
                            setState(() {
                              _activeMood = 'all';
                              _currentPage = 1;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.close_rounded, size: 14, color: Color(0xFF64748B)),
                                SizedBox(width: 4),
                                Text(
                                  'กลับหน้าหลัก',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (filteredPlaces.isEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.search_off_rounded,
                              size: 34,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'ไม่พบสถานที่ที่ตรงกับเงื่อนไข',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'ลองเปลี่ยนคำค้นหา หรือเลือกหมวดหมู่อื่นดูนะครับ',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              placeProvider.setSearchQuery('');
                              placeProvider.setCategory('All');
                              setState(() {
                                _activeMood = 'all';
                                _currentPage = 1;
                              });
                            },
                            child: const Text('ล้างตัวกรองทั้งหมด'),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.70,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, idx) => GridPlaceCard(place: pagedPlaces[idx]),
                        childCount: pagedPlaces.length,
                      ),
                    ),
                  ),

                  // Pagination Controls Bar (if totalPages > 1)
                  if (totalPages > 1)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                        child: Column(
                          children: [
                            // Page Status Label
                            Text(
                              'หน้า $currentPage จาก $totalPages  •  ทั้งหมด ${filteredPlaces.length} รายการ (หน้าละ $_itemsPerPage รายการ)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Previous Page Button
                                  InkWell(
                                    onTap: currentPage > 1
                                        ? () {
                                            setState(() => _currentPage = currentPage - 1);
                                          }
                                        : null,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: currentPage > 1 ? Colors.white : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: currentPage > 1 ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                                        ),
                                        boxShadow: currentPage > 1
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.04),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.chevron_left_rounded,
                                            size: 18,
                                            color: currentPage > 1 ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'ก่อนหน้า',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: currentPage > 1 ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Numbered Page Buttons [ 1 ] [ 2 ] ...
                                  ...List.generate(totalPages, (index) {
                                    final pageNum = index + 1;
                                    final isCurrent = pageNum == currentPage;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 3),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() => _currentPage = pageNum);
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 150),
                                          width: 36,
                                          height: 36,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: isCurrent ? const Color(0xFF2563EB) : Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isCurrent ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                                              width: isCurrent ? 1.5 : 1,
                                            ),
                                            boxShadow: isCurrent
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Text(
                                            '$pageNum',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: isCurrent ? Colors.white : const Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),

                                  const SizedBox(width: 8),

                                  // Next Page Button
                                  InkWell(
                                    onTap: currentPage < totalPages
                                        ? () {
                                            setState(() => _currentPage = currentPage + 1);
                                          }
                                        : null,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: currentPage < totalPages ? Colors.white : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: currentPage < totalPages ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                                        ),
                                        boxShadow: currentPage < totalPages
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.04),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            'ถัดไป',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: currentPage < totalPages ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            size: 18,
                                            color: currentPage < totalPages ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ]

              // -----------------------------------------------------------------
              // IF DEFAULT BROWSING MODE -> SHOW CURATED HOME FEED
              // -----------------------------------------------------------------
              else ...[
                // 4. Grand Spotlight Highlights Carousel (ไฮไลท์ห้ามพลาด)
                if (spotlightPlaces.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                      child: _buildSectionHeader(
                        title: 'ไฮไลท์ห้ามพลาด',
                        badge: 'แนะนำ',
                        badgeColor: const Color(0xFFF59E0B),
                        icon: Icons.star_rounded,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 205,
                      child: PageView.builder(
                        controller: _spotlightController,
                        itemCount: spotlightPlaces.length,
                        onPageChanged: (idx) => setState(() => _currentSpotlightPage = idx),
                        itemBuilder: (context, idx) {
                          return _buildSpotlightCard(context, spotlightPlaces[idx]);
                        },
                      ),
                    ),
                  ),
                  // Dots Indicator
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          spotlightPlaces.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentSpotlightPage == i ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentSpotlightPage == i
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // 5. Trip Planner Promotion Banner (มีแพลนเที่ยวหรือยัง?)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    child: _buildTripPromoBanner(context),
                  ),
                ),

                // 6. Section: ที่เที่ยวยอดนิยม (Attractions Horizontal Carousel)
                if (attractions.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                      child: _buildSectionHeader(
                        title: 'ที่เที่ยวยอดนิยม',
                        badge: '${attractions.length} แห่ง',
                        badgeColor: const Color(0xFF059669),
                        icon: Icons.explore_rounded,
                        onSeeAll: () {
                          setState(() => _currentPage = 1);
                          placeProvider.setCategory('Attraction');
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 230,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        itemCount: attractions.length,
                        itemBuilder: (context, idx) => CompactPlaceCard(place: attractions[idx]),
                      ),
                    ),
                  ),
                ],

                // 7. Section: ร้านอาหาร & คาเฟ่ริมน้ำ (Restaurants Horizontal Carousel)
                if (restaurants.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
                      child: _buildSectionHeader(
                        title: 'คาเฟ่ & อาหารเด็ดริมน้ำ',
                        badge: '${restaurants.length} แห่ง',
                        badgeColor: const Color(0xFFEA580C),
                        icon: Icons.restaurant_rounded,
                        onSeeAll: () {
                          setState(() => _currentPage = 1);
                          placeProvider.setCategory('Restaurant');
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 230,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        itemCount: restaurants.length,
                        itemBuilder: (context, idx) => CompactPlaceCard(place: restaurants[idx]),
                      ),
                    ),
                  ),
                ],

                // 8. Section: ที่พักริมน้ำแคว (Accommodations Horizontal Carousel)
                if (accommodations.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
                      child: _buildSectionHeader(
                        title: 'ที่พัก & รีสอร์ทริมน้ำแคว',
                        badge: '${accommodations.length} แห่ง',
                        badgeColor: const Color(0xFF9333EA),
                        icon: Icons.hotel_rounded,
                        onSeeAll: () {
                          setState(() => _currentPage = 1);
                          placeProvider.setCategory('Accommodation');
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 230,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        itemCount: accommodations.length,
                        itemBuilder: (context, idx) => CompactPlaceCard(place: accommodations[idx]),
                      ),
                    ),
                  ),
                ],
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Header Icon Button
  Widget _buildHeaderIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // Helper: Quick Action Item
  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colors.last.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Mood Filter Pill (White & Bright Vibrant Tone)
  Widget _buildMoodPill({
    required String id,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _activeMood == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            _activeMood = id;
            _currentPage = 1;
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
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? color.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Section Header
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    String? badge,
    Color badgeColor = const Color(0xFF2563EB),
    VoidCallback? onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: badgeColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: const Row(
              children: [
                Text(
                  'ดูทั้งหมด',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF2563EB)),
              ],
            ),
          ),
      ],
    );
  }

  // Helper: Spotlight Card
  Widget _buildSpotlightCard(BuildContext context, PlaceModel place) {
    final placeProvider = context.watch<PlaceProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isFav = placeProvider.isFavorite(place.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Image
            Positioned.fill(
              child: Image.network(
                place.primaryImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, st) => Container(
                  color: const Color(0xFFCBD5E1),
                  child: const Icon(Icons.landscape_rounded, color: Colors.white, size: 48),
                ),
              ),
            ),

            // Gradient Overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),

            // Top Badges
            Positioned(
              top: 12,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 12, color: Color(0xFFFBBF24)),
                        SizedBox(width: 4),
                        Text(
                          'ไฮไลท์แนะนำเมืองกาญจน์',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
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
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 18,
                        color: isFav ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Content
            Positioned(
              bottom: 14,
              left: 14,
              right: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          place.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: Colors.white70),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                place.address ?? 'กาญจนบุรี',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Button to view detail
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => PlaceDetailScreen(place: place),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('สำรวจ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_forward_rounded, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Trip Planner Promo Banner (Crisp White & Bright Vibrant Tone)
  Widget _buildTripPromoBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Icon(
              Icons.alt_route_rounded,
              color: Color(0xFF2563EB),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'มีแพลนเที่ยวหรือยัง?',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map_rounded, size: 10, color: Color(0xFF2563EB)),
                          SizedBox(width: 2),
                          Text(
                            'ทริป',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'จัดเส้นทาง คำนวณเวลา และดูงบประมาณบนมินิแมพ',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => widget.onSelectTab?.call(1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'จัดทริป',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_forward_rounded, size: 13, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
