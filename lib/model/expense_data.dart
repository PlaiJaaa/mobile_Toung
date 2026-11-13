import '../constant/app_format.dart';

// Model รายจ่าย (GET /expenses?tripId=...)
class ExpenseData {
  final String id; // id ที่ json-server สร้างให้
  final String tripId; // ทริปที่รายจ่ายนี้อยู่
  final String title; // รายการ เช่น ราเมน
  final String category; // หมวด เช่น อาหาร
  final double amount; // จำนวนเงิน (สกุลเงินเดียวกับทริป)
  final DateTime date; // วันที่จ่าย

  // Constructor
  ExpenseData({
    required this.id,
    required this.tripId,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
  });

  // แปลง JSON เป็น Object
  ExpenseData.fromJson(Map<String, dynamic> json)
    : id = json['id'].toString(),
      tripId = (json['tripId'] ?? '').toString(),
      title = json['title'] ?? '',
      category = json['category'] ?? 'อื่น ๆ',
      amount = (json['amount'] as num? ?? 0).toDouble(),
      date = parseDateKey(json['date']);

  // แปลง Object เป็น JSON Map สำหรับส่งไปกับ POST
  Map<String, dynamic> toJson() {
    return {
      'tripId': int.tryParse(tripId) ?? tripId,
      'title': title,
      'category': category,
      'amount': amount,
      'date': toDateKey(date),
    };
  }

  // ---------- คำนวณยอดรวม (ใช้ where + map ตามบทที่ 1) ----------

  // ยอดรวมของรายจ่ายทั้งหมดในรายการ
  static double sumOf(List<ExpenseData> expenses) {
    return expenses
        .map((ExpenseData e) => e.amount)
        .fold(0.0, (double sum, double amount) => sum + amount);
  }

  // ยอดรวมของทริปที่ระบุ (ใช้ในหน้ารายการทริป ที่โหลดรายจ่ายทุกทริปมาพร้อมกัน)
  static double totalOfTrip(List<ExpenseData> expenses, String tripId) {
    return sumOf(expenses.where((ExpenseData e) => e.tripId == tripId).toList());
  }

  // ยอดรวมแยกตามหมวด เช่น {อาหาร: 1200, ที่พัก: 3000} เฉพาะหมวดที่มีรายจ่าย
  static Map<String, double> totalByCategory(
    List<ExpenseData> expenses,
    List<String> categories,
  ) {
    Map<String, double> result = {};
    for (String category in categories) {
      double total = sumOf(
        expenses.where((ExpenseData e) => e.category == category).toList(),
      );
      if (total > 0) {
        result[category] = total;
      }
    }
    return result;
  }
}
