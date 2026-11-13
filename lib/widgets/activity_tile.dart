import 'package:flutter/material.dart';

import '../constant/app_constant.dart';
import '../model/activity_data.dart';

// แถวกิจกรรม 1 รายการในแผนรายวัน
// ติ๊ก Checkbox = ทำแล้ว แถวจะจางลงด้วย AnimatedOpacity และชื่อมีขีดฆ่า
class ActivityTile extends StatelessWidget {
  final ActivityData activity;
  final ValueChanged<bool> onToggle; // ติ๊ก / เอาติ๊กออก
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ActivityTile({
    super.key,
    required this.activity,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color color = activityColors[activity.category] ?? colorScheme.primary;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: activity.isDone ? 0.55 : 1,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: activity.isDone,
                  onChanged: (bool? value) => onToggle(value ?? false),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              activity.time,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // ป้ายหมวด
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    activityIcons[activity.category],
                                    size: 13,
                                    color: color,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    activity.category,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activity.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            decoration: activity.isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (activity.place.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.place_outlined,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    activity.place,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (activity.note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '📝 ${activity.note}',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'ลบกิจกรรม',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
