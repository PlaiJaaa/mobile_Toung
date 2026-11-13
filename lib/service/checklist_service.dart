import 'dart:convert';

import '../constant/api_config.dart';
import '../model/checklist_data.dart';
import 'api_client.dart';

// จัดการเช็กลิสต์ของที่ต้องเตรียม (REST API: /checklist)
class ChecklistService {
  // GET /checklist : เช็กลิสต์ของทุกทริป (หน้ารายการทริปใช้นับของที่ยังไม่ได้เตรียม)
  Future<List<ChecklistData>> getAllItems() async {
    return fetchItems('$baseUrl/checklist');
  }

  // GET /checklist?tripId=1 : เช็กลิสต์ของทริป
  Future<List<ChecklistData>> getChecklist(String tripId) async {
    return fetchItems('$baseUrl/checklist?tripId=$tripId');
  }

  // เรียก GET แล้วแปลง JSON เป็น List ของ ChecklistData
  Future<List<ChecklistData>> fetchItems(String url) async {
    try {
      var response = await client.get(Uri.parse(url)).timeout(requestTimeout);
      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((json) => ChecklistData.fromJson(json)).toList();
      } else {
        throw ApiException('โหลดเช็กลิสต์ไม่สำเร็จ (${response.statusCode})');
      }
    } catch (e) {
      throw toApiException(e);
    }
  }

  // POST /checklist : เพิ่มรายการ แล้วคืนรายการที่มี id จาก server
  Future<ChecklistData> createItem(ChecklistData item) async {
    try {
      var response = await client
          .post(
            Uri.parse('$baseUrl/checklist'),
            headers: jsonHeaders,
            body: jsonEncode(item.toJson()),
          )
          .timeout(requestTimeout);
      if (response.statusCode == 201) {
        return ChecklistData.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)),
        );
      } else {
        throw ApiException('เพิ่มรายการไม่สำเร็จ (${response.statusCode})');
      }
    } catch (e) {
      throw toApiException(e);
    }
  }

  // PATCH /checklist/{id} : ติ๊กว่าเตรียมแล้ว / ยังไม่เตรียม
  Future<void> setPacked(String id, bool isPacked) async {
    try {
      var response = await client
          .patch(
            Uri.parse('$baseUrl/checklist/$id'),
            headers: jsonHeaders,
            body: jsonEncode({'isPacked': isPacked}),
          )
          .timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw ApiException('บันทึกสถานะไม่สำเร็จ (${response.statusCode})');
      }
    } catch (e) {
      throw toApiException(e);
    }
  }

  // DELETE /checklist/{id} : ลบรายการ
  Future<void> deleteItem(String id) async {
    try {
      var response = await client
          .delete(Uri.parse('$baseUrl/checklist/$id'))
          .timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw ApiException('ลบรายการไม่สำเร็จ (${response.statusCode})');
      }
    } catch (e) {
      throw toApiException(e);
    }
  }
}
