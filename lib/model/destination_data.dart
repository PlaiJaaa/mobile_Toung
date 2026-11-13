import '../constant/app_constant.dart';

// Model ปลายทาง (GET /destinations) ใช้เลือกในฟอร์มทริป และใช้ lat/lon เรียกพยากรณ์อากาศ
class DestinationData {
  final String id; // id ที่ json-server สร้างให้
  final String name; // ชื่อปลายทาง เช่น เกียวโต
  final String country; // ประเทศ เช่น ญี่ปุ่น (ใช้จับคู่กับ packingRules)
  final String type; // beach / mountain / city / temple
  final String image; // ที่อยู่รูป (ไฟล์ใน assets หรือ URL)
  final double lat; // ละติจูด
  final double lon; // ลองจิจูด

  // Constructor
  DestinationData({
    required this.id,
    required this.name,
    required this.country,
    required this.type,
    required this.image,
    required this.lat,
    required this.lon,
  });

  // แปลง JSON เป็น Object
  // ตัวเลขใช้ num แล้วค่อยแปลง เพราะ JSON อาจส่งมาเป็น int หรือ double
  DestinationData.fromJson(Map<String, dynamic> json)
    : id = json['id'].toString(),
      name = json['name'] ?? '',
      country = json['country'] ?? '',
      type = json['type'] ?? 'city',
      image = json['image'] ?? '',
      lat = (json['lat'] as num? ?? 0).toDouble(),
      lon = (json['lon'] as num? ?? 0).toDouble();

  // แปลง Object เป็น JSON Map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'country': country,
      'type': type,
      'image': image,
      'lat': lat,
      'lon': lon,
    };
  }

  // ชื่อประเภทภาษาไทย เช่น beach -> ทะเล
  String get typeName => destinationTypeNames[type] ?? type;

  // เช่น เกียวโต, ญี่ปุ่น
  String get fullName => '$name, $country';
}
