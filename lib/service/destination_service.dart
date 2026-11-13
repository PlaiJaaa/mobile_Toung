import 'dart:convert';

import '../constant/api_config.dart';
import '../model/destination_data.dart';
import 'api_client.dart';

// จัดการข้อมูลปลายทาง (REST API: /destinations) อ่านอย่างเดียว
class DestinationService {
  // GET /destinations : ปลายทางทั้งหมด
  Future<List<DestinationData>> getDestinations() async {
    try {
      var response = await client
          .get(Uri.parse('$baseUrl/destinations'))
          .timeout(requestTimeout);
      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((json) => DestinationData.fromJson(json)).toList();
      } else {
        throw ApiException('โหลดปลายทางไม่สำเร็จ (${response.statusCode})');
      }
    } catch (e) {
      throw toApiException(e);
    }
  }

  // หาปลายทางจาก id ในรายการที่โหลดมาแล้ว (ไม่พบคืน null)
  static DestinationData? findById(List<DestinationData> list, String id) {
    for (DestinationData destination in list) {
      if (destination.id == id) {
        return destination;
      }
    }
    return null;
  }
}
