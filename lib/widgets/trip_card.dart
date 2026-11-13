import 'package:flutter/material.dart';

import '../constant/app_constant.dart';
import '../constant/app_format.dart';
import '../constant/color.dart';
import '../model/destination_data.dart';
import '../model/trip_data.dart';
import 'budget_bar.dart';
import 'destination_image.dart';

// การ์ดทริปในหน้ารายการ: รูปปลายทางเป็นพื้นหลัง (Stack) ทับด้วยชื่อทริปและวันที่
// ด้านล่างเป็นแถบงบที่ใช้ไปแล้ว
class TripCard extends StatelessWidget {
  final TripData trip;
  final DestinationData? destination; // null = หาปลายทางไม่พบ
  final double spent; // ยอดรายจ่ายรวมของทริป
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TripCard({
    super.key,
    required this.trip,
    required this.destination,
    required this.spent,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  // ข้อความสถานะมุมซ้ายบน
  String get statusText {
    if (trip.isPast) return 'ไปแล้ว';
    if (trip.isOngoing) return 'กำลังเที่ยว';
    if (trip.daysUntilStart == 1) return 'พรุ่งนี้';
    return 'อีก ${trip.daysUntilStart} วัน';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double ratio = trip.budget <= 0 ? 0 : spent / trip.budget;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- ส่วนรูป: ซ้อนชั้นด้วย Stack ----------
            SizedBox(
              height: 170,
              child: Stack(
                children: [
                  // ชั้นที่ 1: รูปปลายทาง
                  Positioned.fill(
                    child: DestinationImage(image: destination?.image ?? ''),
                  ),
                  // ชั้นที่ 2: ไล่สีดำด้านล่าง ให้ตัวหนังสือสีขาวอ่านง่าย
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // ชั้นที่ 3: ป้ายสถานะมุมซ้ายบน
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: trip.isPast
                            ? Colors.black.withValues(alpha: 0.55)
                            : secondaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // ชั้นที่ 4: เมนูแก้ไข/ลบ มุมขวาบน
                  Positioned(
                    top: 4,
                    right: 4,
                    child: PopupMenuButton<String>(
                      tooltip: 'เมนูทริป',
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white,
                      ),
                      onSelected: (String value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (BuildContext context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('แก้ไขทริป'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline_rounded,
                              color: dangerColor,
                            ),
                            title: Text(
                              'ลบทริป',
                              style: TextStyle(color: dangerColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ชั้นที่ 5: ชื่อทริป ปลายทาง และวันที่ ด้านล่าง
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              destinationTypeIcons[destination?.type] ??
                                  Icons.place_rounded,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${destination?.fullName ?? 'ไม่พบปลายทาง'}'
                                '  ·  ${formatDateRange(trip.startDate, trip.endDate)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---------- ส่วนงบ ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ใช้ไป ${formatMoney(spent, trip.currency)} '
                          'จาก ${formatMoney(trip.budget, trip.currency)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        '${(ratio * 100).round()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: BudgetBar.colorOf(ratio),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  BudgetBar(spent: spent, budget: trip.budget, height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
