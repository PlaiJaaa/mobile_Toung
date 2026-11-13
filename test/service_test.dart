import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:travel_planner/constant/api_config.dart';
import 'package:travel_planner/constant/app_format.dart';
import 'package:travel_planner/model/activity_data.dart';
import 'package:travel_planner/model/destination_data.dart';
import 'package:travel_planner/model/trip_data.dart';
import 'package:travel_planner/service/activity_service.dart';
import 'package:travel_planner/service/api_client.dart' as api;
import 'package:travel_planner/service/checklist_service.dart';
import 'package:travel_planner/service/trip_service.dart';
import 'package:travel_planner/service/weather_service.dart';

import 'test_helper.dart';

TripData tripFrom(int startOffset, int endOffset) => TripData(
  id: '9',
  name: 'ทดสอบ',
  destinationId: '8',
  startDate: today().add(Duration(days: startOffset)),
  endDate: today().add(Duration(days: endOffset)),
  budget: 1000,
  currency: 'THB',
  style: 'สบาย ๆ',
);

final DestinationData niseko = DestinationData(
  id: '8',
  name: 'ฮอกไกโด (นิเซโกะ)',
  country: 'ญี่ปุ่น',
  type: 'mountain',
  image: '',
  lat: 42.8048,
  lon: 140.6874,
);

// ทดสอบว่า service เรียก URL / method / body ถูกต้อง และจัดการ statusCode กับ error
void main() {
  test('createTrip ส่ง POST พร้อม JSON ไม่มี id และต้องได้ 201', () async {
    late http.Request sent;
    api.client = MockClient((request) async {
      sent = request;
      return http.Response.bytes(
        utf8.encode(jsonEncode({...jsonDecode(request.body), 'id': 4})),
        201,
      );
    });

    final created = await TripService().createTrip(tripFrom(10, 12));
    expect(sent.method, 'POST');
    expect(sent.url.toString(), '$baseUrl/trips');
    expect(sent.headers['Content-Type'], startsWith('application/json'));
    expect(jsonDecode(sent.body).containsKey('id'), false);
    expect(created.id, '4');
    expect(created.name, 'ทดสอบ');
  });

  test('setDone ส่ง PATCH เฉพาะช่อง isDone / updateActivity ใช้ PUT', () async {
    final List<http.Request> sent = [];
    api.client = MockClient((request) async {
      sent.add(request);
      return http.Response('{}', 200);
    });

    await ActivityService().setDone('5', true);
    await ActivityService().updateActivity(
      ActivityData(
        id: '5',
        tripId: '2',
        day: 2,
        time: '09:00',
        title: 'สกี',
        place: '',
        category: 'เที่ยว',
        note: '',
        isDone: false,
      ),
    );
    expect(sent[0].method, 'PATCH');
    expect(sent[0].url.toString(), '$baseUrl/activities/5');
    expect(jsonDecode(sent[0].body), {'isDone': true});
    expect(sent[1].method, 'PUT');
    expect(jsonDecode(sent[1].body)['tripId'], 2);
  });

  test('deleteTrip ลบกิจกรรม รายจ่าย เช็กลิสต์ที่ผูกอยู่ แล้วค่อยลบทริป', () async {
    final server = await setUpFakeServer();
    await TripService().deleteTrip('2');

    expect(server.count('activities', {'tripId': 2}), 0);
    expect(server.count('expenses', {'tripId': 2}), 0);
    expect(server.count('checklist', {'tripId': 2}), 0);
    expect(server.findById('trips', '2'), isNull);
    // ทริปอื่นไม่โดนลบ
    expect(server.count('activities', {'tripId': 1}), greaterThan(0));
    expect(server.requests.last, 'DELETE /trips/2');
  });

  test('statusCode ผิดปกติ -> ApiException พร้อมรหัส', () async {
    api.client = MockClient((request) async => http.Response('{}', 404));
    expect(
      () => ChecklistService().deleteItem('999'),
      throwsA(
        isA<api.ApiException>().having(
          (e) => e.message,
          'message',
          contains('404'),
        ),
      ),
    );
  });

  test('ต่อ server ไม่ได้ -> ข้อความให้เปิด server ก่อน', () async {
    api.client = MockClient((request) async {
      throw http.ClientException('Connection refused', request.url);
    });
    expect(
      () => TripService().getTrips(),
      throwsA(
        isA<api.ApiException>().having(
          (e) => e.message,
          'message',
          api.serverDownMessage,
        ),
      ),
    );
  });

  group('WeatherService (Open-Meteo)', () {
    test('ส่ง lat/lon และช่วงวันที่ของทริปไปใน query', () async {
      final server = await setUpFakeServer();
      final trip = tripFrom(2, 6);
      final list = await WeatherService().getForecast(niseko, trip);

      final Uri url = server.lastWeatherUrl!;
      expect(url.toString(), startsWith(weatherUrl));
      expect(url.queryParameters['latitude'], '42.8048');
      expect(url.queryParameters['longitude'], '140.6874');
      expect(url.queryParameters['start_date'], toDateKey(trip.startDate));
      expect(url.queryParameters['end_date'], toDateKey(trip.endDate));
      expect(url.queryParameters['daily'], contains('precipitation'));
      expect(list.length, 5);
    });

    test('ทริปยาวเกิน 16 วัน ตัดช่วงพยากรณ์ / ทริปเริ่มแล้วเริ่มที่วันนี้', () {
      final longTrip = tripFrom(10, 25);
      expect(
        WeatherService.forecastEnd(longTrip),
        today().add(const Duration(days: forecastDays - 1)),
      );
      final ongoing = tripFrom(-2, 2);
      expect(WeatherService.forecastStart(ongoing), today());
    });

    test('ทริปที่ผ่านไปแล้ว / ไกลเกินพยากรณ์ มีข้อความอธิบาย', () {
      expect(WeatherService.unavailableReason(tripFrom(-10, -5)), contains('ผ่านไปแล้ว'));
      expect(WeatherService.unavailableReason(tripFrom(30, 35)), contains('ไกลเกิน'));
      expect(WeatherService.unavailableReason(tripFrom(2, 6)), isNull);
    });

    test('เน็ตใช้ไม่ได้ -> ข้อความเรื่องพยากรณ์อากาศ', () async {
      api.client = MockClient((request) async {
        throw http.ClientException('timeout', request.url);
      });
      expect(
        () => WeatherService().getForecast(niseko, tripFrom(2, 4)),
        throwsA(
          isA<api.ApiException>().having(
            (e) => e.message,
            'message',
            api.weatherDownMessage,
          ),
        ),
      );
    });
  });
}
