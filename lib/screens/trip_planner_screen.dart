import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/place_provider.dart';
import '../providers/trip_provider.dart';
import '../widgets/mini_map.dart';
import 'login_screen.dart';
import 'place_detail_screen.dart';

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.read<TripProvider>().loadUserTrips(auth.currentUser!.id);
      }
    });
  }

  void _showCreateTripModal(BuildContext context) {
    final nameController = TextEditingController(text: 'ทริปกาญจนบุรี');
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final diffDays = endDate.difference(startDate).inDays + 1;
            final durationText = diffDays <= 1
                ? '1 วัน (ไปเช้า-เย็นกลับ)'
                : '$diffDays วัน ${diffDays - 1} คืน';

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'สร้างทริปใหม่',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ชื่อทริป',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'เช่น ทริปกาญจนบุรี 2 วัน 1 คืน',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ระยะเวลาเดินทาง',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF475569),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          durationText,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 14),
                          label: Text(
                            'เริ่ม: ${startDate.day}/${startDate.month}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 30)),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setModalState(() {
                                startDate = picked;
                                if (endDate.isBefore(startDate)) {
                                  endDate =
                                      startDate.add(const Duration(days: 1));
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 14),
                          label: Text(
                            'จบ: ${endDate.day}/${endDate.month}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setModalState(() => endDate = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;
                        final messenger = ScaffoldMessenger.of(context);
                        final auth = context.read<AuthProvider>();
                        final trip = context.read<TripProvider>();
                        Navigator.pop(ctx);
                        final success = await trip.createNewTrip(
                          userId: auth.currentUser!.id,
                          name: nameController.text.trim(),
                          startDate: startDate,
                          endDate: endDate,
                        );
                        if (mounted && success) {
                          messenger.showSnackBar(
                            const SnackBar(
                                content: Text('สร้างทริปใหม่สำเร็จ!')),
                          );
                        }
                      },
                      child: const Text(
                        'สร้างทริป',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTripPickerSheet(BuildContext context, TripProvider trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'เลือกทริปของคุณ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: trip.tripPlans.length,
                      itemBuilder: (context, index) {
                        final plan = trip.tripPlans[index];
                        final isSelected = plan.id == trip.tripPlanId;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEFF6FF)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.backpack_rounded,
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          title: Text(
                            plan.planName,
                            style: TextStyle(
                              fontWeight:
                                  isSelected ? FontWeight.w900 : FontWeight.w700,
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          subtitle: Text(
                            '${plan.startDate.day}/${plan.startDate.month} - ${plan.endDate.day}/${plan.endDate.month}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF2563EB))
                              : null,
                          onTap: () {
                            trip.switchTrip(plan.id);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('สร้างทริปใหม่'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showCreateTripModal(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final trip = context.watch<TripProvider>();

    if (auth.isAuthenticated && trip.tripPlans.isEmpty && !trip.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && auth.isAuthenticated && trip.tripPlans.isEmpty && !trip.isLoading) {
          trip.loadUserTrips(auth.currentUser!.id);
        }
      });
    }

    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'แผนการเดินทาง',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
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
                      color: const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFFDBEAFE), width: 2),
                    ),
                    child: const Icon(
                      Icons.map_rounded,
                      size: 36,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'เข้าสู่ระบบเพื่อวางแผนเดินทาง',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'จัดสรรสถานที่ ดูมินิแมพเส้นทาง คำนวณเวลาเดินทาง และสรุปงบประมาณได้ง่ายๆ',
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
                      label: const Text('เข้าสู่ระบบ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
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

    final currentPlan = trip.currentPlan;
    final timelineItems = trip.timelineItems;
    final mapPlaces = currentPlan?.items
            .where((i) => i.place != null)
            .map((i) => i.place!)
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: GestureDetector(
          onTap: () => _showTripPickerSheet(context, trip),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    currentPlan?.planName ?? 'ทริปเดินทาง',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E40AF),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: Color(0xFF2563EB)),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: Color(0xFF2563EB)),
            tooltip: 'สร้างทริปใหม่',
            onPressed: () => _showCreateTripModal(context),
          ),
          if (currentPlan != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444)),
              tooltip: 'ลบทริปนี้',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('ลบทริปการเดินทาง?'),
                    content: const Text(
                        'ข้อมูลและสถานที่ในทริปนี้จะถูกลบทั้งหมด ยืนยันหรือไม่?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('ยกเลิก'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444)),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('ลบทริป',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await trip.deleteCurrentTrip(auth.currentUser!.id);
                }
              },
            ),
        ],
      ),
      body: trip.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : timelineItems.isEmpty
              ? _buildEmptyState(context)
              : CustomScrollView(
                  slivers: [
                    // Mini Map Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: MiniMapWidget(
                          places: mapPlaces,
                          activeStep: trip.activeStep,
                          height: 240,
                          userLocation: trip.isUsingGps &&
                                  trip.userLatitude != null
                              ? LatLng(trip.userLatitude!, trip.userLongitude!)
                              : null,
                          onToggleGps: () {
                            trip.toggleGps();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(trip.isUsingGps
                                    ? 'เปิดระบบระบุตำแหน่ง GPS เรียบร้อย (เริ่มจากตำแหน่งของคุณ)'
                                    : 'ปิดระบบระบุตำแหน่ง GPS แล้ว'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Trip Status / Header Controls
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              // Completed Banner
                              if (trip.isTripCompleted) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: const Color(0xFFA7F3D0)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          color: Color(0xFF059669), size: 24),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Text(
                                          'จบทริปสมบูรณ์! เช็คอินครบทุกจุดหมายแล้ว ',
                                          style: TextStyle(
                                            color: Color(0xFF065F46),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: trip.resetCheckIn,
                                        child: const Text('รีเซ็ต',
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // 1. Top Row: Departure Time Selector & Check-in Badge
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule_rounded,
                                          size: 18, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'เริ่มออกเดินทาง:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () async {
                                          final parts =
                                              trip.tripStartTime.split(':');
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay(
                                              hour: int.tryParse(parts[0]) ?? 8,
                                              minute:
                                                  int.tryParse(parts[1]) ?? 0,
                                            ),
                                          );
                                          if (picked != null) {
                                            final h = picked.hour
                                                .toString()
                                                .padLeft(2, '0');
                                            final m = picked.minute
                                                .toString()
                                                .padLeft(2, '0');
                                            trip.setStartTime('$h:$m');
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: const Color(0xFFBFDBFE)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${trip.tripStartTime} น.',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF2563EB),
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              const Icon(
                                                  Icons.arrow_drop_down_rounded,
                                                  size: 16,
                                                  color: Color(0xFF2563EB)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Check-in Progress Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 13,
                                          color: trip.activeStep > 0
                                              ? const Color(0xFF059669)
                                              : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'เช็คอิน ${trip.activeStep}/${trip.itemCount}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // 2. Bottom Row: GPS Live Navigation Toggle Card
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  trip.toggleGps();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(trip.isUsingGps
                                          ? 'เปิดระบบ GPS นำทางจากตำแหน่งปัจจุบันแล้ว'
                                          : 'ปิดระบบ GPS แล้ว'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: trip.isUsingGps
                                        ? const Color(0xFFECFDF5)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: trip.isUsingGps
                                          ? const Color(0xFFA7F3D0)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            trip.isUsingGps
                                                ? Icons.gps_fixed_rounded
                                                : Icons.gps_not_fixed_rounded,
                                            size: 15,
                                            color: trip.isUsingGps
                                                ? const Color(0xFF059669)
                                                : const Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            trip.isUsingGps
                                                ? 'นำทางด้วย GPS จากตำแหน่งจริงของคุณ'
                                                : 'นำทางด้วย GPS จากตำแหน่งปัจจุบัน',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: trip.isUsingGps
                                                  ? const Color(0xFF065F46)
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: trip.isUsingGps
                                              ? const Color(0xFF059669)
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: trip.isUsingGps
                                                ? const Color(0xFF059669)
                                                : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        child: Text(
                                          trip.isUsingGps
                                              ? 'เปิดอยู่'
                                              : 'เปิด GPS',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: trip.isUsingGps
                                                ? Colors.white
                                                : const Color(0xFF475569),
                                          ),
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
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 14)),

                    // Timeline Cards
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, idx) {
                          final item = timelineItems[idx];
                          return _buildTimelineCard(
                              context, item, trip, idx, timelineItems.length);
                        },
                        childCount: timelineItems.length,
                      ),
                    ),

                    // Cost Breakdown Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: _buildCostSummary(trip),
                      ),
                    ),

                    // Quick Add Category Chips
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                        child: _buildQuickAddSection(context),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.alt_route_rounded,
                size: 40,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ยังไม่มีสถานที่ในแผนการเดินทาง',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'เลือกสถานที่ที่คุณสนใจในหน้าแรก หรือหน้าค้นหา\nแล้วกด "จัดลงทริป" เพื่อเริ่มวางแผนเส้นทาง',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.explore_rounded, size: 18),
              label: const Text('ค้นหาสถานที่ท่องเที่ยว'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(
    BuildContext context,
    TripTimelineItem item,
    TripProvider trip,
    int index,
    int totalCount,
  ) {
    Color typeColor;
    switch (item.place.placeType) {
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

    final isPassed = index < trip.activeStep;
    final isCurrent = index == trip.activeStep;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          // Travel distance from prev stop or current GPS
          if (index > 0 || (index == 0 && trip.isUsingGps))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Container(
                      width: 2, height: 24, color: const Color(0xFFCBD5E1)),
                  const SizedBox(width: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: index == 0
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: index == 0
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          index == 0
                              ? Icons.gps_fixed_rounded
                              : Icons.directions_car_rounded,
                          size: 12,
                          color: index == 0
                              ? const Color(0xFF059669)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          index == 0
                              ? 'จากตำแหน่งของคุณ: ${item.distanceKm.toStringAsFixed(1)} กม. (~${item.travelMinutes} นาที)'
                              : '${item.distanceKm.toStringAsFixed(1)} กม. (~${item.travelMinutes} นาที)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: index == 0
                                ? const Color(0xFF059669)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Place Card in Timeline
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCurrent
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE2E8F0),
                width: isCurrent ? 1.8 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isCurrent
                      ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Number badge
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isPassed
                            ? const Color(0xFF059669)
                            : (isCurrent ? typeColor : const Color(0xFF64748B)),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isPassed
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Place Thumbnail
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PlaceDetailScreen(place: item.place),
                          ),
                        );
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: typeColor.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.5),
                          child: Image.network(
                            item.place.primaryImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFF1F5F9),
                              child: Icon(
                                Icons.photo_outlined,
                                size: 20,
                                color: typeColor.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Place Title & Type
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlaceDetailScreen(place: item.place),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.place.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.place.address ?? 'กาญจนบุรี',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Reorder & Delete actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (index > 0)
                          IconButton(
                            icon: const Icon(Icons.arrow_upward_rounded,
                                size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => trip.reorderItem(index, index - 1),
                          ),
                        const SizedBox(width: 6),
                        if (index < totalCount - 1)
                          IconButton(
                            icon: const Icon(Icons.arrow_downward_rounded,
                                size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => trip.reorderItem(index, index + 1),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: Color(0xFFEF4444)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => trip.removeTripItem(item.rawItem.id),
                        ),
                      ],
                    ),
                  ],
                ),

                const Divider(height: 18, color: Color(0xFFF1F5F9)),

                // Schedule times row & Operating Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.arriveTime} → ${item.leaveTime}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.statusMessage,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: item.operatingStatus == 'closed'
                              ? const Color(0xFFDC2626)
                              : (item.operatingStatus == 'warning'
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF059669)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Cost & Check In Action Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Estimated Cost field
                    Row(
                      children: [
                        const Text(
                          'ค่าใช้จ่าย:',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '฿${item.rawItem.estimatedCost.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Check-in Button
                    if (isCurrent && !trip.isTripCompleted)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                        onPressed: () => trip.handleCheckIn(index),
                        child: const Text('✓ เช็คอินถึงแล้ว'),
                      )
                    else if (isPassed)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: const Text(
                              'ผ่านแล้ว',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                          if (index == trip.activeStep - 1)
                            IconButton(
                              icon: const Icon(Icons.undo_rounded,
                                  size: 16, color: Color(0xFF94A3B8)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: trip.undoCheckIn,
                              tooltip: 'ย้อนกลับการเช็คอิน',
                            ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostSummary(TripProvider trip) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'สรุปงบประมาณทริป',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${trip.itemCount} สถานที่',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCostCategoryItem(
                  label: 'ค่าเข้าชม',
                  amount: trip.attractionCost,
                  icon: Icons.explore_rounded,
                  color: const Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCostCategoryItem(
                  label: 'ค่าอาหาร',
                  amount: trip.restaurantCost,
                  icon: Icons.restaurant_rounded,
                  color: const Color(0xFFEA580C),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCostCategoryItem(
                  label: 'ค่าที่พัก',
                  amount: trip.accommodationCost,
                  icon: Icons.hotel_rounded,
                  color: const Color(0xFF9333EA),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'รวมค่าใช้จ่ายทั้งหมด',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                ),
              ),
              Text(
                '฿${trip.totalCost.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostCategoryItem({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            '฿${amount.toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddSection(BuildContext context) {
    final placeProvider = context.read<PlaceProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'เพิ่มสถานที่ลงในทริปนี้',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildQuickAddBtn(
                label: 'ที่เที่ยว',
                color: const Color(0xFF059669),
                icon: Icons.explore_rounded,
                onTap: () {
                  placeProvider.setCategory('Attraction');
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickAddBtn(
                label: 'ร้านอาหาร',
                color: const Color(0xFFEA580C),
                icon: Icons.restaurant_rounded,
                onTap: () {
                  placeProvider.setCategory('Restaurant');
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickAddBtn(
                label: 'ที่พัก',
                color: const Color(0xFF9333EA),
                icon: Icons.hotel_rounded,
                onTap: () {
                  placeProvider.setCategory('Accommodation');
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAddBtn({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
