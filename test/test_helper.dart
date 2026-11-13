import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_planner/constant/app_format.dart';
import 'package:travel_planner/main.dart';
import 'package:travel_planner/service/api_client.dart' as api;

// json-server จำลองสำหรับเทสต์ ทำงานเหมือน json-server 0.17 เท่าที่แอปใช้
// - GET /collection?field=value  กรองแบบเท่ากับ
// - POST /collection             สร้าง id ใหม่ ตอบ 201
// - PUT / PATCH /collection/{id} แก้ข้อมูล ตอบ 200 (ไม่พบ id ตอบ 404)
// - DELETE /collection/{id}      ตอบ 200 (ไม่พบ id ตอบ 404)
// และจำลอง Open-Meteo: ทุกวันหนาว (ต่ำสุด -2°C) และวันที่ 2 ของช่วงที่ขอมีฝน 85%
// ข้อมูลตั้งต้นอ่านจาก server/db.sample.json แล้วเลื่อนวันที่ให้ตรงกับวันนี้ (เหมือน reset_db.js)
class FakeJsonServer {
  final Map<String, List<Map<String, dynamic>>> db = {};
  final List<String> requests = []; // เช่น 'PATCH /checklist/4'
  bool isDown = false; // true = จำลองว่ายังไม่ได้เปิด server
  bool weatherDown = false; // true = จำลองว่าเรียก Open-Meteo ไม่ได้
  Uri? lastWeatherUrl;

  FakeJsonServer() {
    final Map<String, dynamic> sample = jsonDecode(
      File('server/db.sample.json').readAsStringSync(),
    );
    sample.forEach((String name, dynamic rows) {
      db[name] = (rows as List)
          .map((r) => Map<String, dynamic>.from(r))
          .toList();
    });
    // เลื่อนวันที่ของข้อมูลตัวอย่าง (อ้างอิง 13 พ.ย. 2026) ให้ตรงกับวันนี้
    final int shift = today().difference(DateTime(2026, 11, 13)).inDays;
    String move(String text) =>
        toDateKey(DateTime.parse(text).add(Duration(days: shift)));
    for (final trip in table('trips')) {
      trip['startDate'] = move(trip['startDate']);
      trip['endDate'] = move(trip['endDate']);
    }
    for (final expense in table('expenses')) {
      expense['date'] = move(expense['date']);
    }
  }

  List<Map<String, dynamic>> table(String name) => db[name]!;

  Map<String, dynamic>? findById(String name, String id) {
    for (final row in table(name)) {
      if (row['id'].toString() == id) return row;
    }
    return null;
  }

  int count(String name, Map<String, Object> where) {
    return table(name).where((row) {
      return where.entries.every((e) => row[e.key] == e.value);
    }).length;
  }

  MockClient get client => MockClient(handle);

  Future<http.Response> handle(http.Request request) async {
    if (request.url.host == 'api.open-meteo.com') {
      return handleWeather(request);
    }
    if (isDown) {
      throw http.ClientException('Connection refused', request.url);
    }
    final List<String> parts = request.url.pathSegments;
    requests.add('${request.method} ${request.url.path}');
    final String name = parts.first;
    if (!db.containsKey(name)) return http.Response('{}', 404);

    final String? id = parts.length > 1 ? parts[1] : null;
    switch (request.method) {
      case 'GET':
        final rows = table(name).where((row) {
          return request.url.queryParameters.entries.every(
            (e) => row[e.key].toString() == e.value,
          );
        }).toList();
        return json(rows, 200);
      case 'POST':
        final Map<String, dynamic> body = jsonDecode(request.body);
        int nextId = 1;
        for (final row in table(name)) {
          final int rowId = int.parse(row['id'].toString());
          if (rowId >= nextId) nextId = rowId + 1;
        }
        body['id'] = nextId;
        table(name).add(body);
        return json(body, 201);
      case 'PUT':
      case 'PATCH':
        final row = findById(name, id!);
        if (row == null) return http.Response('{}', 404);
        if (request.method == 'PUT') {
          row.removeWhere((key, value) => key != 'id');
        }
        row.addAll(jsonDecode(request.body));
        return json(row, 200);
      case 'DELETE':
        final row = findById(name, id!);
        if (row == null) return http.Response('{}', 404);
        table(name).remove(row);
        return json({}, 200);
    }
    return http.Response('{}', 405);
  }

  // พยากรณ์จำลองตามช่วง start_date - end_date ที่แอปขอมา
  Future<http.Response> handleWeather(http.Request request) async {
    if (weatherDown) {
      throw http.ClientException('Network is unreachable', request.url);
    }
    lastWeatherUrl = request.url;
    final DateTime start = DateTime.parse(
      request.url.queryParameters['start_date']!,
    );
    final DateTime end = DateTime.parse(
      request.url.queryParameters['end_date']!,
    );
    final int days = end.difference(start).inDays + 1;
    return json({
      'daily': {
        'time': [
          for (int i = 0; i < days; i++)
            toDateKey(start.add(Duration(days: i))),
        ],
        'temperature_2m_max': [for (int i = 0; i < days; i++) 4.0],
        'temperature_2m_min': [for (int i = 0; i < days; i++) -2.0],
        'precipitation_probability_max': [
          for (int i = 0; i < days; i++) i == 1 ? 85 : 10,
        ],
        'weather_code': [for (int i = 0; i < days; i++) i == 1 ? 63 : 3],
      },
    }, 200);
  }

  http.Response json(Object data, int status) {
    return http.Response.bytes(
      utf8.encode(jsonEncode(data)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}

// ตั้งค่าให้แอปเรียก server จำลอง และล้าง shared_preferences
Future<FakeJsonServer> setUpFakeServer({
  Map<String, Object> prefs = const {},
}) async {
  await initializeDateFormatting('th');
  SharedPreferences.setMockInitialValues(prefs);
  final FakeJsonServer server = FakeJsonServer();
  api.client = server.client;
  return server;
}

// ตั้งขนาดจอทดสอบให้เท่ามือถือ (411 x 891)
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

// เปิดแอปแล้วรอจนโหลดหน้ารายการทริปเสร็จ
Future<void> openApp(WidgetTester tester) async {
  usePhoneScreen(tester);
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
}

// รายการแนวตั้งที่อยู่บนจอ (ข้าม TabBarView ที่เลื่อนแนวนอน)
Finder verticalList() {
  return find
      .byWidgetPredicate(
        (Widget w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      )
      .hitTestable()
      .first;
}

// เลื่อนรายการจนเห็นข้อความที่ต้องการ
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 300, scrollable: verticalList());
  await tester.pumpAndSettle();
}

// เลื่อนหาข้อความในรายการจนเจอ แล้วกด
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

// ปิด SnackBar ที่ค้างอยู่ เพื่อไม่ให้บังปุ่มด้านล่างจอในขั้นถัดไป
Future<void> hideSnackBar(WidgetTester tester) async {
  final BuildContext context = tester.element(find.byType(Scaffold).first);
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  await tester.pumpAndSettle();
}
