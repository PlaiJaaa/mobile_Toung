import 'package:flutter/material.dart';

import '../constant/app_format.dart';
import '../model/activity_data.dart';
import '../model/trip_data.dart';
import '../service/activity_service.dart';
import '../widgets/activity_tile.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import 'activity_form_screen.dart';

// แท็บแผนรายวัน: กิจกรรมแยกตามวันของทริป เพิ่ม แก้ ลบ และติ๊กว่าทำแล้วได้
class PlanTab extends StatefulWidget {
  final TripData trip;

  const PlanTab({super.key, required this.trip});

  @override
  State<PlanTab> createState() => _PlanTabState();
}

// AutomaticKeepAliveClientMixin: สลับแท็บไปมาแล้วไม่ต้องโหลดข้อมูลใหม่
class _PlanTabState extends State<PlanTab> with AutomaticKeepAliveClientMixin {
  final ActivityService activityService = ActivityService();

  List<ActivityData> _activities = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    loadActivities();
  }

  // GET /activities?tripId=...
  Future<void> loadActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      List<ActivityData> list = await activityService.getActivities(
        widget.trip.id,
      );
      if (!mounted) return;
      setState(() {
        _activities = list;
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

  // กิจกรรมของวันที่ระบุ (กรองด้วย where)
  List<ActivityData> activitiesOfDay(int day) {
    return _activities.where((ActivityData a) => a.day == day).toList();
  }

  // กิจกรรมที่อยู่นอกช่วงวันของทริป (เช่น แก้ทริปให้สั้นลงภายหลัง)
  List<ActivityData> get outOfRangeActivities {
    return _activities
        .where((ActivityData a) => a.day < 1 || a.day > widget.trip.dayCount)
        .toList();
  }

  // ติ๊กว่าทำแล้ว: เปลี่ยนบนจอทันที แล้ว PATCH ไป server ถ้าไม่สำเร็จเปลี่ยนกลับ
  Future<void> toggleDone(ActivityData activity, bool isDone) async {
    setState(() {
      replaceActivity(activity, isDone);
    });
    try {
      await activityService.setDone(activity.id, isDone);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        replaceActivity(activity, !isDone);
      });
      showErrorSnackBar(context, e.toString());
    }
  }

  // แทนกิจกรรมในรายการด้วยตัวใหม่ที่สถานะ isDone เปลี่ยนไป
  void replaceActivity(ActivityData activity, bool isDone) {
    int index = _activities.indexWhere((a) => a.id == activity.id);
    if (index < 0) return;
    _activities[index] = ActivityData(
      id: activity.id,
      tripId: activity.tripId,
      day: activity.day,
      time: activity.time,
      title: activity.title,
      place: activity.place,
      category: activity.category,
      note: activity.note,
      isDone: isDone,
    );
  }

  // เปิดฟอร์มเพิ่ม (activity = null) หรือแก้ไขกิจกรรม
  Future<void> openForm({ActivityData? activity, int day = 1}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityFormScreen(
          trip: widget.trip,
          activity: activity,
          initialDay: day,
        ),
      ),
    );
    if (result == true) loadActivities();
  }

  Future<void> deleteActivity(ActivityData activity) async {
    bool confirmed = await showConfirmDialog(
      context,
      title: 'ลบกิจกรรมนี้?',
      message: '"${activity.title}" จะถูกลบออกจากแผนเที่ยว',
    );
    if (!confirmed) return;

    try {
      await activityService.deleteActivity(activity.id);
      if (!mounted) return;
      showSuccessSnackBar(context, 'ลบกิจกรรมเรียบร้อย');
      loadActivities();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // จำเป็นสำหรับ AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _errorMessage == null && !_isLoading
          ? FloatingActionButton.extended(
              heroTag: 'add-activity',
              onPressed: () => openForm(day: suggestDay()),
              icon: const Icon(Icons.add_rounded),
              label: const Text('เพิ่มกิจกรรม'),
            )
          : null,
      body: RefreshIndicator(onRefresh: loadActivities, child: buildBody()),
    );
  }

  // วันเริ่มต้นของฟอร์ม: ถ้ากำลังเที่ยวอยู่ใช้วันนี้ ไม่อย่างนั้นใช้วันแรก
  int suggestDay() {
    int day = today().difference(widget.trip.startDate).inDays + 1;
    if (day < 1 || day > widget.trip.dayCount) return 1;
    return day;
  }

  Widget buildBody() {
    if (_isLoading) {
      return const LoadingView();
    }
    if (_errorMessage != null) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          ErrorView(message: _errorMessage!, onRetry: loadActivities),
        ],
      );
    }

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    int doneCount = _activities.where((ActivityData a) => a.isDone).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // สรุปความคืบหน้า
        Text(
          _activities.isEmpty
              ? 'ทริป ${widget.trip.dayCount} วัน · ยังไม่มีกิจกรรม เริ่มเพิ่มได้เลย'
              : 'ทริป ${widget.trip.dayCount} วัน · ทำแล้ว $doneCount จาก ${_activities.length} กิจกรรม',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),

        // แต่ละวันของทริป
        for (int day = 1; day <= widget.trip.dayCount; day++) ...[
          buildDayHeader(
            title: 'วันที่ $day',
            subtitle: formatDayDate(widget.trip.dateOfDay(day)),
            onAdd: () => openForm(day: day),
          ),
          if (activitiesOfDay(day).isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'ยังไม่มีกิจกรรม',
                style: TextStyle(color: colorScheme.outline),
              ),
            ),
          for (ActivityData activity in activitiesOfDay(day))
            buildTile(activity),
        ],

        // กิจกรรมที่อยู่นอกช่วงวันที่ของทริป
        if (outOfRangeActivities.isNotEmpty) ...[
          buildDayHeader(
            title: 'นอกช่วงวันที่ของทริป',
            subtitle: 'แตะเพื่อย้ายไปวันอื่น',
          ),
          for (ActivityData activity in outOfRangeActivities)
            buildTile(activity),
        ],
      ],
    );
  }

  Widget buildDayHeader({
    required String title,
    required String subtitle,
    VoidCallback? onAdd,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtitle,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          if (onAdd != null)
            IconButton(
              tooltip: 'เพิ่มกิจกรรมวันนี้',
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: onAdd,
            ),
        ],
      ),
    );
  }

  Widget buildTile(ActivityData activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ActivityTile(
        activity: activity,
        onToggle: (bool value) => toggleDone(activity, value),
        onEdit: () => openForm(activity: activity, day: activity.day),
        onDelete: () => deleteActivity(activity),
      ),
    );
  }
}
