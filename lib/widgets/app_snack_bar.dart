import 'package:flutter/material.dart';

import '../constant/color.dart';

// SnackBar แจ้งผลการทำงาน: สีเขียว = สำเร็จ, สีแดง = ผิดพลาด

void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: successColor),
  );
}

void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: dangerColor),
  );
}
