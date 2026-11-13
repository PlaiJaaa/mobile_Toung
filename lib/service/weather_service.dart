import 'dart:convert';

import '../constant/api_config.dart';
import '../constant/app_format.dart';
import '../model/destination_data.dart';
import '../model/trip_data.dart';
import '../model/weather_data.dart';
import 'api_client.dart';

// เรียกพยากรณ์อากาศรายวันจาก Open-Meteo (https://open-meteo.com) ไม่ต้องใช้ API key
class WeatherService {
  // วันสุดท้ายที่ Open-Meteo พยากรณ์ได้ (วันนี้ + 15 วัน รวมเป็น 16 วัน)
  static DateTime lastForecastDate() {
    return today().add(const Duration(days: forecastDays - 1));
  }

  // ตรวจว่าทริปนี้ดูพยากรณ์ได้หรือไม่ ถ้าไม่ได้คืนข้อความอธิบาย ถ้าได้คืน null
  static String? unavailableReason(TripData trip) {
    if (trip.isPast) {
      return 'ทริปนี้ผ่านไปแล้ว จึงไม่มีพยากรณ์อากาศ '
          '(พยากรณ์ใช้ได้กับวันนี้และวันข้างหน้าเท่านั้น)';
    }
    if (trip.startDate.isAfter(lastForecastDate())) {
      DateTime openDate = trip.startDate.subtract(
        const Duration(days: forecastDays - 1),
      );
      return 'ทริปนี้ยังอยู่ไกลเกินช่วงที่พยากรณ์ได้ '
          '(พยากรณ์ล่วงหน้าได้ประมาณ $forecastDays วัน) '
          'กลับมาดูได้ตั้งแต่วันที่ ${formatDate(openDate)}';
    }
    return null;
  }

  // ช่วงวันที่จะขอพยากรณ์ = ส่วนที่ทริปซ้อนกับช่วงที่พยากรณ์ได้
  // เช่น ทริปเริ่มเมื่อวาน ให้เริ่มที่วันนี้ / ทริปยาวเกินวันที่ 16 ให้ตัดที่วันที่ 16
  static DateTime forecastStart(TripData trip) {
    return trip.startDate.isBefore(today()) ? today() : trip.startDate;
  }

  static DateTime forecastEnd(TripData trip) {
    return trip.endDate.isAfter(lastForecastDate())
        ? lastForecastDate()
        : trip.endDate;
  }

  // GET https://api.open-meteo.com/v1/forecast?latitude=..&longitude=..&daily=..
  Future<List<WeatherData>> getForecast(
    DestinationData destination,
    TripData trip,
  ) async {
    Uri url = Uri.parse(weatherUrl).replace(
      queryParameters: {
        'latitude': destination.lat.toString(),
        'longitude': destination.lon.toString(),
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
        'timezone': 'auto', // ใช้วันตามเวลาท้องถิ่นของปลายทาง
        'start_date': toDateKey(forecastStart(trip)),
        'end_date': toDateKey(forecastEnd(trip)),
      },
    );

    try {
      var response = await client.get(url).timeout(weatherTimeout);
      if (response.statusCode == 200) {
        Map<String, dynamic> json = jsonDecode(utf8.decode(response.bodyBytes));
        return WeatherData.listFromJson(json);
      } else {
        throw ApiException(
          'โหลดพยากรณ์อากาศไม่สำเร็จ (${response.statusCode})',
        );
      }
    } catch (e) {
      throw toApiException(e, downMessage: weatherDownMessage);
    }
  }
}
