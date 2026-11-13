import 'package:flutter/material.dart';

import '../constant/color.dart';
import '../model/checklist_data.dart';
import '../model/destination_data.dart';
import '../model/packing_rule_data.dart';
import '../model/suggestion_data.dart';
import '../model/trip_data.dart';
import '../model/weather_data.dart';
import '../service/checklist_service.dart';
import '../service/packing_service.dart';
import '../service/trip_service.dart';
import '../service/weather_service.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/checklist_tile.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/section_title.dart';
import '../widgets/suggestion_card.dart';

// แท็บเช็กลิสต์: ของที่ต้องเตรียม (เพิ่มเอง / ติ๊กว่าเตรียมแล้ว / ลบ)
// และส่วน "ของแนะนำสำหรับทริปนี้" ที่กดเพิ่มลงเช็กลิสต์ได้
class ChecklistTab extends StatefulWidget {
  final TripData trip;
  final DestinationData destination;
  final ValueChanged<TripData> onTripChanged; // แจ้งหน้าแม่เมื่อทริปเปลี่ยน

  const ChecklistTab({
    super.key,
    required this.trip,
    required this.destination,
    required this.onTripChanged,
  });

  @override
  State<ChecklistTab> createState() => _ChecklistTabState();
}

class _ChecklistTabState extends State<ChecklistTab>
    with AutomaticKeepAliveClientMixin {
  final ChecklistService checklistService = ChecklistService();
  final PackingService packingService = PackingService();
  final WeatherService weatherService = WeatherService();
  final TripService tripService = TripService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _itemController = TextEditingController();

  List<ChecklistData> _items = [];
  List<PackingRuleData> _rules = [];
  List<WeatherData>? _weather; // null = ไม่มีพยากรณ์
  List<String> _dismissed = []; // ของแนะนำที่ปัดทิ้ง (จำไว้ต่อทริปใน server)
  String? _weatherNote; // เหตุผลที่ไม่มีคำแนะนำตามอากาศ
  bool _weatherFailed = false; // โหลดพยากรณ์ไม่สำเร็จ (ให้กดลองใหม่ได้)

  bool _isLoading = true;
  String? _errorMessage;
  bool _isBusy = false; // กำลังเพิ่มทั้งหมด กันกดซ้ำ

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _dismissed = List.of(widget.trip.dismissedItems);
    loadData();
  }

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  // โหลดเช็กลิสต์ + กฎของแนะนำ (จำเป็น) แล้วโหลดพยากรณ์อากาศ (ไม่บังคับ)
  Future<void> loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      List<dynamic> results = await Future.wait([
        checklistService.getChecklist(widget.trip.id),
        packingService.getRules(),
      ]);
      if (!mounted) return;
      setState(() {
        _items = results[0];
        _rules = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      return;
    }
    loadWeather();
  }

  // พยากรณ์อากาศใช้เพิ่มคำแนะนำ ถ้าโหลดไม่ได้ยังใช้คำแนะนำส่วนอื่นได้ตามปกติ
  Future<void> loadWeather() async {
    String? reason = WeatherService.unavailableReason(widget.trip);
    if (reason != null) {
      setState(() {
        _weather = null;
        _weatherNote = 'ยังไม่มีคำแนะนำตามอากาศ: $reason';
        _weatherFailed = false;
      });
      return;
    }
    setState(() {
      _weatherNote = 'กำลังโหลดพยากรณ์อากาศเพื่อแนะนำของเพิ่ม...';
      _weatherFailed = false;
    });
    try {
      List<WeatherData> weather = await weatherService.getForecast(
        widget.destination,
        widget.trip,
      );
      if (!mounted) return;
      setState(() {
        _weather = weather;
        _weatherNote = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _weather = null;
        _weatherNote = 'ยังไม่มีคำแนะนำตามอากาศ: $e';
        _weatherFailed = true;
      });
    }
  }

  // ของแนะนำที่ยังไม่อยู่ในเช็กลิสต์และยังไม่ถูกปัดทิ้ง
  List<SuggestionData> get visibleSuggestions {
    List<SuggestionData> all = PackingService.buildSuggestions(
      trip: widget.trip,
      destination: widget.destination,
      rules: _rules,
      weather: _weather,
    );
    return PackingService.hideUsed(all, _items, _dismissed);
  }

  // ---------- เช็กลิสต์ ----------

  // เพิ่มรายการที่พิมพ์เอง (POST)
  Future<void> addCustomItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    String name = _itemController.text.trim();
    bool added = await addItem(name);
    if (added) {
      _itemController.clear();
      if (!mounted) return;
      showSuccessSnackBar(context, 'เพิ่ม "$name" ลงเช็กลิสต์แล้ว');
    }
  }

  // POST /checklist แล้วเพิ่มรายการที่ได้จาก server ต่อท้ายรายการบนจอ
  Future<bool> addItem(String name) async {
    try {
      ChecklistData created = await checklistService.createItem(
        ChecklistData(
          id: '',
          tripId: widget.trip.id,
          item: name,
          isPacked: false,
        ),
      );
      if (!mounted) return false;
      setState(() {
        _items.add(created);
      });
      return true;
    } catch (e) {
      if (!mounted) return false;
      showErrorSnackBar(context, e.toString());
      return false;
    }
  }

  // ติ๊กว่าเตรียมแล้ว: เปลี่ยนบนจอทันที (มี animation) แล้ว PATCH ถ้าไม่สำเร็จเปลี่ยนกลับ
  Future<void> togglePacked(ChecklistData item, bool isPacked) async {
    setState(() {
      replaceItem(item, isPacked);
    });
    try {
      await checklistService.setPacked(item.id, isPacked);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        replaceItem(item, !isPacked);
      });
      showErrorSnackBar(context, e.toString());
    }
  }

  void replaceItem(ChecklistData item, bool isPacked) {
    int index = _items.indexWhere((c) => c.id == item.id);
    if (index < 0) return;
    _items[index] = ChecklistData(
      id: item.id,
      tripId: item.tripId,
      item: item.item,
      isPacked: isPacked,
    );
  }

  Future<void> deleteItem(ChecklistData item) async {
    bool confirmed = await showConfirmDialog(
      context,
      title: 'ลบรายการนี้?',
      message: '"${item.item}" จะถูกลบออกจากเช็กลิสต์',
    );
    if (!confirmed) return;

    try {
      await checklistService.deleteItem(item.id);
      if (!mounted) return;
      setState(() {
        _items.removeWhere((c) => c.id == item.id);
      });
      showSuccessSnackBar(context, 'ลบ "${item.item}" แล้ว');
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.toString());
    }
  }

  // ---------- ของแนะนำ ----------

  Future<void> addSuggestion(SuggestionData suggestion) async {
    bool added = await addItem(suggestion.item);
    if (added && mounted) {
      showSuccessSnackBar(context, 'เพิ่ม "${suggestion.item}" ลงเช็กลิสต์แล้ว');
    }
  }

  // เพิ่มของแนะนำทั้งหมดที่เห็นอยู่ (POST ทีละรายการ)
  Future<void> addAllSuggestions() async {
    List<SuggestionData> suggestions = visibleSuggestions;
    setState(() {
      _isBusy = true;
    });
    int count = 0;
    for (SuggestionData suggestion in suggestions) {
      bool added = await addItem(suggestion.item);
      if (!added) break; // ถ้าล้ม (เช่น server ปิด) หยุดเลย ไม่ต้องลองต่อ
      count++;
    }
    if (!mounted) return;
    setState(() {
      _isBusy = false;
    });
    if (count > 0) {
      showSuccessSnackBar(context, 'เพิ่ม $count รายการลงเช็กลิสต์แล้ว');
    }
  }

  // ปัดทิ้ง: PATCH /trips/{id} บันทึกรายการที่ไม่ต้องการ (จำไว้ต่อทริป)
  Future<void> dismissSuggestion(SuggestionData suggestion) async {
    List<String> newList = [..._dismissed, suggestion.item];
    bool saved = await saveDismissed(newList);
    if (!saved || !mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ซ่อน "${suggestion.item}" แล้ว'),
        action: SnackBarAction(
          label: 'เลิกทำ',
          textColor: Colors.white,
          onPressed: () {
            saveDismissed(
              _dismissed.where((item) => item != suggestion.item).toList(),
            );
          },
        ),
      ),
    );
  }

  // คืนรายการที่ปัดทิ้งทั้งหมดกลับมา
  Future<void> restoreDismissed() async {
    bool saved = await saveDismissed([]);
    if (saved && mounted) {
      showSuccessSnackBar(context, 'แสดงของแนะนำที่ซ่อนไว้แล้ว');
    }
  }

  Future<bool> saveDismissed(List<String> items) async {
    if (!mounted) return false;
    List<String> oldList = _dismissed;
    setState(() {
      _dismissed = items; // เปลี่ยนบนจอทันที
    });
    try {
      TripData updated = await tripService.saveDismissedItems(
        widget.trip.id,
        items,
      );
      widget.onTripChanged(updated);
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        _dismissed = oldList;
      });
      showErrorSnackBar(context, e.toString());
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(onRefresh: loadData, child: buildBody());
  }

  Widget buildBody() {
    if (_isLoading) {
      return const LoadingView();
    }
    if (_errorMessage != null) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          ErrorView(message: _errorMessage!, onRetry: loadData),
        ],
      );
    }

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    int packedCount = _items.where((ChecklistData c) => c.isPacked).length;
    double progress = _items.isEmpty ? 0 : packedCount / _items.length;
    List<SuggestionData> suggestions = visibleSuggestions;
    int essentialCount = suggestions.where((s) => s.essential).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // ---------- ความคืบหน้า ----------
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.luggage_rounded, color: primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'เตรียมแล้ว $packedCount จาก ${_items.length} อย่าง',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: successColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // TweenAnimationBuilder: แถบค่อย ๆ ยืดไปที่ค่าใหม่เมื่อติ๊ก
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 400),
                  builder: (BuildContext context, double value, Widget? child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 10,
                        color: successColor,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ---------- ช่องเพิ่มรายการเอง ----------
        Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _itemController,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => addCustomItem(),
                  decoration: const InputDecoration(
                    hintText: 'เพิ่มของที่ต้องเตรียม เช่น ที่ชาร์จมือถือ',
                    prefixIcon: Icon(Icons.add_task_rounded),
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณาพิมพ์ชื่อของ';
                    }
                    bool exists = _items.any(
                      (c) => PackingService.sameItem(c.item, value),
                    );
                    if (exists) {
                      return 'มีรายการนี้ในเช็กลิสต์แล้ว';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: addCustomItem,
                  child: const Text('เพิ่ม'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ---------- รายการในเช็กลิสต์ ----------
        if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'ยังไม่มีของในเช็กลิสต์ เพิ่มเอง หรือกดเพิ่มจากของแนะนำด้านล่าง',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        for (ChecklistData item in _items)
          ChecklistTile(
            item: item,
            onToggle: (bool value) => togglePacked(item, value),
            onDelete: () => deleteItem(item),
          ),
        const SizedBox(height: 20),

        // ---------- ของแนะนำสำหรับทริปนี้ ----------
        SectionTitle(
          title: 'ของแนะนำสำหรับทริปนี้ (${suggestions.length})',
          actionText: suggestions.isEmpty || _isBusy ? null : 'เพิ่มทั้งหมด',
          onAction: addAllSuggestions,
        ),
        Text(
          essentialCount > 0
              ? 'มีของจำเป็นที่ยังไม่ได้ใส่เช็กลิสต์ $essentialCount อย่าง · ปัดซ้าย/ขวาเพื่อซ่อน'
              : 'รวมจากประเภทสถานที่ ประเทศ สภาพอากาศ และจำนวนวัน · ปัดซ้าย/ขวาเพื่อซ่อน',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        if (_weatherNote != null) buildWeatherNote(),
        if (_isBusy) const LinearProgressIndicator(),
        if (suggestions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '🎉 ของแนะนำอยู่ในเช็กลิสต์ครบแล้ว',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        for (SuggestionData suggestion in suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            // Dismissible: ปัดการ์ดออกด้านข้างเพื่อซ่อนรายการ
            child: Dismissible(
              key: ValueKey('suggest-${suggestion.item}'),
              onDismissed: (_) => dismissSuggestion(suggestion),
              background: buildSwipeBackground(Alignment.centerLeft),
              secondaryBackground: buildSwipeBackground(Alignment.centerRight),
              child: SuggestionCard(
                suggestion: suggestion,
                onAdd: () => addSuggestion(suggestion),
                onDismiss: () => dismissSuggestion(suggestion),
              ),
            ),
          ),
        if (_dismissed.isNotEmpty)
          Center(
            child: TextButton.icon(
              onPressed: restoreDismissed,
              icon: const Icon(Icons.visibility_outlined),
              label: Text('แสดงรายการที่ซ่อนไว้ (${_dismissed.length})'),
            ),
          ),
      ],
    );
  }

  // กล่องบอกว่าทำไมยังไม่มีคำแนะนำตามอากาศ (ถ้าโหลดไม่สำเร็จมีปุ่มลองใหม่)
  Widget buildWeatherNote() {
    Color color = _weatherFailed ? dangerColor : infoColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _weatherFailed ? Icons.cloud_off_rounded : Icons.info_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _weatherNote!,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
          if (_weatherFailed)
            TextButton(onPressed: loadWeather, child: const Text('ลองใหม่')),
        ],
      ),
    );
  }

  Widget buildSwipeBackground(Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text('ซ่อน'),
    );
  }
}
