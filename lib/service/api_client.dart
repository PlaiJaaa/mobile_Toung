import 'package:http/http.dart' as http;

// ตัวเรียก http ที่ทุก service ใช้ร่วมกัน
// ประกาศเป็นตัวแปรที่แก้ค่าได้ เพื่อให้ตอนรัน flutter test เปลี่ยนเป็น MockClient ได้
http.Client client = http.Client();

// หมายเหตุ: service ทุกตัวอ่านผลด้วย utf8.decode(response.bodyBytes) แทน response.body
// เพราะถ้า server ไม่ได้ระบุ charset มาใน header ตัว http จะถอดข้อความเป็น latin1
// แล้วภาษาไทยจะกลายเป็นตัวอ่านไม่ออก

// header ของคำขอที่ส่ง JSON ไปด้วย (POST / PUT / PATCH)
const Map<String, String> jsonHeaders = {'Content-Type': 'application/json'};

// ข้อความเมื่อเชื่อมต่อ json-server ไม่ได้
const String serverDownMessage =
    'เชื่อมต่อ server ไม่ได้ กรุณาเปิด server ก่อน (ดับเบิลคลิก start_server.bat)';

// ข้อความเมื่อเรียก Open-Meteo ไม่ได้ (อินเทอร์เน็ตมีปัญหา)
const String weatherDownMessage =
    'โหลดพยากรณ์อากาศไม่สำเร็จ ตรวจการเชื่อมต่ออินเทอร์เน็ตแล้วลองใหม่';

// Exception ที่มีข้อความภาษาไทยไว้แสดงให้ผู้ใช้เห็น
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

// แปลง error ทุกแบบให้เป็น ApiException
// - เป็น ApiException อยู่แล้ว (เช่น statusCode ไม่ถูกต้อง) ใช้ข้อความเดิม
// - อย่างอื่น (เน็ตหลุด, server ไม่ได้เปิด, รอนานเกิน) ใช้ข้อความ downMessage
ApiException toApiException(
  Object error, {
  String downMessage = serverDownMessage,
}) {
  if (error is ApiException) {
    return error;
  }
  return ApiException(downMessage);
}
