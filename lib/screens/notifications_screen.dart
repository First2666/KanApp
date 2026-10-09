import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_item.dart';
import '../providers/auth_provider.dart';
import '../providers/place_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'place_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItemModel> _notifications = [];
  bool _isLoading = false;
  String _activeTab = 'all'; // 'all' or 'unread'

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) return;

    setState(() => _isLoading = true);
    try {
      final items = await ApiService.getNotifications();
      setState(() {
        _notifications = items;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    await ApiService.markAllNotificationsAsRead();
    _loadNotifications();
  }

  Future<void> _deleteNotification(int id) async {
    await ApiService.deleteNotification(id);
    setState(() {
      _notifications.removeWhere((item) => item.id == id);
    });
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diffSec = now.difference(dateTime).inSeconds;

    if (diffSec < 60) return 'เมื่อสักครู่';
    final diffMin = now.difference(dateTime).inMinutes;
    if (diffMin < 60) return '$diffMin นาทีที่แล้ว';
    final diffHour = now.difference(dateTime).inHours;
    if (diffHour < 24) return '$diffHour ชั่วโมงที่แล้ว';
    final diffDay = now.difference(dateTime).inDays;
    if (diffDay == 1) return 'เมื่อวานนี้';
    if (diffDay < 7) return '$diffDay วันที่แล้ว';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year + 543}';
  }

  NotificationTypeConfig _getTypeConfig(int type) {
    switch (type) {
      case 0: // TripReminder
        return NotificationTypeConfig(
          icon: Icons.calendar_month_rounded,
          bgColor: const Color(0xFFEFF6FF),
          iconColor: const Color(0xFF2563EB),
          label: 'ทริปเดินทาง',
        );
      case 1: // BudgetAlert
        return NotificationTypeConfig(
          icon: Icons.warning_amber_rounded,
          bgColor: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFD97706),
          label: 'งบประมาณ',
        );
      case 2: // NewEvent
        return NotificationTypeConfig(
          icon: Icons.auto_awesome_rounded,
          bgColor: const Color(0xFFF3E8FF),
          iconColor: const Color(0xFF9333EA),
          label: 'กิจกรรมใหม่',
        );
      case 3: // CrowdAlert
        return NotificationTypeConfig(
          icon: Icons.people_alt_rounded,
          bgColor: const Color(0xFFFFE4E6),
          iconColor: const Color(0xFFE11D48),
          label: 'ความหนาแน่น',
        );
      default:
        return NotificationTypeConfig(
          icon: Icons.notifications_rounded,
          bgColor: const Color(0xFFF1F5F9),
          iconColor: const Color(0xFF64748B),
          label: 'แจ้งเตือน',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isAuthenticated && _notifications.isEmpty && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && authProvider.isAuthenticated && _notifications.isEmpty && !_isLoading) {
          _loadNotifications();
        }
      });
    }

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'การแจ้งเตือน',
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
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFDBEAFE), width: 2),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 36,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'เข้าสู่ระบบเพื่อรับการแจ้งเตือน',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'รับข้อมูลอัปเดตทริป สถานที่ใหม่ และการแจ้งเตือนงบประมาณแบบเรียลไทม์',
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
                        'เข้าสู่ระบบ',
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

    final unreadCount = _notifications.where((n) => !n.isRead).length;
    final displayedList = _activeTab == 'unread'
        ? _notifications.where((n) => !n.isRead).toList()
        : _notifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            const Text(
              'การแจ้งเตือน',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _markAllRead,
                icon: const Icon(Icons.done_all_rounded, size: 16, color: Color(0xFF2563EB)),
                label: const Text(
                  'อ่านทั้งหมด',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs (ทั้งหมด / ยังไม่ได้อ่าน)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                _buildTabButton(
                  id: 'all',
                  label: 'ทั้งหมด',
                  count: _notifications.length,
                ),
                const SizedBox(width: 8),
                _buildTabButton(
                  id: 'unread',
                  label: 'ยังไม่ได้อ่าน',
                  count: unreadCount,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Notification List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadNotifications,
              color: const Color(0xFF2563EB),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                    )
                  : displayedList.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.notifications_off_outlined,
                                      size: 36,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _activeTab == 'unread'
                                        ? 'ไม่มีข้อความที่ยังไม่ได้อ่าน'
                                        : 'ไม่มีการแจ้งเตือนในขณะนี้',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'ระบบจะแจ้งเตือนเมื่อมีกิจกรรม อัปเดตทริป หรือข่าวสารใหม่ๆ',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: displayedList.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (context, idx) {
                            final item = displayedList[idx];
                            final config = _getTypeConfig(item.type);

                            return Dismissible(
                              key: Key('notif_${item.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: const Color(0xFFEF4444),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                              ),
                              onDismissed: (_) => _deleteNotification(item.id),
                              child: InkWell(
                                onTap: () async {
                                  if (!item.isRead) {
                                    await ApiService.markNotificationAsRead(item.id);
                                    _loadNotifications();
                                  }
                                  if (item.relatedPlaceId != null && context.mounted) {
                                    final placeProvider = context.read<PlaceProvider>();
                                    final match = placeProvider.places.where((p) => p.id == item.relatedPlaceId).firstOrNull;
                                    if (match != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PlaceDetailScreen(place: match),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  color: item.isRead
                                      ? Colors.white
                                      : const Color(0xFFEFF6FF).withValues(alpha: 0.5),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Type Icon badge
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: config.bgColor,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          config.icon,
                                          color: config.iconColor,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      // Content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.title,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: item.isRead
                                                          ? FontWeight.w700
                                                          : FontWeight.w900,
                                                      color: const Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                ),
                                                if (!item.isRead)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF2563EB),
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                                                          blurRadius: 4,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.message,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: const Color(0xFF475569),
                                                height: 1.4,
                                                fontWeight: item.isRead
                                                    ? FontWeight.normal
                                                    : FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF1F5F9),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    config.label,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w800,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '•  ${_formatRelativeTime(item.createdAt)}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF94A3B8),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const Spacer(),
                                                IconButton(
                                                  icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  splashRadius: 16,
                                                  onPressed: () => _deleteNotification(item.id),
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
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String id,
    required String label,
    required int count,
  }) {
    final isSelected = _activeTab == id;

    return GestureDetector(
      onTap: () => setState(() => _activeTab = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NotificationTypeConfig {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final String label;

  NotificationTypeConfig({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.label,
  });
}

