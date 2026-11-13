import 'dart:convert';

import '../constant/api_config.dart';
import '../model/activity_data.dart';
import 'api_client.dart';

// จัดการกิจกรรมในแผนรายวัน (REST API: /activities)
class ActivityService {
  // GET /activities?tripId=1 : กิจกรรมของทริป เรียงตามวันแล้วตามเวลา
  Future<List<ActivityData>> getActivities(String tripId) async {
    try {
      var response = await client
          .get(Uri.parse('$baseUrl/activities?tripId=$tripId'))
          .timeout(requestTimeout);
      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        List<ActivityData> activities = jsonList
            .map((json) => ActivityData.fromJson(json))
            .toList();
        activities.sort((a, b) {
          if (a.day != b.day) return a.day.compareTo(b.day);
          return a.time.compareTo(b.time);
        });
        return activities;
      } else {
        throw ApiException('โหลดแผนเที่ยวไม่สำเร็จ (${response.statusCode})');
      }
    } catch (e) {
      throw toApiException(e);
    }
  }

  // POST /activities : เพิ่มกิจกรรม (server ตอบ 201 Created)
  Future<void> createActivity(ActivityData activity) async {
    try {
      var response = await client
          .post(
            Uri.parse('$baseUrl/activities'),
            headers: jsonHeaders,
            body: jsonEncode(activity.toJson()),
          )
          .timeout(requestTimeout);
      if (response.statusCode != 201) {
        throw ApiException('เพิ่มกิจกรรมไม่สำเร็จ (${response.statusCode})');
      }
    } catch (e) {
      throw toApiException(e);
    }
  }

  // PUT /activities/{id} : แก้กิจกรรมทั้งรายการ (ส่งข้อมูลครบทุกช่อง)
  Future<void> updateActivity(ActivityData activity) async {
    try {
      var response = await client
          .put(
            Uri.parse('$baseUrl/activities/${activity.id}'),
            headers: jsonHeaders,
            body: jsonEncode(activity.toJson()),
          )
          .timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw ApiException('แก้กิจกรรมไม่สำเร็จ (${response.statusCode})');
      }
    } catch (e) {
      throw toApiException(e);
    }
  }

  // PATCH /activities/{id} : ติ๊กว่าทำแล้ว / ยังไม่ทำ (ส่งไปแค่ช่องเดียว)
  Future<void> setDone(String id, bool isDone) async {
    try {
      var response = await client
          .patch(
            Uri.parse('$baseUrl/activities/$id'),
            headers: jsonHeaders,
            body: jsonEncode({'isDone': isDone}),
          )
          .timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw ApiException('บันทึกสถานะไม่สำเร็จ (${response.statusCode})');
      }
    } catch (e) {
      throw toApiException(e);
    }
  }

  // DELETE /activities/{id} : ลบกิจกรรม
  Future<void> deleteActivity(String id) async {
    try {
      var response = await client
          .delete(Uri.parse('$baseUrl/activities/$id'))
          .timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw ApiException('ลบกิจกรรมไม่สำเร็จ (${response.statusCode})');
      }
    } catch (e) {
      throw toApiException(e);
    }
  }
}
