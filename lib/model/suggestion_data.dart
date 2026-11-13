// ของแนะนำ 1 รายการที่แสดงในส่วน "ของแนะนำสำหรับทริปนี้"
// ไม่ได้เก็บใน server แต่คำนวณในแอปจาก packingRules + พยากรณ์อากาศ + จำนวนวัน
class SuggestionData {
  final String item; // ชื่อของ (ใช้เป็นชื่อรายการตอนเพิ่มลงเช็กลิสต์)
  final String reason; // เหตุผล เช่น "เพราะพยากรณ์ว่าฝนตกวันที่ 3"
  final String emoji; // ไอคอนหน้ารายการ
  final bool essential; // ของจำเป็น
  final String source; // มาจากไหน: สถานที่ / ประเทศ / อากาศ / จำนวนวัน / ทุกทริป

  // Constructor
  SuggestionData({
    required this.item,
    required this.reason,
    required this.emoji,
    required this.essential,
    required this.source,
  });
}
