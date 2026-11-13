import 'package:flutter/material.dart';

import '../constant/color.dart';

// แสดง AlertDialog ถามยืนยันก่อนลบข้อมูล
// คืนค่า true เมื่อผู้ใช้กดยืนยัน
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'ลบ',
}) async {
  String? result = await showDialog<String>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      icon: const Icon(Icons.delete_outline_rounded, color: dangerColor),
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, 'Cancel'),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: dangerColor),
          onPressed: () => Navigator.pop(context, 'OK'),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  // ถ้ากดนอกกล่องเพื่อปิด result จะเป็น null = ไม่ยืนยัน
  return result == 'OK';
}
