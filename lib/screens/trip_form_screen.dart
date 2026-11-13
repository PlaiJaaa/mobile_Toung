import 'package:flutter/material.dart';

import '../constant/app_constant.dart';
import '../constant/app_format.dart';
import '../constant/color.dart';
import '../model/destination_data.dart';
import '../model/trip_data.dart';
import '../service/destination_service.dart';
import '../service/trip_service.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/destination_option.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/primary_button.dart';

// ฟอร์มสร้างและแก้ไขทริป (บทที่ 4)
// ชื่อทริป (TextFormField), ปลายทาง (เลือกจากรายการ destinations),
// ช่วงวันที่ (showDateRangePicker), งบประมาณ, สกุลเงิน (Dropdown), สไตล์การเที่ยว (Radio)
class TripFormScreen extends StatefulWidget {
  final TripData? trip; // null = สร้างทริปใหม่, มีค่า = แก้ไขทริปนี้
  final String defaultCurrency; // สกุลเงินเริ่มต้นของทริปใหม่

  const TripFormScreen({super.key, this.trip, required this.defaultCurrency});

  @override
  State<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends State<TripFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TripService tripService = TripService();
  final DestinationService destinationService = DestinationService();

  List<DestinationData> _destinations = [];
  String? _destinationId; // ปลายทางที่เลือก
  DateTimeRange? _dateRange; // วันไป - วันกลับ
  String? _currency;
  String? _style = travelStyles.first;

  bool _isLoading = true; // กำลังโหลดรายการปลายทาง
  String? _errorMessage;
  bool _isSaving = false;

  // ความกว้างของตัวเลือกปลายทาง 1 ใบ (การ์ด 140 + ระยะห่าง 10)
  static const double optionWidth = 150;
  ScrollController? _destinationScroll; // เลื่อนไปที่ปลายทางที่เลือกไว้ตอนแก้ไข

  bool get isEdit => widget.trip != null;

  @override
  void initState() {
    super.initState();
    // ถ้าเป็นการแก้ไข ใส่ค่าเดิมของทริปลงในฟอร์ม
    TripData? trip = widget.trip;
    if (trip != null) {
      _nameController.text = trip.name;
      _budgetController.text = plainNumber(trip.budget);
      _destinationId = trip.destinationId;
      _dateRange = DateTimeRange(start: trip.startDate, end: trip.endDate);
      _currency = trip.currency;
      if (travelStyles.contains(trip.style)) _style = trip.style;
    } else {
      _currency = widget.defaultCurrency;
    }
    loadDestinations();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    _destinationScroll?.dispose();
    super.dispose();
  }

  // GET /destinations สำหรับให้เลือกปลายทาง
  Future<void> loadDestinations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      List<DestinationData> list = await destinationService.getDestinations();
      if (!mounted) return;
      // ตอนแก้ไข ให้รายการปลายทางเลื่อนไปที่ใบที่เลือกไว้ จะได้เห็นทันที
      int index = list.indexWhere((d) => d.id == _destinationId);
      _destinationScroll?.dispose();
      _destinationScroll = ScrollController(
        initialScrollOffset: index > 0 ? index * optionWidth : 0,
      );
      setState(() {
        _destinations = list;
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

  // เปิดปฏิทินเลือกช่วงวันที่ (เลือกวันไปแล้วเลือกวันกลับ)
  Future<void> pickDateRange(FormFieldState<DateTimeRange> field) async {
    DateTime start = _dateRange?.start ?? today().add(const Duration(days: 7));
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today().year - 2),
      lastDate: DateTime(today().year + 3, 12, 31),
      initialDateRange:
          _dateRange ??
          DateTimeRange(start: start, end: start.add(const Duration(days: 2))),
      helpText: 'เลือกวันไปและวันกลับ',
      saveText: 'ตกลง',
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      field.didChange(picked); // แจ้ง FormField ให้ตรวจ validator ใหม่
    }
  }

