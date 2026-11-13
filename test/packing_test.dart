import 'package:flutter_test/flutter_test.dart';
import 'package:travel_planner/constant/app_format.dart';
import 'package:travel_planner/model/checklist_data.dart';
import 'package:travel_planner/model/destination_data.dart';
import 'package:travel_planner/model/packing_rule_data.dart';
import 'package:travel_planner/model/suggestion_data.dart';
import 'package:travel_planner/model/trip_data.dart';
import 'package:travel_planner/model/weather_data.dart';
import 'package:travel_planner/service/packing_service.dart';

// ทดสอบการรวมของแนะนำจาก 3 แหล่ง: packingRules / พยากรณ์อากาศ / จำนวนวัน
void main() {
  final DateTime start = DateTime(2026, 11, 15);
  final TripData trip = TripData(
    id: '2',
    name: 'ฮอกไกโด',
    destinationId: '8',
    startDate: start,
    endDate: DateTime(2026, 11, 19), // 5 วัน
    budget: 60000,
    currency: 'THB',
    style: 'ผจญภัย',
  );
  final DestinationData niseko = DestinationData(
    id: '8',
    name: 'นิเซโกะ',
    country: 'ญี่ปุ่น',
    type: 'mountain',
    image: '',
    lat: 0,
    lon: 0,
  );

  PackingRuleData rule(String match, String value, String item, {bool essential = false}) =>
      PackingRuleData(
        id: item,
        match: match,
        value: value,
        item: item,
        reason: 'เหตุผล',
        essential: essential,
      );

  final List<PackingRuleData> rules = [
    rule('all', '', 'ยาประจำตัว', essential: true),
    rule('type', 'mountain', 'เสื้อกันหนาว', essential: true),
    rule('type', 'beach', 'ครีมกันแดด'),
    rule('country', 'ญี่ปุ่น', 'พาสปอร์ต', essential: true),
    rule('country', 'ฝรั่งเศส', 'วีซ่าเชงเก้น', essential: true),
  ];

  WeatherData day(int index, {double max = 10, double min = 5, int rain = 10, int code = 3}) =>
      WeatherData(
        date: start.add(Duration(days: index)),
        maxTemp: max,
        minTemp: min,
        rainChance: rain,
        weatherCode: code,
      );

  List<String> items(List<SuggestionData> list) => list.map((s) => s.item).toList();

  test('กรอง packingRules ด้วยประเภทสถานที่ ประเทศ และ all', () {
    final list = PackingService.suggestionsFromRules(niseko, rules);
    expect(items(list), ['ยาประจำตัว', 'เสื้อกันหนาว', 'พาสปอร์ต']);
  });

  test('ฝนตกวันที่ 3 -> แนะนำร่ม พร้อมบอกวันที่ในเหตุผล', () {
    final list = PackingService.suggestionsFromWeather(trip, [
      day(0),
      day(1),
      day(2, rain: 85, code: 63),
    ]);
    final umbrella = list.firstWhere((s) => s.item.contains('ร่ม'));
    expect(umbrella.reason, contains('ฝนตกวันที่ 3'));
    expect(umbrella.reason, contains('85%'));
    expect(umbrella.essential, true); // โอกาสฝน 80% ขึ้นไปถือว่าจำเป็น
  });

  test('หนาวต่ำกว่า 15°C / ต่ำกว่า 5°C / หิมะ / ร้อนจัด', () {
    final cold = PackingService.suggestionsFromWeather(trip, [
      day(0, min: 12),
      day(1, min: -3, code: 73),
    ]);
    expect(items(cold), contains('เสื้อกันหนาว'));
    expect(items(cold), contains('ถุงมือ หมวกไหมพรม และผ้าพันคอ'));
    expect(items(cold), contains('รองเท้ากันน้ำกันลื่น'));
    expect(cold.firstWhere((s) => s.item == 'เสื้อกันหนาว').reason, contains('-3°C'));

    final hot = PackingService.suggestionsFromWeather(trip, [day(0, max: 36, min: 27)]);
    expect(items(hot), ['แว่นกันแดด', 'ขวดน้ำพกพา']);

    final mild = PackingService.suggestionsFromWeather(trip, [day(0, max: 28, min: 20)]);
    expect(mild, isEmpty);
  });

  test('จำนวนวัน: 5 วัน -> เสื้อผ้า 5 ชุด, เกิน 7 วันเตรียม 7 ชุด, ไปเช้าเย็นกลับ', () {
    expect(items(PackingService.suggestionsFromDays(trip)), [
      'เสื้อผ้า 5 ชุด',
      'ชุดชั้นในและถุงเท้า 6 ชุด',
      'ถุงแยกผ้าใช้แล้ว',
    ]);

    TripData withDays(int days) => TripData(
      id: '1',
      name: '',
      destinationId: '1',
      startDate: start,
      endDate: start.add(Duration(days: days - 1)),
      budget: 1,
      currency: 'THB',
      style: '',
    );
    expect(PackingService.suggestionsFromDays(withDays(10)).first.item, 'เสื้อผ้า 7 ชุด');
    expect(PackingService.suggestionsFromDays(withDays(1)).first.item, 'เสื้อผ้าสำรอง 1 ชุด');
  });

  test('รวมทุกแหล่ง: ไม่มีชื่อซ้ำ ของจำเป็นขึ้นก่อน และเหตุผลจากอากาศมาก่อน', () {
    final list = PackingService.buildSuggestions(
      trip: trip,
      destination: niseko,
      rules: rules,
      weather: [day(0, min: -2)],
    );
    expect(items(list).where((i) => i == 'เสื้อกันหนาว').length, 1);
    final jacket = list.firstWhere((s) => s.item == 'เสื้อกันหนาว');
    expect(jacket.source, 'พยากรณ์อากาศ');
    // ของจำเป็นทั้งหมดอยู่หน้าของไม่จำเป็น
    final int lastEssential = list.lastIndexWhere((s) => s.essential);
    final int firstOptional = list.indexWhere((s) => !s.essential);
    expect(lastEssential, lessThan(firstOptional));
  });

  test('ซ่อนของที่อยู่ในเช็กลิสต์แล้ว และของที่ปัดทิ้ง', () {
    final all = PackingService.buildSuggestions(
      trip: trip,
      destination: niseko,
      rules: rules,
    );
    final visible = PackingService.hideUsed(
      all,
      [ChecklistData(id: '1', tripId: '2', item: ' พาสปอร์ต ', isPacked: true)],
      ['ยาประจำตัว'],
    );
    expect(items(visible), isNot(contains('พาสปอร์ต')));
    expect(items(visible), isNot(contains('ยาประจำตัว')));
    expect(items(visible), contains('เสื้อกันหนาว'));
  });

  test('ข้อมูลตัวอย่างวันที่เดินทาง', () {
    expect(toDateKey(trip.dateOfDay(5)), '2026-11-19');
  });
}
