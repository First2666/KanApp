import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/place_provider.dart';
import '../widgets/place_card.dart';
import '../widgets/grid_place_card.dart';
import 'login_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  bool _isGridView = true;
  int _currentPage = 1;
  static const int _itemsPerPage = 8; // 2 columns x 4 rows

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _changePage(int page) {
    setState(() => _currentPage = page);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final placeProvider = context.watch<PlaceProvider>();

    if (authProvider.isAuthenticated && placeProvider.favoriteIds.isEmpty && !placeProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && authProvider.isAuthenticated && !placeProvider.isLoading) {
          placeProvider.fetchFavorites(authProvider.currentUser!.id);
        }
      });
    }

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'รายการโปรด',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          centerTitle: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFEE2E2), width: 2),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 36,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'เข้าสู่ระบบเพื่อดูรายการโปรด',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'บันทึกสถานที่ที่คุณชื่นชอบเพื่อวางแผนเที่ยวและค้นหาได้สะดวกยิ่งขึ้น',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: const Text(
                        'เข้าสู่ระบบ / สมัครสมาชิก',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (ctx) => const LoginScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final allFavorites = placeProvider.favoritePlaces;

    final filteredFavorites = allFavorites.where((p) {
      final matchesCategory =
          _selectedCategory == 'All' || p.placeType == _selectedCategory;
      final query = _searchQuery.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query) ||
          (p.address ?? '').toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    final totalItems = filteredFavorites.length;
    final totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 9999);
    final currentPage = _currentPage > totalPages ? totalPages : _currentPage;
    final startIndex = (currentPage - 1) * _itemsPerPage;
    final pagedFavorites = filteredFavorites.skip(startIndex).take(_itemsPerPage).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFEE2E2)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_rounded, size: 15, color: Color(0xFFEF4444)),
              SizedBox(width: 5),
              Text(
                'รายการโปรด',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (allFavorites.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Text(
                '${allFavorites.length} รายการ',
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // View Toggle (Grid / List)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        if (!_isGridView) {
                          setState(() => _isGridView = true);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isGridView ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _isGridView
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          Icons.grid_view_rounded,
                          size: 16,
                          color: _isGridView ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        if (_isGridView) {
                          setState(() => _isGridView = false);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: !_isGridView ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: !_isGridView
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          Icons.view_agenda_rounded,
                          size: 16,
                          color: !_isGridView ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2563EB),
        onRefresh: () async {
          if (authProvider.isAuthenticated) {
            await placeProvider.fetchFavorites(authProvider.currentUser!.id);
          }
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Header title + Search & Category Filters
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'สถานที่ที่คุณบันทึกไว้',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'รวมสถานที่ท่องเที่ยว ร้านอาหาร และที่พักที่คุณกดถูกใจไว้ทั้งหมด',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Search bar
                    if (allFavorites.isNotEmpty) ...[
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val;
                                    _currentPage = 1;
                                  });
                                },
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'ค้นหาชื่อ, ที่อยู่ในรายการโปรด...',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.normal,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _currentPage = 1;
                                  });
                                },
                                child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Category Filter Pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterTab(
                              id: 'All',
                              label: 'ทั้งหมด',
                              icon: Icons.auto_awesome_rounded,
                              activeColor: const Color(0xFF2563EB),
                              count: allFavorites.length,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterTab(
                              id: 'Attraction',
                              label: 'ที่เที่ยว',
                              icon: Icons.explore_rounded,
                              activeColor: const Color(0xFF059669),
                              count: allFavorites.where((p) => p.placeType == 'Attraction').length,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterTab(
                              id: 'Restaurant',
                              label: 'ร้านอาหาร',
                              icon: Icons.restaurant_rounded,
                              activeColor: const Color(0xFFEA580C),
                              count: allFavorites.where((p) => p.placeType == 'Restaurant').length,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterTab(
                              id: 'Accommodation',
                              label: 'ที่พัก',
                              icon: Icons.hotel_rounded,
                              activeColor: const Color(0xFF9333EA),
                              count: allFavorites.where((p) => p.placeType == 'Accommodation').length,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Body Content
            if (allFavorites.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFEE2E2), width: 2),
                          ),
                          child: const Icon(
                            Icons.favorite_border_rounded,
                            size: 40,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'ยังไม่มีสถานที่ที่คุณบันทึกไว้',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'กดที่ไอคอนรูปหัวใจบนการ์ดสถานที่ท่องเที่ยว\nร้านอาหาร หรือที่พัก เพื่อบันทึกไว้ดูภายหลัง',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (filteredFavorites.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.search_off_rounded,
                            size: 32,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'ไม่พบรายการโปรดที่ตรงกับ "$_searchQuery"'
                              : 'ไม่มีรายการในหมวดหมู่นี้',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'ลองค้นหาด้วยคำค้นอื่น หรือเปลี่ยนหมวดหมู่',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _selectedCategory = 'All';
                              _currentPage = 1;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            side: const BorderSide(color: Color(0xFF2563EB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('ล้างตัวกรองทั้งหมด'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              // Grid View (Default: 2 columns, 4 rows = 8 items)
              if (_isGridView)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.70,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final place = pagedFavorites[index];
                        return GridPlaceCard(place: place);
                      },
                      childCount: pagedFavorites.length,
                    ),
                  ),
                )
              else
                // List View
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final place = pagedFavorites[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PlaceCard(place: place),
                        );
                      },
                      childCount: pagedFavorites.length,
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
                          'หน้า $currentPage จาก $totalPages  •  ทั้งหมด $totalItems รายการ (หน้าละ $_itemsPerPage รายการ)',
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
                                    ? () => _changePage(currentPage - 1)
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
                                    onTap: () => _changePage(pageNum),
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
                                    ? () => _changePage(currentPage + 1)
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
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab({
    required String id,
    required String label,
    required IconData icon,
    required Color activeColor,
    required int count,
  }) {
    final isSelected = _selectedCategory == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = id;
          _currentPage = 1;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
