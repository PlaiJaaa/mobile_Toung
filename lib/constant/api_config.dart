import 'package:flutter/foundation.dart';

// ตั้งค่าการเชื่อมต่อ API ทั้งหมดของแอป
// ถ้าต้องเปลี่ยน port หรือเครื่อง server ให้แก้ที่ไฟล์นี้จุดเดียว

// ---------- json-server (โฟลเดอร์ server/) ----------
const int serverPort = 3001; // ใช้ 3001 จะได้ไม่ชนกับแอปอื่นที่ใช้ 3000

// เลือกที่อยู่ server ให้อัตโนมัติตามเครื่องที่รันแอป
// - Android Emulator มองเครื่องคอมพิวเตอร์ของเราเป็น 10.0.2.2
//   (localhost ใน emulator หมายถึงตัว emulator เอง จึงเรียกไม่ถึง server)
// - Chrome / Windows ใช้ localhost ได้ตามปกติ
String get baseUrl {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:$serverPort';
  }
  return 'http://localhost:$serverPort';
}

// เวลารอสูงสุดของคำขอไป json-server ถ้าเกินนี้ถือว่าเชื่อมต่อไม่สำเร็จ
const Duration requestTimeout = Duration(seconds: 10);

// ---------- Open-Meteo (พยากรณ์อากาศ ไม่ต้องใช้ API key) ----------
const String weatherUrl = 'https://api.open-meteo.com/v1/forecast';

// พยากรณ์ได้ล่วงหน้าสูงสุด 16 วัน (วันนี้ + อีก 15 วัน)
const int forecastDays = 16;

// อินเทอร์เน็ตภายนอกอาจช้ากว่า server ในเครื่อง จึงให้รอนานกว่า
const Duration weatherTimeout = Duration(seconds: 15);
