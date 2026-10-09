import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/place_provider.dart';
import '../providers/trip_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Function(int)? onSelectTab;

  const ProfileScreen({super.key, this.onSelectTab});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final placeProvider = context.watch<PlaceProvider>();
    final tripProvider = context.watch<TripProvider>();
    final user = authProvider.currentUser;

    // Unauthenticated State (Clean & Minimal)
    if (!authProvider.isAuthenticated || user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
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
                      color: const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      size: 40,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'เข้าสู่ระบบสมาชิก',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'เข้าสู่ระบบเพื่อจัดการแผนการเดินทางและสถานที่โปรดของคุณ',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (ctx) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'เข้าสู่ระบบ / สมัครสมาชิก',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final totalStops = tripProvider.tripPlans.fold<int>(
      0,
      (sum, plan) => sum + plan.items.length,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Title Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'โปรไฟล์',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    onPressed: () => onSelectTab?.call(3),
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF475569),
                      size: 24,
                    ),
                    tooltip: 'การแจ้งเตือน',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. User Identity Card (Clean, Light & Modern)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
                          ),
                          alignment: Alignment.center,
                          child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Image.network(
                                    user.avatarUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Text(
                                  user.username.isNotEmpty
                                      ? user.username.substring(0, 1).toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),

                        // Name & Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.username,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email.isNotEmpty ? user.email : 'ยังไม่ระบุอีเมล',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              // Role Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: user.isAdmin
                                      ? const Color(0xFFFAF5FF)
                                      : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: user.isAdmin
                                        ? const Color(0xFFE9D5FF)
                                        : const Color(0xFFDBEAFE),
                                  ),
                                ),
                                child: Text(
                                  user.isAdmin ? 'ผู้ดูแลระบบ (Admin)' : 'นักเดินทาง KanG',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: user.isAdmin
                                        ? const Color(0xFF7C3AED)
                                        : const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 16),

                    // Metrics Row (Simple, Clean Numbers)
                    Row(
                      children: [
                        _buildStatColumn(
                          count: '${tripProvider.tripPlans.length}',
                          label: 'ทริปเดินทาง',
                          onTap: () => onSelectTab?.call(1),
                        ),
                        Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                        _buildStatColumn(
                          count: '${placeProvider.favoriteIds.length}',
                          label: 'สถานที่โปรด',
                          onTap: () => onSelectTab?.call(2),
                        ),
                        Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                        _buildStatColumn(
                          count: '$totalStops',
                          label: 'จุดหมายรวม',
                          onTap: () => onSelectTab?.call(1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Section: Travel Menu
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'การเดินทาง',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildRowItem(
                      icon: Icons.map_outlined,
                      title: 'แผนการเดินทางทั้งหมด',
                      trailingText: '${tripProvider.tripPlans.length} ทริป',
                      onTap: () => onSelectTab?.call(1),
                    ),
                    const Divider(height: 1, indent: 48, color: Color(0xFFF1F5F9)),
                    _buildRowItem(
                      icon: Icons.favorite_border_rounded,
                      title: 'สถานที่ที่บันทึกไว้',
                      trailingText: '${placeProvider.favoriteIds.length} แห่ง',
                      onTap: () => onSelectTab?.call(2),
                    ),
                    const Divider(height: 1, indent: 48, color: Color(0xFFF1F5F9)),
                    _buildRowItem(
                      icon: Icons.notifications_none_rounded,
                      title: 'การแจ้งเตือน',
                      onTap: () => onSelectTab?.call(3),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Section: Account & Settings
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'การตั้งค่าและระบบ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildRowItem(
                      icon: Icons.security_rounded,
                      title: 'ความปลอดภัยของบัญชี',
                      trailingText: 'JWT Protected',
                      onTap: () => _showSecurityDialog(context),
                    ),
                    const Divider(height: 1, indent: 48, color: Color(0xFFF1F5F9)),
                    _buildRowItem(
                      icon: Icons.language_rounded,
                      title: 'ภาษา',
                      trailingText: 'ไทย',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 48, color: Color(0xFFF1F5F9)),
                    _buildRowItem(
                      icon: Icons.info_outline_rounded,
                      title: 'เกี่ยวกับแอพพลิเคชัน',
                      trailingText: 'v1.0.0',
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. Logout Button (Clean, Subtle, Not aggressive)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFDC2626)),
                  label: const Text(
                    'ออกจากระบบ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    backgroundColor: const Color(0xFFFEF2F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _confirmLogout(context, authProvider),
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Stat Column
  Widget _buildStatColumn({
    required String count,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Text(
                count,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Row Item
  Widget _buildRowItem({
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: const Color(0xFF334155), size: 20),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFCBD5E1),
            size: 18,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  // Security Info Dialog
  void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('ความปลอดภัยของบัญชี', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'บัญชีของคุณเข้าสู่ระบบอย่างปลอดภัยด้วย JWT Token และข้อมูลถูกจัดเก็บบนเซิร์ฟเวอร์ฐานข้อมูลของ KanG',
          style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ตกลง', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // About Dialog
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('เกี่ยวกับ KanG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'KanG แพลตฟอร์มท่องเที่ยวจังหวัดกาญจนบุรี\nเวอร์ชัน 1.0.0',
          style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ปิด', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Logout Dialog
  Future<void> _confirmLogout(BuildContext context, AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('ยืนยันออกจากระบบ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ออกจากระบบ', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      authProvider.logout();
    }
  }
}
