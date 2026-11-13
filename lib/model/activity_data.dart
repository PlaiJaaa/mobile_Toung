// Model กิจกรรมในแผนรายวัน (GET /activities?tripId=...)
class ActivityData {
  final String id; // id ที่ json-server สร้างให้
  final String tripId; // ทริปที่กิจกรรมนี้อยู่
  final int day; // วันที่เท่าไรของทริป (เริ่มที่ 1)
  final String time; // เวลา เช่น 09:30
  final String title; // ชื่อกิจกรรม
  final String place; // สถานที่
  final String category; // กิน / เที่ยว / เดินทาง / ที่พัก
  final String note; // โน้ตเพิ่มเติม
  final bool isDone; // ทำแล้วหรือยัง

  // Constructor
  ActivityData({
    required this.id,
    required this.tripId,
    required this.day,
    required this.time,
    required this.title,
    required this.place,
    required this.category,
    required this.note,
    required this.isDone,
  });

  // แปลง JSON เป็น Object
  ActivityData.fromJson(Map<String, dynamic> json)
    : id = json['id'].toString(),
      tripId = (json['tripId'] ?? '').toString(),
      day = (json['day'] as num? ?? 1).toInt(),
      time = json['time'] ?? '',
      title = json['title'] ?? '',
      place = json['place'] ?? '',
      category = json['category'] ?? 'เที่ยว',
      note = json['note'] ?? '',
      isDone = json['isDone'] ?? false;

  // แปลง Object เป็น JSON Map สำหรับส่งไปกับ POST / PUT
  // tripId ส่งเป็นตัวเลข ให้ตรงกับ id ของ trips
  Map<String, dynamic> toJson() {
    return {
      'tripId': int.tryParse(tripId) ?? tripId,
      'day': day,
      'time': time,
      'title': title,
      'place': place,
      'category': category,
      'note': note,
      'isDone': isDone,
    };
  }
}
