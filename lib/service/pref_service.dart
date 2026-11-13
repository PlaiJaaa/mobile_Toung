import 'package:shared_preferences/shared_preferences.dart';

import '../constant/app_constant.dart';

// เก็บค่าลงเครื่องด้วย shared_preferences
// ใช้จำ 2 อย่าง: ธีมที่เลือก และสกุลเงินหลัก
class PrefService {
  // ---------- ธีม ----------
  Future<void> saveDarkMode(bool isDark) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  Future<bool> getDarkMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isDarkMode') ?? false;
  }

  // ---------- สกุลเงินหลัก (ค่าเริ่มต้นตอนสร้างทริปใหม่) ----------
  Future<void> saveMainCurrency(String currency) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('mainCurrency', currency);
  }

  Future<String> getMainCurrency() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? currency = prefs.getString('mainCurrency');
    // ถ้ายังไม่เคยตั้ง หรือเป็นรหัสที่แอปไม่รู้จัก ให้ใช้บาท
    if (currency == null || !currencySymbols.containsKey(currency)) {
      return defaultCurrency;
    }
    return currency;
  }
}
