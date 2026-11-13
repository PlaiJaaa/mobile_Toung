import 'package:flutter_test/flutter_test.dart';
import 'package:travel_planner/constant/app_format.dart';
import 'package:travel_planner/model/checklist_data.dart';
import 'package:travel_planner/model/expense_data.dart';
import 'package:travel_planner/model/trip_data.dart';
import 'package:travel_planner/model/weather_data.dart';

// ทดสอบการแปลง JSON <-> Object และการคำนวณใน Model
void main() {
  test('TripData.fromJson / toJson และจำนวนวัน', () {
    final trip = TripData.fromJson({
      'id': 2,
      'name': 'ฮอกไกโด',
      'destinationId': 8,
      'startDate': '2026-11-15',
      'endDate': '2026-11-19',
      'budget': 60000,
      'currency': 'THB',
      'style': 'ผจญภัย',
    });
    expect(trip.id, '2');
    expect(trip.destinationId, '8');
    expect(trip.budget, 60000.0);
    expect(trip.dayCount, 5);
    expect(trip.dateOfDay(3), DateTime(2026, 11, 17));
    expect(trip.dismissedItems, isEmpty);

    final json = trip.toJson();
    expect(json.containsKey('id'), false);
    expect(json['destinationId'], 8); // ส่งกลับเป็นตัวเลข
    expect(json['startDate'], '2026-11-15');
  });

  test('สถานะทริป: ไปแล้ว / กำลังเที่ยว / อีกกี่วัน', () {
    TripData make(int startOffset, int endOffset) => TripData(
      id: '1',
      name: 't',
      destinationId: '1',
      startDate: today().add(Duration(days: startOffset)),
      endDate: today().add(Duration(days: endOffset)),
      budget: 1,
      currency: 'THB',
      style: '',
    );
    expect(make(-5, -1).isPast, true);
    expect(make(-1, 1).isOngoing, true);
    expect(make(2, 4).daysUntilStart, 2);
    expect(make(2, 4).isPast, false);
  });

  test('ExpenseData: ยอดรวม ยอดต่อทริป และยอดแยกตามหมวด (where/map)', () {
    ExpenseData make(String tripId, String category, double amount) =>
        ExpenseData(
          id: '',
          tripId: tripId,
          title: 'x',
          category: category,
          amount: amount,
          date: DateTime(2026, 11, 1),
        );
    final list = [
      make('1', 'อาหาร', 100),
      make('1', 'อาหาร', 50.5),
      make('1', 'ที่พัก', 1000),
      make('2', 'อาหาร', 999),
    ];
    expect(ExpenseData.sumOf(list), 2149.5);
    expect(ExpenseData.totalOfTrip(list, '1'), 1150.5);
    expect(
      ExpenseData.totalByCategory(
        list.where((e) => e.tripId == '1').toList(),
        ['อาหาร', 'ที่พัก', 'ช้อปปิ้ง'],
      ),
      {'อาหาร': 150.5, 'ที่พัก': 1000.0},
    );
  });

  test('ChecklistData.countUnpacked นับเฉพาะทริปและรายการที่ยังไม่เตรียม', () {
    final list = [
      ChecklistData(id: '1', tripId: '2', item: 'a', isPacked: false),
      ChecklistData(id: '2', tripId: '2', item: 'b', isPacked: true),
      ChecklistData(id: '3', tripId: '3', item: 'c', isPacked: false),
    ];
    expect(ChecklistData.countUnpacked(list, '2'), 1);
  });

  test('WeatherData.listFromJson แปลงรายการคู่ขนานของ Open-Meteo', () {
    final list = WeatherData.listFromJson({
      'daily': {
        'time': ['2026-11-15', '2026-11-16'],
        'temperature_2m_max': [7.4, 5],
        'temperature_2m_min': [-1.2, null],
        'precipitation_probability_max': [20, 90],
        'weather_code': [3, 73],
      },
    });
    expect(list.length, 2);
    expect(list[0].date, DateTime(2026, 11, 15));
    expect(list[0].maxTemp, 7.4);
    expect(list[1].minTemp, 0); // null -> 0
    expect(list[1].rainChance, 90);
    expect(list[1].isSnow, true);
    expect(list[1].description, 'หิมะตก');
  });

  test('formatMoney และ formatDateRange', () {
    expect(formatMoney(4260.5, 'THB'), '฿4,260.5');
    expect(formatMoney(15000, 'JPY'), '¥15,000');
    expect(plainNumber(5000), '5000');
    expect(plainNumber(99.5), '99.5');
  });
}
