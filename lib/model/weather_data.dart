import '../constant/app_format.dart';

// Model พยากรณ์อากาศ 1 วัน จาก Open-Meteo
class WeatherData {
  final DateTime date; // วันที่
  final double maxTemp; // อุณหภูมิสูงสุด (°C)
  final double minTemp; // อุณหภูมิต่ำสุด (°C)
  final int rainChance; // โอกาสฝนตกสูงสุดของวัน (%)
  final int weatherCode; // รหัสสภาพอากาศ WMO

  // Constructor
  WeatherData({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.rainChance,
    required this.weatherCode,
  });

  // Open-Meteo ตอบข้อมูลรายวันเป็น "รายการคู่ขนาน" เช่น
  // "daily": { "time": ["2026-11-15", ...], "temperature_2m_max": [7.1, ...], ... }
  // จึงแปลงทีละ index ให้เป็น List ของ WeatherData
  static List<WeatherData> listFromJson(Map<String, dynamic> json) {
    Map<String, dynamic> daily = json['daily'] ?? {};
    List<dynamic> times = daily['time'] ?? [];
    List<dynamic> maxTemps = daily['temperature_2m_max'] ?? [];
    List<dynamic> minTemps = daily['temperature_2m_min'] ?? [];
    List<dynamic> rains = daily['precipitation_probability_max'] ?? [];
    List<dynamic> codes = daily['weather_code'] ?? [];

    List<WeatherData> result = [];
    for (int i = 0; i < times.length; i++) {
      result.add(
        WeatherData(
          date: parseDateKey(times[i]),
          maxTemp: _numAt(maxTemps, i).toDouble(),
          minTemp: _numAt(minTemps, i).toDouble(),
          rainChance: _numAt(rains, i).round(),
          weatherCode: _numAt(codes, i).toInt(),
        ),
      );
    }
    return result;
  }

  // อ่านตัวเลขตำแหน่งที่ i (บางวันอาจเป็น null ให้ใช้ 0)
  static num _numAt(List<dynamic> list, int i) {
    if (i >= list.length || list[i] == null) return 0;
    return list[i] as num;
  }

  // หิมะตก (รหัส WMO 71-77 และ 85-86)
  bool get isSnow =>
      (weatherCode >= 71 && weatherCode <= 77) ||
      weatherCode == 85 ||
      weatherCode == 86;

  // ไอคอนตามรหัส WMO
  String get emoji {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 2) return '🌤️';
    if (weatherCode == 3) return '☁️';
    if (weatherCode == 45 || weatherCode == 48) return '🌫️';
    if (isSnow) return '❄️';
    if (weatherCode >= 95) return '⛈️';
    return '🌧️'; // 51-67, 80-82 = ฝนแบบต่าง ๆ
  }

  // คำอธิบายภาษาไทยตามรหัส WMO
  String get description {
    if (weatherCode == 0) return 'ท้องฟ้าแจ่มใส';
    if (weatherCode <= 2) return 'มีเมฆบางส่วน';
    if (weatherCode == 3) return 'เมฆมาก';
    if (weatherCode == 45 || weatherCode == 48) return 'มีหมอก';
    if (weatherCode >= 51 && weatherCode <= 57) return 'ฝนปรอย';
    if (weatherCode >= 61 && weatherCode <= 67) return 'ฝนตก';
    if (isSnow) return 'หิมะตก';
    if (weatherCode >= 80 && weatherCode <= 82) return 'ฝนตกเป็นช่วง ๆ';
    if (weatherCode >= 95) return 'พายุฝนฟ้าคะนอง';
    return 'ไม่ทราบสภาพอากาศ';
  }
}
