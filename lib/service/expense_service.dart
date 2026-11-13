import 'dart:convert';

import '../constant/api_config.dart';
import '../model/expense_data.dart';
import 'api_client.dart';

// จัดการรายจ่าย (REST API: /expenses)
class ExpenseService {
  // GET /expenses : รายจ่ายของทุกทริป (หน้ารายการทริปใช้คำนวณงบที่ใช้ไป)
  Future<List<ExpenseData>> getAllExpenses() async {
    return fetchExpenses('$baseUrl/expenses');
  }

  // GET /expenses?tripId=1 : รายจ่ายของทริป เรียงวันที่ล่าสุดขึ้นก่อน
  Future<List<ExpenseData>> getExpenses(String tripId) async {
    List<ExpenseData> expenses = await fetchExpenses(
      '$baseUrl/expenses?tripId=$tripId',
    );
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  // เรียก GET แล้วแปลง JSON เป็น List ของ ExpenseData
  Future<List<ExpenseData>> fetchExpenses(String url) async {
    try {
      var response = await client.get(Uri.parse(url)).timeout(requestTimeout);
      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((json) => ExpenseData.fromJson(json)).toList();
      } else {
        throw ApiException('โหลดค่าใช้จ่ายไม่สำเร็จ (${response.statusCode})');
      }
    } catch (e) {
      throw toApiException(e);
    }
  }

  // POST /expenses : บันทึกรายจ่าย (server ตอบ 201 Created)
  Future<void> createExpense(ExpenseData expense) async {
    try {
      var response = await client
          .post(
            Uri.parse('$baseUrl/expenses'),
            headers: jsonHeaders,
            body: jsonEncode(expense.toJson()),
          )
          .timeout(requestTimeout);
      if (response.statusCode != 201) {
        throw ApiException('บันทึกรายจ่ายไม่สำเร็จ (${response.statusCode})');
      }
    } catch (e) {
      throw toApiException(e);
    }
  }

  // DELETE /expenses/{id} : ลบรายจ่าย
  Future<void> deleteExpense(String id) async {
    try {
      var response = await client
          .delete(Uri.parse('$baseUrl/expenses/$id'))
          .timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw ApiException('ลบรายจ่ายไม่สำเร็จ (${response.statusCode})');
      }
    } catch (e) {
      throw toApiException(e);
    }
  }
}
