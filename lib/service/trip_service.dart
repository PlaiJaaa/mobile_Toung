import 'dart:convert';

import '../constant/api_config.dart';
import '../model/trip_data.dart';
import 'activity_service.dart';
import 'api_client.dart';
import 'checklist_service.dart';
import 'expense_service.dart';

// จัดการข้อมูลทริป (REST API: /trips)
class TripService {
  // GET /trips : ทริปทั้งหมด
  Future<List<TripData>> getTrips() async {
    try {
      var response = await client
          .get(Uri.parse('$baseUrl/trips'))
          .timeout(requestTimeout);
      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((json) => TripData.fromJson(json)).toList();
      } else {
        throw ApiException('โหลดรายการทริปไม่สำเร็จ (${response.statusCode})');
      }
    } catch (e) {
      throw toApiException(e);
    }
  }

  // POST /trips : สร้างทริปใหม่ (server ตอบ 201 Created พร้อมข้อมูลที่มี id แล้ว)
  Future<TripData> createTrip(TripData trip) async {
    try {
      var response = await client
          .post(
            Uri.parse('$baseUrl/trips'),
            headers: jsonHeaders,
            body: jsonEncode(trip.toJson()),
          )
          .timeout(requestTimeout);
      if (response.statusCode == 201) {
        return TripData.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        throw ApiException('สร้างทริปไม่สำเร็จ (${response.statusCode})');
      }
    } catch (e) {
      throw toApiException(e);
    }
  }

  // PATCH /trips/{id} : แก้เฉพาะช่องที่ส่งไป แล้วคืนข้อมูลทริปล่าสุด
  // ใช้ PATCH แทน PUT เพื่อไม่ให้ช่องอื่น (เช่น dismissedItems) หายไป
  Future<TripData> updateTrip(String id, Map<String, dynamic> data) async {
    try {
      var response = await client
          .patch(
            Uri.parse('$baseUrl/trips/$id'),
            headers: jsonHeaders,
            body: jsonEncode(data),
          )
          .timeout(requestTimeout);
      if (response.statusCode == 200) {
        return TripData.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        throw ApiException('บันทึกทริปไม่สำเร็จ (${response.statusCode})');
      }
    } catch (e) {
      throw toApiException(e);
    }
  }

  // บันทึกรายการของแนะนำที่ผู้ใช้ปัดทิ้ง (จำไว้ต่อทริป)
  Future<TripData> saveDismissedItems(String id, List<String> items) async {
    return updateTrip(id, {'dismissedItems': items});
  }

  // ลบทริป พร้อมกิจกรรม รายจ่าย และเช็กลิสต์ที่ผูกกับทริปนี้
  // ลบข้อมูลลูกก่อน แล้วค่อย DELETE /trips/{id} เพื่อไม่ให้เหลือข้อมูลค้างใน server
  Future<void> deleteTrip(String id) async {
    ActivityService activityService = ActivityService();
    ExpenseService expenseService = ExpenseService();
    ChecklistService checklistService = ChecklistService();

    for (var activity in await activityService.getActivities(id)) {
      await activityService.deleteActivity(activity.id);
    }
    for (var expense in await expenseService.getExpenses(id)) {
      await expenseService.deleteExpense(expense.id);
    }
    for (var item in await checklistService.getChecklist(id)) {
      await checklistService.deleteItem(item.id);
    }

    try {
      var response = await client
          .delete(Uri.parse('$baseUrl/trips/$id'))
          .timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw ApiException('ลบทริปไม่สำเร็จ (${response.statusCode})');
      }
    } catch (e) {
      throw toApiException(e);
    }
  }
}
