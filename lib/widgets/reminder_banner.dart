import 'dart:math';

import 'package:flutter/material.dart';

import '../constant/color.dart';

// แถบเตือนที่หน้าแรก เมื่อเหลือไม่เกิน 3 วันก่อนเดินทาง
// animation (implicit ด้วย TweenAnimationBuilder):
// - ตอนแสดงครั้งแรก แถบจะเลื่อนลงมาพร้อมค่อย ๆ ชัดขึ้น
// - ไอคอนกระเป๋าส่ายไปมาเล็กน้อย 3 ครั้งแล้วหยุด
class ReminderBanner extends StatelessWidget {
  final String tripName;
  final int daysUntilStart; // 0 = วันนี้
  final int unpackedCount; // จำนวนของที่ยังไม่ได้เตรียม
  final VoidCallback onTap; // กดแล้วไปหน้าเช็กลิสต์ของทริป

  const ReminderBanner({
    super.key,
    required this.tripName,
    required this.daysUntilStart,
    required this.unpackedCount,
    required this.onTap,
  });

  String get title {
    if (daysUntilStart <= 0) return 'วันนี้ออกเดินทาง $tripName';
    if (daysUntilStart == 1) return 'พรุ่งนี้ออกเดินทาง $tripName';
    return 'อีก $daysUntilStart วันจะออกเดินทาง $tripName';
  }

  @override
  Widget build(BuildContext context) {
    final bool isReady = unpackedCount == 0;
    final Color color = isReady ? successColor : dangerColor;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Material(
        color: color.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: color.withValues(alpha: 0.4)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // ไอคอนส่ายไปมา: มุมหมุน = sin(...) ที่ค่อย ๆ เล็กลงจนเป็น 0
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1500),
                  builder: (BuildContext context, double t, Widget? child) {
                    double angle = sin(t * pi * 6) * 0.25 * (1 - t);
                    return Transform.rotate(angle: angle, child: child);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isReady
                          ? Icons.check_rounded
                          : Icons.luggage_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isReady
                            ? 'เตรียมของในเช็กลิสต์ครบแล้ว พร้อมเดินทาง!'
                            : 'ยังไม่ได้เตรียม $unpackedCount อย่าง แตะเพื่อดูเช็กลิสต์',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
