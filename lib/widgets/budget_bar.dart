import 'package:flutter/material.dart';

import '../constant/color.dart';

// แถบแสดงงบที่ใช้ไปเทียบกับงบทั้งหมด
// ใช้ AnimatedContainer (บทที่ 6) ให้ความยาวและสีของแถบเปลี่ยนแบบนุ่มนวล
// สี: เขียว = ใช้ไม่ถึง 80%, ส้ม = 80-100%, แดง = เกินงบ
class BudgetBar extends StatelessWidget {
  final double spent; // ใช้ไปแล้ว
  final double budget; // งบทั้งหมด
  final double height;
  final Color? trackColor; // สีพื้นของแถบ (ไม่ส่งมา = สีตามธีม)

  const BudgetBar({
    super.key,
    required this.spent,
    required this.budget,
    this.height = 10,
    this.trackColor,
  });

  // สัดส่วนที่ใช้ไป เช่น 0.5 = ครึ่งหนึ่งของงบ
  double get ratio => budget <= 0 ? 0 : spent / budget;

  // สีของแถบตามสัดส่วน (ใช้ร่วมกับข้อความในหน้าอื่นได้)
  static Color colorOf(double ratio) {
    if (ratio > 1) return dangerColor;
    if (ratio >= 0.8) return warningColor;
    return successColor;
  }

  @override
  Widget build(BuildContext context) {
    // แถบยาวได้ไม่เกิน 100% แม้จะใช้เกินงบ
    double fill = ratio.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Container(
          height: height,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            color:
                trackColor ??
                Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(height),
          ),
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            width: constraints.maxWidth * fill,
            height: height,
            decoration: BoxDecoration(
              color: colorOf(ratio),
              borderRadius: BorderRadius.circular(height),
            ),
          ),
        );
      },
    );
  }
}
