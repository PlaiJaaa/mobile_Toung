import 'package:flutter/material.dart';

import '../constant/app_format.dart';
import '../model/destination_data.dart';
import '../model/trip_data.dart';
import '../service/destination_service.dart';
import '../widgets/destination_image.dart';
import 'checklist_tab.dart';
import 'expense_tab.dart';
import 'plan_tab.dart';
import 'trip_form_screen.dart';
import 'weather_tab.dart';

// หน้ารายละเอียดทริป แบ่งเป็น 4 แท็บด้วย TabBar (บทที่ 3)
// แผนรายวัน / ค่าใช้จ่าย / เช็กลิสต์ / สภาพอากาศ
class TripDetailScreen extends StatefulWidget {
  final TripData trip; // ทริปที่เปิดดู (รับมาจากหน้ารายการผ่าน constructor)
  final DestinationData destination; // ปลายทางของทริป
  final int initialTab; // แท็บที่เปิดก่อน (0 = แผนรายวัน, 2 = เช็กลิสต์)

  const TripDetailScreen({
    super.key,
    required this.trip,
    required this.destination,
    this.initialTab = 0,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late TripData _trip; // เก็บไว้ใน state เพราะแก้ไขทริปแล้วต้องแสดงค่าใหม่
  late DestinationData _destination;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _destination = widget.destination;
  }

  // แก้ไขทริปจากหน้านี้ แล้วอัปเดตข้อมูลที่แสดง
  Future<void> openEditForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TripFormScreen(trip: _trip, defaultCurrency: _trip.currency),
      ),
    );
    if (result is! TripData) return;

    // ถ้าเปลี่ยนปลายทาง ต้องหาข้อมูลปลายทางใหม่ (ใช้รูปและพิกัดใหม่)
    DestinationData destination = _destination;
    if (result.destinationId != _destination.id) {
      try {
        List<DestinationData> list = await DestinationService()
            .getDestinations();
        destination =
            DestinationService.findById(list, result.destinationId) ??
            destination;
      } catch (e) {
        // โหลดไม่สำเร็จ ใช้ปลายทางเดิมไปก่อน กลับไปหน้ารายการจะโหลดใหม่เอง
      }
    }
    if (!mounted) return;
    setState(() {
      _trip = result;
      _destination = destination;
    });
  }

  // แท็บเช็กลิสต์เรียกเมื่อบันทึกรายการที่ปัดทิ้ง เพื่อให้ข้อมูลทริปตรงกับ server
  void onTripChanged(TripData trip) {
    setState(() {
      _trip = trip;
    });
  }

  @override
  Widget build(BuildContext context) {
    // key ของแต่ละแท็บผูกกับข้อมูลทริปที่มีผล เมื่อแก้ไขทริปแท็บจะสร้างใหม่และโหลดข้อมูลใหม่
    final String tripKey =
        '${_trip.destinationId}-${toDateKey(_trip.startDate)}-'
        '${toDateKey(_trip.endDate)}-${_trip.budget}-${_trip.currency}';

    return DefaultTabController(
      length: 4,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              // รูปปลายทางเล็ก ๆ ข้างชื่อทริป
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: DestinationImage(image: _destination.image),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _trip.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18),
                    ),
                    Text(
                      '${_destination.fullName} · '
                      '${formatDateRange(_trip.startDate, _trip.endDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'แก้ไขทริป',
              icon: const Icon(Icons.edit_outlined),
              onPressed: openEditForm,
            ),
          ],
          // แท็บ 4 อันแบ่งความกว้างเท่ากัน เห็นครบทุกแท็บโดยไม่ต้องเลื่อน
          bottom: const TabBar(
            labelPadding: EdgeInsets.symmetric(horizontal: 4),
            labelStyle: TextStyle(
              fontFamily: 'Prompt',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(fontFamily: 'Prompt', fontSize: 13),
            tabs: [
              Tab(icon: Icon(Icons.event_note_rounded), text: 'แผนรายวัน'),
              Tab(icon: Icon(Icons.payments_outlined), text: 'ค่าใช้จ่าย'),
              Tab(icon: Icon(Icons.checklist_rounded), text: 'เช็กลิสต์'),
              Tab(icon: Icon(Icons.wb_sunny_outlined), text: 'สภาพอากาศ'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PlanTab(key: ValueKey('plan-$tripKey'), trip: _trip),
            ExpenseTab(key: ValueKey('expense-$tripKey'), trip: _trip),
            ChecklistTab(
              key: ValueKey('checklist-$tripKey'),
              trip: _trip,
              destination: _destination,
              onTripChanged: onTripChanged,
            ),
            WeatherTab(
              key: ValueKey('weather-$tripKey'),
              trip: _trip,
              destination: _destination,
            ),
          ],
        ),
      ),
    );
  }
}
