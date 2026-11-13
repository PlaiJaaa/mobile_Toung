// Model รายการในเช็กลิสต์ของที่ต้องเตรียม (GET /checklist?tripId=...)
class ChecklistData {
  final String id; // id ที่ json-server สร้างให้
  final String tripId; // ทริปที่รายการนี้อยู่
  final String item; // ชื่อของ เช่น ครีมกันแดด
  final bool isPacked; // เตรียมแล้วหรือยัง

  // Constructor
  ChecklistData({
    required this.id,
    required this.tripId,
    required this.item,
    required this.isPacked,
  });

  // แปลง JSON เป็น Object
  ChecklistData.fromJson(Map<String, dynamic> json)
    : id = json['id'].toString(),
      tripId = (json['tripId'] ?? '').toString(),
      item = json['item'] ?? '',
      isPacked = json['isPacked'] ?? false;

  // แปลง Object เป็น JSON Map สำหรับส่งไปกับ POST
  Map<String, dynamic> toJson() {
    return {
      'tripId': int.tryParse(tripId) ?? tripId,
      'item': item,
      'isPacked': isPacked,
    };
  }

  // จำนวนรายการที่ยังไม่ได้เตรียมของทริปที่ระบุ (ใช้ where ตามบทที่ 1)
  static int countUnpacked(List<ChecklistData> items, String tripId) {
    return items
        .where((ChecklistData c) => c.tripId == tripId && !c.isPacked)
        .length;
  }
}