  Future<void> saveTrip() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      TripData saved;
      if (isEdit) {
        // แก้ไข: PATCH เฉพาะช่องในฟอร์ม (ไม่แตะรายการที่ปัดทิ้งของทริป)
        saved = await tripService.updateTrip(widget.trip!.id, {
          'name': _nameController.text.trim(),
          'destinationId': int.tryParse(_destinationId!) ?? _destinationId,
          'startDate': toDateKey(_dateRange!.start),
          'endDate': toDateKey(_dateRange!.end),
          'budget': double.parse(_budgetController.text.trim()),
          'currency': _currency,
          'style': _style,
        });
      } else {
        // สร้างใหม่: สร้าง Object จากค่าในฟอร์ม (id เว้นว่าง json-server จะสร้างให้)
        TripData trip = TripData(
          id: '',
          name: _nameController.text.trim(),
          destinationId: _destinationId!,
          startDate: _dateRange!.start,
          endDate: _dateRange!.end,
          budget: double.parse(_budgetController.text.trim()),
          currency: _currency!,
          style: _style!,
        );
        saved = await tripService.createTrip(trip);
      }
      if (!mounted) return;
      showSuccessSnackBar(
        context,
        isEdit ? 'บันทึกการแก้ไขทริปเรียบร้อย' : 'สร้างทริป "${saved.name}" เรียบร้อย',
      );
      // กลับไปหน้าก่อน พร้อมส่งทริปที่บันทึกแล้วกลับไป
      Navigator.pop(context, saved);
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
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'แก้ไขทริป' : 'สร้างทริปใหม่')),
      body: buildBody(),
    );
  }

  Widget buildBody() {
    if (_isLoading) {
      return const LoadingView();
    }
    if (_errorMessage != null) {
      return ErrorView(message: _errorMessage!, onRetry: loadDestinations);
    }

    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // ---------- ชื่อทริป ----------
          TextFormField(
            controller: _nameController,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: 'ชื่อทริป',
              hintText: 'เช่น เที่ยวญี่ปุ่นหน้าหนาว',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'กรุณากรอกชื่อทริป';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // ---------- ปลายทาง: FormField ที่มี validator ของตัวเอง ----------
          FormField<String>(
            initialValue: _destinationId,
            validator: (String? value) {
              if (value == null) {
                return 'กรุณาเลือกปลายทาง';
              }
              return null;
            },
            builder: (FormFieldState<String> field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ปลายทาง',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      controller: _destinationScroll,
                      scrollDirection: Axis.horizontal,
                      itemCount: _destinations.length,
                      itemBuilder: (BuildContext context, int index) {
                        DestinationData destination = _destinations[index];
                        return DestinationOption(
                          destination: destination,
                          isSelected: destination.id == _destinationId,
                          onTap: () {
                            setState(() {
                              _destinationId = destination.id;
                            });
                            field.didChange(destination.id);
                          },
                        );
                      },
                    ),
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 12),
                      child: Text(
                        field.errorText!,
                        style: TextStyle(color: colorScheme.error, fontSize: 12),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // ---------- ช่วงวันที่ ----------
          FormField<DateTimeRange>(
            initialValue: _dateRange,
            validator: (DateTimeRange? value) {
              if (value == null) {
                return 'กรุณาเลือกวันไปและวันกลับ';
              }
              if (value.end.isBefore(value.start)) {
                return 'วันกลับต้องไม่ก่อนวันไป';
              }
              return null;
            },
            builder: (FormFieldState<DateTimeRange> field) {
              DateTimeRange? range = field.value;
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => pickDateRange(field),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'ช่วงวันที่เดินทาง',
                    prefixIcon: const Icon(Icons.date_range_rounded),
                    errorText: field.errorText,
                  ),
                  child: Text(
                    range == null
                        ? 'แตะเพื่อเลือกวันไป - วันกลับ'
                        : '${formatDateRange(range.start, range.end)} '
                              '(${range.duration.inDays + 1} วัน)',
                    style: TextStyle(
                      color: range == null ? colorScheme.onSurfaceVariant : null,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // ---------- งบประมาณ + สกุลเงิน ----------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _budgetController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'งบประมาณ',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกงบประมาณ';
                    }
                    double? budget = double.tryParse(value.trim());
                    if (budget == null) {
                      return 'กรอกเป็นตัวเลขเท่านั้น';
                    }
                    if (budget <= 0) {
                      return 'งบต้องมากกว่า 0';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _currency,
                  decoration: const InputDecoration(labelText: 'สกุลเงิน'),
                  items: currencySymbols.keys
                      .map(
                        (String code) => DropdownMenuItem(
                          value: code,
                          child: Text(code),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _currency = value;
                    });
                  },
                  validator: (String? value) {
                    if (value == null) {
                      return 'เลือกสกุลเงิน';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ---------- สไตล์การเที่ยว (Radio) ----------
          const Text(
            'สไตล์การเที่ยว',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: travelStyles.map((String item) {
                return RadioListTile<String>(
                  value: item,
                  groupValue: _style,
                  title: Text(item),
                  secondary: Icon(travelStyleIcons[item], color: primaryColor),
                  onChanged: (String? value) {
                    setState(() {
                      _style = value;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: isEdit ? 'บันทึกการแก้ไข' : 'สร้างทริป',
            icon: Icons.check_rounded,
            isLoading: _isSaving,
            onPressed: saveTrip,
          ),
        ],
      ),
    );
  }
}
