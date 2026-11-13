import 'package:flutter/material.dart';

import '../constant/app_constant.dart';
import '../constant/app_format.dart';
import '../model/activity_data.dart';
import '../model/trip_data.dart';
import '../service/activity_service.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/primary_button.dart';

// ฟอร์มเพิ่ม / แก้ไขกิจกรรมในแผนรายวัน
// ชื่อกิจกรรม, วันที่ (Dropdown), เวลา (showTimePicker), สถานที่, หมวด, โน้ต, ทำแล้ว (Checkbox)
class ActivityFormScreen extends StatefulWidget {
  final TripData trip;
  final ActivityData? activity; // null = เพิ่มใหม่
  final int initialDay; // วันที่เลือกไว้ตอนเปิดฟอร์ม

  const ActivityFormScreen({
    super.key,
    required this.trip,
    this.activity,
    this.initialDay = 1,
  });

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final ActivityService activityService = ActivityService();

  int? _day;
  TimeOfDay? _time;
  String _category = activityCategories[1]; // ค่าเริ่มต้น = เที่ยว
  bool _isDone = false;
  bool _isSaving = false;

  bool get isEdit => widget.activity != null;

  @override
  void initState() {
    super.initState();
    ActivityData? activity = widget.activity;
    if (activity != null) {
      _titleController.text = activity.title;
      _placeController.text = activity.place;
      _noteController.text = activity.note;
      _category = activity.category;
      _isDone = activity.isDone;
      _time = parseTime(activity.time);
    }
    // วันต้องอยู่ในช่วงของทริป ถ้าไม่อยู่ให้ผู้ใช้เลือกใหม่
    int day = activity?.day ?? widget.initialDay;
    _day = (day >= 1 && day <= widget.trip.dayCount) ? day : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // "09:30" -> TimeOfDay(9, 30)
  TimeOfDay? parseTime(String text) {
    List<String> parts = text.split(':');
    if (parts.length != 2) return null;
    int? hour = int.tryParse(parts[0]);
    int? minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  // TimeOfDay(9, 5) -> "09:05" (เก็บแบบนี้เพื่อให้เรียงตามเวลาได้)
  String timeText(TimeOfDay time) {
    String hour = time.hour.toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> pickTime(FormFieldState<TimeOfDay> field) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
      helpText: 'เลือกเวลา',
      // แสดงนาฬิกาแบบ 24 ชั่วโมง (เช่น 21:00) ตามที่คนไทยคุ้นเคย
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _time = picked;
      });
      field.didChange(picked);
    }
  }

  Future<void> saveActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    ActivityData activity = ActivityData(
      id: widget.activity?.id ?? '',
      tripId: widget.trip.id,
      day: _day!,
      time: timeText(_time!),
      title: _titleController.text.trim(),
      place: _placeController.text.trim(),
      category: _category,
      note: _noteController.text.trim(),
      isDone: _isDone,
    );

    try {
      if (isEdit) {
        await activityService.updateActivity(activity); // PUT
      } else {
        await activityService.createActivity(activity); // POST
      }
      if (!mounted) return;
      showSuccessSnackBar(
        context,
        isEdit ? 'แก้ไขกิจกรรมเรียบร้อย' : 'เพิ่มกิจกรรมเรียบร้อย',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.toString());
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'แก้ไขกิจกรรม' : 'เพิ่มกิจกรรม')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ชื่อกิจกรรม',
                hintText: 'เช่น ไหว้พระวัดคิโยมิสึ',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกชื่อกิจกรรม';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ---------- วัน + เวลา ----------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: _day,
                    decoration: const InputDecoration(labelText: 'วันที่'),
                    items: [
                      for (int day = 1; day <= widget.trip.dayCount; day++)
                        DropdownMenuItem(
                          value: day,
                          child: Text(
                            'วันที่ $day · ${formatShortDate(widget.trip.dateOfDay(day))}',
                          ),
                        ),
                    ],
                    onChanged: (int? value) {
                      setState(() {
                        _day = value;
                      });
                    },
                    validator: (int? value) {
                      if (value == null) return 'กรุณาเลือกวัน';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FormField<TimeOfDay>(
                    initialValue: _time,
                    validator: (TimeOfDay? value) {
                      if (value == null) return 'เลือกเวลา';
                      return null;
                    },
                    builder: (FormFieldState<TimeOfDay> field) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => pickTime(field),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'เวลา',
                            errorText: field.errorText,
                            suffixIcon: const Icon(Icons.schedule_rounded),
                          ),
                          child: Text(
                            field.value == null ? '--:--' : timeText(field.value!),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _placeController,
              decoration: const InputDecoration(
                labelText: 'สถานที่ (ไม่บังคับ)',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // ---------- หมวด (ChoiceChip เลือกได้ 1 หมวด) ----------
            const Text(
              'หมวด',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: activityCategories.map((String item) {
                Color color = activityColors[item] ?? colorScheme.primary;
                return ChoiceChip(
                  avatar: Icon(
                    activityIcons[item],
                    size: 18,
                    color: _category == item ? Colors.white : color,
                  ),
                  label: Text(item),
                  selected: _category == item,
                  selectedColor: color,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: _category == item
                        ? Colors.white
                        : colorScheme.onSurface,
                    fontFamily: 'Prompt',
                  ),
                  onSelected: (bool selected) {
                    setState(() {
                      _category = item;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'โน้ต (ไม่บังคับ)',
                hintText: 'เช่น จองตั๋วล่วงหน้า / ปิดวันพุธ',
                alignLabelWithHint: true,
              ),
            ),

            // ---------- ทำแล้ว (Checkbox) ----------
            Card(
              clipBehavior: Clip.antiAlias,
              child: CheckboxListTile(
                value: _isDone,
                title: const Text('ทำกิจกรรมนี้แล้ว'),
                secondary: const Icon(Icons.task_alt_rounded),
                onChanged: (bool? value) {
                  setState(() {
                    _isDone = value ?? false;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: isEdit ? 'บันทึกการแก้ไข' : 'เพิ่มกิจกรรม',
              icon: Icons.check_rounded,
              isLoading: _isSaving,
              onPressed: saveActivity,
            ),
          ],
        ),
      ),
    );
  }
}
