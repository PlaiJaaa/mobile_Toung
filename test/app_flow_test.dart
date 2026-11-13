import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helper.dart';

// ทดสอบการใช้งานจริงผ่านหน้าจอ (ใช้ json-server และ Open-Meteo จำลองจาก test_helper.dart)
void main() {
  testWidgets('หน้ารายการทริป: แยกกำลังจะไป/ไปแล้ว และมีแถบเตือนก่อนเดินทาง', (
    tester,
  ) async {
    await setUpFakeServer();
    await openApp(tester);

    expect(find.text('กำลังจะไป (2)'), findsOneWidget);
    expect(find.text('อีก 2 วันจะออกเดินทาง ฮอกไกโดหน้าหนาว'), findsOneWidget);
    expect(find.textContaining('ยังไม่ได้เตรียม 5 อย่าง'), findsOneWidget);
    expect(find.text('ฮอกไกโดหน้าหนาว'), findsOneWidget);
    // งบที่ใช้ไป = 21500 + 16800 + 1150
    expect(find.textContaining('ใช้ไป ฿39,450 จาก ฿60,000'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('ไปแล้ว (1)'), 300);
    expect(find.text('ไปแล้ว (1)'), findsOneWidget);
  });

  testWidgets('ปิด server: ขึ้น error ภาษาไทย กดลองใหม่แล้วโหลดได้', (tester) async {
    final server = await setUpFakeServer();
    server.isDown = true;
    await openApp(tester);

    expect(find.text('โหลดข้อมูลไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('กรุณาเปิด server ก่อน'), findsOneWidget);

    server.isDown = false;
    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();
    expect(find.text('ฮอกไกโดหน้าหนาว'), findsOneWidget);
  });

  testWidgets('ฟอร์มสร้างทริป: validator ห้ามว่าง และงบต้องมากกว่า 0', (
    tester,
  ) async {
    await setUpFakeServer();
    await openApp(tester);

    await tester.tap(find.text('สร้างทริป'));
    await tester.pumpAndSettle();
    expect(find.text('สร้างทริปใหม่'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), '-5');
    await scrollAndTap(tester, find.widgetWithText(FilledButton, 'สร้างทริป'));

    await tester.scrollUntilVisible(
      find.text('กรุณากรอกชื่อทริป'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('กรุณากรอกชื่อทริป'), findsOneWidget);
    expect(find.text('กรุณาเลือกปลายทาง'), findsOneWidget);
    expect(find.text('กรุณาเลือกวันไปและวันกลับ'), findsOneWidget);
    expect(find.text('งบต้องมากกว่า 0'), findsOneWidget);
  });

  testWidgets('แก้ไขทริปจากเมนูการ์ด: ส่ง PATCH แล้วชื่อใหม่ขึ้นในรายการ', (
    tester,
  ) async {
    final server = await setUpFakeServer();
    await openApp(tester);

    await tester.tap(find.byTooltip('เมนูทริป').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('แก้ไขทริป'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'ฮอกไกโดลุยหิมะ');
    await scrollAndTap(tester, find.text('บันทึกการแก้ไข'));

    expect(server.requests, contains('PATCH /trips/2'));
    expect(server.findById('trips', '2')!['name'], 'ฮอกไกโดลุยหิมะ');
    await hideSnackBar(tester);
    expect(find.text('ฮอกไกโดลุยหิมะ'), findsOneWidget);
  });

  testWidgets('ลบทริป: ถามยืนยันก่อน แล้วลบข้อมูลที่ผูกอยู่ด้วย', (tester) async {
    final server = await setUpFakeServer();
    await openApp(tester);

    await tester.tap(find.byTooltip('เมนูทริป').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบทริป'));
    await tester.pumpAndSettle();
    expect(find.text('ลบทริปนี้?'), findsOneWidget);

    // กดยกเลิก -> ยังไม่ลบ
    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();
    expect(server.findById('trips', '2'), isNotNull);

    await tester.tap(find.byTooltip('เมนูทริป').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบทริป'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'ลบทริป'));
    await tester.pumpAndSettle();

    expect(server.findById('trips', '2'), isNull);
    expect(server.count('checklist', {'tripId': 2}), 0);
    expect(find.textContaining('ลบทริป "ฮอกไกโดหน้าหนาว" เรียบร้อย'), findsOneWidget);
  });

  testWidgets('เช็กลิสต์: ติ๊ก (PATCH) เพิ่มของแนะนำ (POST) และปัดทิ้ง (จำไว้ในทริป)', (
    tester,
  ) async {
    final server = await setUpFakeServer();
    await openApp(tester);

    // แตะแถบเตือน -> เปิดหน้ารายละเอียดที่แท็บเช็กลิสต์
    await tester.tap(find.textContaining('ยังไม่ได้เตรียม 5 อย่าง'));
    await tester.pumpAndSettle();
    expect(find.text('เตรียมแล้ว 2 จาก 7 อย่าง'), findsOneWidget);

    // ติ๊ก "เสื้อกันหนาว"
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text('เสื้อกันหนาว'),
          matching: find.byType(Row),
        ),
        matching: find.byType(Checkbox),
      ).first,
    );
    await tester.pumpAndSettle();
    expect(server.requests, contains('PATCH /checklist/7'));
    expect(server.findById('checklist', '7')!['isPacked'], true);
    expect(find.text('เตรียมแล้ว 3 จาก 7 อย่าง'), findsOneWidget);

    // ของแนะนำตามอากาศ: ฝนตกวันที่ 2 ของทริป
    final Finder umbrella = find.text('ร่มพับหรือเสื้อกันฝน');
    await scrollTo(tester, umbrella);
    expect(find.textContaining('ฝนตกวันที่ 2'), findsOneWidget);
    expect(find.text('อย่าลืม!'), findsWidgets);

    // กดเพิ่มลงเช็กลิสต์
    await tester.tap(
      find.descendant(
        of: find.ancestor(of: umbrella, matching: find.byType(Card)),
        matching: find.byTooltip('เพิ่มลงเช็กลิสต์'),
      ),
    );
    await tester.pumpAndSettle();
    expect(server.count('checklist', {'tripId': 2, 'item': 'ร่มพับหรือเสื้อกันฝน'}), 1);
    expect(server.requests, contains('POST /checklist'));
    await hideSnackBar(tester);

    // ปัดทิ้งของแนะนำที่ไม่ต้องการ -> บันทึกลง dismissedItems ของทริป (PATCH /trips/2)
    final Finder visitJapan = find.text('ลงทะเบียน Visit Japan Web');
    await scrollTo(tester, visitJapan);
    await tester.tap(
      find.descendant(
        of: find.ancestor(of: visitJapan, matching: find.byType(Card)),
        matching: find.byTooltip('ไม่ต้องการ'),
      ),
    );
    await tester.pumpAndSettle();
    expect(visitJapan, findsNothing);
    final List dismissed = server.findById('trips', '2')!['dismissedItems'];
    expect(dismissed, ['ลงทะเบียน Visit Japan Web']);
  });

  testWidgets('แท็บสภาพอากาศ: ทริปใกล้ขึ้นพยากรณ์ ทริปไกลขึ้นข้อความอธิบาย', (
    tester,
  ) async {
    await setUpFakeServer();
    await openApp(tester);

    await tester.tap(find.text('ฮอกไกโดหน้าหนาว'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('สภาพอากาศ'));
    await tester.pumpAndSettle();
    expect(find.text('พยากรณ์อากาศ ฮอกไกโด (นิเซโกะ)'), findsOneWidget);
    expect(find.text('วันที่ 1'), findsOneWidget);

    // กลับไปหน้ารายการทริป
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('ปารีสต้อนรับปีใหม่'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('สภาพอากาศ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ไกลเกินช่วงที่พยากรณ์ได้'), findsOneWidget);
  });

  testWidgets('ค่าใช้จ่าย: ยอดเทียบงบ และฟอร์มบันทึกรายจ่าย (POST)', (tester) async {
    final server = await setUpFakeServer();
    await openApp(tester);

    await tester.tap(find.text('ฮอกไกโดหน้าหนาว'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ค่าใช้จ่าย'));
    await tester.pumpAndSettle();
    expect(find.text('฿39,450'), findsOneWidget);
    expect(find.text('เหลือ ฿20,550'), findsOneWidget);

    await tester.tap(find.text('บันทึกรายจ่าย'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'บันทึกรายจ่าย'));
    await tester.pumpAndSettle();
    expect(find.text('กรุณากรอกชื่อรายการ'), findsOneWidget);
    expect(find.text('กรุณาเลือกหมวด'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'ราเมน');
    await tester.enterText(find.byType(TextFormField).at(1), '25000');
    await tester.tap(find.text('หมวด'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('อาหาร').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'บันทึกรายจ่าย'));
    await tester.pumpAndSettle();

    expect(server.count('expenses', {'tripId': 2, 'title': 'ราเมน'}), 1);
    expect(find.text('เกินงบ ฿4,450'), findsOneWidget);
  });

  testWidgets('ตั้งค่า: สลับธีมและสกุลเงินหลัก จำค่าด้วย shared_preferences', (
    tester,
  ) async {
    await setUpFakeServer();
    await openApp(tester);

    await tester.tap(find.text('ตั้งค่า'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('ใช้ธีมมืดอยู่'), findsOneWidget);

    await tester.tap(find.textContaining('THB · บาท'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('JPY · เยน').last);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('isDarkMode'), true);
    expect(prefs.getString('mainCurrency'), 'JPY');
  });
}
