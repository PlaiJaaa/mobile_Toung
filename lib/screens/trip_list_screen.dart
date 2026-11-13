import 'package:flutter/material.dart';

import '../constant/app_constant.dart';
import '../model/checklist_data.dart';
import '../model/destination_data.dart';
import '../model/expense_data.dart';
import '../model/trip_data.dart';
import '../service/checklist_service.dart';
import '../service/destination_service.dart';
import '../service/expense_service.dart';
import '../service/trip_service.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/reminder_banner.dart';
import '../widgets/section_title.dart';
import '../widgets/trip_card.dart';
import 'trip_detail_screen.dart';
import 'trip_form_screen.dart';

// หน้ารายการทริป แยก "กำลังจะไป" กับ "ไปแล้ว"
// ถ้าเหลือไม่เกิน 3 วันก่อนเดินทาง จะขึ้นแถบเตือนของที่ยังไม่ได้เตรียม
class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  final TripService tripService = TripService();
  final DestinationService destinationService = DestinationService();
  final ExpenseService expenseService = ExpenseService();
  final ChecklistService checklistService = ChecklistService();

  List<TripData> _trips = [];
  List<DestinationData> _destinations = [];
  List<ExpenseData> _expenses = []; // รายจ่ายของทุกทริป ใช้คำนวณงบที่ใช้ไป
  List<ChecklistData> _checklist = []; // เช็กลิสต์ของทุกทริป ใช้นับของที่ยังไม่เตรียม
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // โหลดข้อมูล 4 ชุดพร้อมกันด้วย Future.wait (GET ทั้งหมด)
  Future<void> loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      List<dynamic> results = await Future.wait([
        tripService.getTrips(),
        destinationService.getDestinations(),
        expenseService.getAllExpenses(),
        checklistService.getAllItems(),
      ]);
      if (!mounted) return;
      setState(() {
        _trips = results[0];
        _destinations = results[1];
        _expenses = results[2];
        _checklist = results[3];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // ทริปที่ยังไม่จบ เรียงวันไปใกล้สุดขึ้นก่อน
  List<TripData> get upcomingTrips {
    List<TripData> list = _trips.where((TripData t) => !t.isPast).toList();
    list.sort((a, b) => a.startDate.compareTo(b.startDate));
    return list;
  }

  // ทริปที่จบแล้ว เรียงล่าสุดขึ้นก่อน
  List<TripData> get pastTrips {
    List<TripData> list = _trips.where((TripData t) => t.isPast).toList();
    list.sort((a, b) => b.startDate.compareTo(a.startDate));
    return list;
  }

  // ทริปที่เหลือ 0-3 วันก่อนออกเดินทาง (ใช้แสดงแถบเตือน)
  List<TripData> get soonTrips {
    return upcomingTrips
        .where(
          (TripData t) =>
              t.daysUntilStart >= 0 && t.daysUntilStart <= reminderDays,
        )
        .toList();
  }

  DestinationData? destinationOf(TripData trip) {
    return DestinationService.findById(_destinations, trip.destinationId);
  }

  // ---------- ไปหน้าอื่น ----------

  // สร้างทริปใหม่ผ่าน named route (ฟอร์มส่งทริปที่สร้างแล้วกลับมา)
  Future<void> openCreateForm() async {
    final result = await Navigator.pushNamed(context, '/trip-form');
    if (result != null) loadData();
  }

  // แก้ไขทริป: ส่งทริปเดิมให้ฟอร์มผ่าน constructor
  Future<void> openEditForm(TripData trip) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TripFormScreen(trip: trip, defaultCurrency: trip.currency),
      ),
    );
    if (result != null) loadData();
  }

  // เปิดหน้ารายละเอียดทริป (initialTab = แท็บที่จะเปิดก่อน เช่น 2 = เช็กลิสต์)
  Future<void> openDetail(TripData trip, {int initialTab = 0}) async {
    DestinationData? destination = destinationOf(trip);
    if (destination == null) {
      showErrorSnackBar(context, 'ไม่พบข้อมูลปลายทางของทริปนี้');
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripDetailScreen(
          trip: trip,
          destination: destination,
          initialTab: initialTab,
        ),
      ),
    );
    // กลับมาแล้วโหลดใหม่ เพราะอาจมีการเพิ่มรายจ่ายหรือติ๊กเช็กลิสต์
    loadData();
  }

  // ลบทริป: ถามยืนยันด้วย Dialog ก่อน
  Future<void> deleteTrip(TripData trip) async {
    bool confirmed = await showConfirmDialog(
      context,
      title: 'ลบทริปนี้?',
      message:
          'ทริป "${trip.name}" รวมทั้งกิจกรรม รายจ่าย และเช็กลิสต์ทั้งหมดของทริปนี้จะถูกลบ และกู้คืนไม่ได้',
      confirmText: 'ลบทริป',
    );
    if (!confirmed) return;

    try {
      await tripService.deleteTrip(trip.id);
      if (!mounted) return;
      showSuccessSnackBar(context, 'ลบทริป "${trip.name}" เรียบร้อย');
      loadData();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ทริปของฉัน')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openCreateForm,
        icon: const Icon(Icons.add_rounded),
        label: const Text('สร้างทริป'),
      ),
      body: RefreshIndicator(onRefresh: loadData, child: buildBody()),
    );
  }

  Widget buildBody() {
    if (_isLoading) {
      return const LoadingView();
    }
    // ใส่ใน ListView เพื่อให้ดึงลงโหลดใหม่ได้ แม้จะเป็นหน้า error หรือหน้าว่าง
    if (_errorMessage != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          ErrorView(message: _errorMessage!, onRetry: loadData),
        ],
      );
    }
    if (_trips.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          EmptyView(
            icon: Icons.flight_takeoff_rounded,
            title: 'ยังไม่มีทริป',
            message: 'กดปุ่ม "สร้างทริป" ด้านล่างเพื่อเริ่มวางแผนเที่ยว',
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        // ---------- แถบเตือนก่อนเดินทาง ----------
        for (TripData trip in soonTrips)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ReminderBanner(
              tripName: trip.name,
              daysUntilStart: trip.daysUntilStart,
              unpackedCount: ChecklistData.countUnpacked(_checklist, trip.id),
              onTap: () => openDetail(trip, initialTab: 2),
            ),
          ),

        // ---------- กำลังจะไป ----------
        SectionTitle(title: 'กำลังจะไป (${upcomingTrips.length})'),
        const SizedBox(height: 8),
        if (upcomingTrips.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('ยังไม่มีทริปที่กำลังจะไป'),
          ),
        for (TripData trip in upcomingTrips) buildTripCard(trip),

        // ---------- ไปแล้ว ----------
        if (pastTrips.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionTitle(title: 'ไปแล้ว (${pastTrips.length})'),
          const SizedBox(height: 8),
          for (TripData trip in pastTrips) buildTripCard(trip),
        ],
      ],
    );
  }

  Widget buildTripCard(TripData trip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TripCard(
        trip: trip,
        destination: destinationOf(trip),
        spent: ExpenseData.totalOfTrip(_expenses, trip.id),
        onTap: () => openDetail(trip),
        onEdit: () => openEditForm(trip),
        onDelete: () => deleteTrip(trip),
      ),
    );
  }
}
