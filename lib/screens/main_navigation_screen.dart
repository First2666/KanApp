import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/place_provider.dart';
import '../providers/trip_provider.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'trip_planner_screen.dart';
import 'favorites_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _unreadCount = 0;
  int? _lastLoadedUserId;

  void _selectTab(int index) {
    if (mounted) {
      setState(() => _currentIndex = index);
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        final uid = auth.currentUser!.id;
        if (index == 1) {
          context.read<TripProvider>().loadUserTrips(uid);
        } else if (index == 2) {
          context.read<PlaceProvider>().fetchFavorites(uid);
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final placeProvider = context.read<PlaceProvider>();
      placeProvider.fetchPlaces();

      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        _lastLoadedUserId = authProvider.currentUser!.id;
        placeProvider.fetchFavorites(authProvider.currentUser!.id);
        context.read<TripProvider>().loadUserTrips(authProvider.currentUser!.id);
      }
      _fetchUnreadCount();
    });
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final count = await ApiService.getUnreadNotificationCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final trip = context.watch<TripProvider>();

    if (auth.isAuthenticated && _lastLoadedUserId != auth.currentUser!.id) {
      _lastLoadedUserId = auth.currentUser!.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && auth.isAuthenticated) {
          final uid = auth.currentUser!.id;
          context.read<PlaceProvider>().fetchFavorites(uid);
          context.read<TripProvider>().loadUserTrips(uid);
          _fetchUnreadCount();
        }
      });
    } else if (!auth.isAuthenticated && _lastLoadedUserId != null) {
      _lastLoadedUserId = null;
    }

    final screens = [
      HomeScreen(onSelectTab: _selectTab),
      const TripPlannerScreen(),
      const FavoritesScreen(),
      const NotificationsScreen(),
      ProfileScreen(onSelectTab: _selectTab),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          // กลับไปหน้าแรกก่อน
          setState(() => _currentIndex = 0);
        } else {
          // ถ้าอยู่หน้าแรกแล้ว → ถามยืนยันออกจากแอพ
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('ออกจากแอพ?', style: TextStyle(fontWeight: FontWeight.w800)),
              content: const Text('คุณต้องการออกจากแอพ KanG หรือไม่?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('ยกเลิก'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  child: const Text('ออก'),
                ),
              ],
            ),
          );
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'หน้าแรก',
                  activeColor: const Color(0xFF2563EB), // Blue 600
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.alt_route_outlined,
                  activeIcon: Icons.alt_route_rounded,
                  label: 'แผนเดินทาง',
                  activeColor: const Color(0xFF2563EB),
                  badgeCount: trip.itemCount,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.favorite_border_rounded,
                  activeIcon: Icons.favorite_rounded,
                  label: 'รายการโปรด',
                  activeColor: const Color(0xFFEF4444), // Red 500
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.notifications_none_rounded,
                  activeIcon: Icons.notifications_rounded,
                  label: 'แจ้งเตือน',
                  activeColor: const Color(0xFFF59E0B), // Amber 500
                  badgeCount: _unreadCount,
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'โปรไฟล์',
                  activeColor: const Color(0xFF2563EB),
                ),
              ],
            ),
          ),
        ),
      ),
      ), // close Scaffold
    ); // close PopScope
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color activeColor,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() => _currentIndex = index);
        if (index == 3) _fetchUnreadCount();
        final auth = context.read<AuthProvider>();
        if (auth.isAuthenticated) {
          final uid = auth.currentUser!.id;
          if (index == 1) {
            context.read<TripProvider>().loadUserTrips(uid);
          } else if (index == 2) {
            context.read<PlaceProvider>().fetchFavorites(uid);
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 24,
                  color: isSelected ? activeColor : const Color(0xFF94A3B8),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? activeColor : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
