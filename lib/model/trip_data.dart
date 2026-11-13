import '../constant/app_format.dart';

// Model ทริป (GET /trips)
class TripData {
  final String id; // id ที่ json-server สร้างให้
  final String name; // ชื่อทริป
  final String destinationId; // id ของปลายทางใน /destinations
  final DateTime startDate; // วันไป
  final DateTime endDate; // วันกลับ
  final double budget; // งบประมาณ
  final String currency; // สกุลเงิน เช่น THB
  final String style; // สไตล์การเที่ยว
  final List<String> dismissedItems; // ของแนะนำที่ผู้ใช้ปัดทิ้งในทริปนี้

  // Constructor
  TripData({
    required this.id,
    required this.name,
    required this.destinationId,
    required this.startDate,
    required this.endDate,
    required this.budget,
    required this.currency,
    required this.style,
    this.dismissedItems = const [],
  });

  // แปลง JSON เป็น Object
  // วันที่เก็บเป็นข้อความ เช่น "2026-11-15" แล้วแปลงด้วย parseDateKey
  TripData.fromJson(Map<String, dynamic> json)
    : id = json['id'].toString(),
      name = json['name'] ?? '',
      destinationId = (json['destinationId'] ?? '').toString(),
      startDate = parseDateKey(json['startDate']),
      endDate = parseDateKey(json['endDate']),
      budget = (json['budget'] as num? ?? 0).toDouble(),
      currency = json['currency'] ?? 'THB',
      style = json['style'] ?? '',
      dismissedItems = (json['dismissedItems'] as List? ?? [])
          .map((item) => item.toString())
          .toList();

  // แปลง Object เป็น JSON Map สำหรับส่งไปกับ POST
  // ไม่ใส่ id เพราะ json-server จะสร้าง id ให้เอง
  // destinationId ส่งเป็นตัวเลข ให้ตรงกับ id ของ destinations
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'destinationId': int.tryParse(destinationId) ?? destinationId,
      'startDate': toDateKey(startDate),
      'endDate': toDateKey(endDate),
      'budget': budget,
      'currency': currency,
      'style': style,
      'dismissedItems': dismissedItems,
    };
  }

  // จำนวนวันของทริป (นับวันไปและวันกลับด้วย) เช่น 15-19 พ.ย. = 5 วัน
  int get dayCount => endDate.difference(startDate).inDays + 1;

  // วันที่ของวันที่ n ในทริป (n เริ่มที่ 1)
  DateTime dateOfDay(int day) => startDate.add(Duration(days: day - 1));

  // อีกกี่วันจะถึงวันไป (0 = วันนี้, ติดลบ = ออกเดินทางแล้ว)
  int get daysUntilStart => startDate.difference(today()).inDays;

  // ทริปจบไปแล้ว (วันกลับอยู่ก่อนวันนี้)
  bool get isPast => endDate.isBefore(today());

  // กำลังเที่ยวอยู่ (วันนี้อยู่ระหว่างวันไปถึงวันกลับ)
  bool get isOngoing => !isPast && daysUntilStart <= 0;
}
