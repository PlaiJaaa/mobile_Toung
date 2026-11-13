import 'package:intl/intl.dart';

import 'app_constant.dart';

// ฟังก์ชันจัดรูปแบบข้อความและวันที่ ใช้ package intl

// จำนวนเงินพร้อมสัญลักษณ์สกุลเงิน เช่น (4260.5, 'THB') -> ฿4,260.5
// ถ้าเป็นจำนวนเต็มจะไม่แสดงทศนิยม เช่น ¥15,000
String formatMoney(double amount, String currency) {
  String symbol = currencySymbols[currency] ?? '$currency ';
  return '$symbol${NumberFormat('#,##0.##').format(amount)}';
}

// ตัวเลขสำหรับใส่ในช่องกรอก เช่น 5000.0 -> "5000", 99.5 -> "99.5"
String plainNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toString();
}

// ตัดเวลาออก เหลือแค่วันที่ (ใช้เทียบวันโดยไม่สนชั่วโมง)
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

// วันนี้ (ไม่มีเวลา)
DateTime today() => dateOnly(DateTime.now());

// แปลงวันที่เป็นข้อความที่เก็บใน server เช่น 2026-11-15
String toDateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

// แปลงข้อความ 2026-11-15 กลับเป็น DateTime (อ่านไม่ได้ให้ใช้วันนี้)
DateTime parseDateKey(String? text) {
  DateTime? date = DateTime.tryParse(text ?? '');
  return date == null ? today() : dateOnly(date);
}

// วันที่แบบไทย ปี พ.ศ. เช่น 15 พ.ย. 2569
String formatDate(DateTime date) {
  return '${DateFormat('d MMM', 'th').format(date)} ${date.year + 543}';
}

// วันที่แบบสั้น เช่น 15 พ.ย.
String formatShortDate(DateTime date) => DateFormat('d MMM', 'th').format(date);

// วันในสัปดาห์ + วันที่ เช่น ส. 15 พ.ย.
String formatDayDate(DateTime date) {
  return DateFormat('E d MMM', 'th').format(date);
}

// ช่วงวันที่ เช่น 15 - 19 พ.ย. 2569 หรือ 28 ธ.ค. 2569 - 2 ม.ค. 2570
String formatDateRange(DateTime start, DateTime end) {
  if (dateOnly(start) == dateOnly(end)) {
    return formatDate(start);
  }
  if (start.year != end.year) {
    return '${formatDate(start)} - ${formatDate(end)}';
  }
  if (start.month != end.month) {
    return '${formatShortDate(start)} - ${formatDate(end)}';
  }
  return '${start.day} - ${formatDate(end)}';
}
