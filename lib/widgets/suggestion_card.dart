import 'package:flutter/material.dart';

import '../constant/color.dart';
import '../model/suggestion_data.dart';

// การ์ดของแนะนำ 1 รายการ: ไอคอน ชื่อของ เหตุผล และแหล่งที่มา
// ของจำเป็นติดป้าย "อย่าลืม!" สีแดง มีปุ่มเพิ่มลงเช็กลิสต์ และปุ่มปัดทิ้ง
class SuggestionCard extends StatelessWidget {
  final SuggestionData suggestion;
  final VoidCallback onAdd;
  final VoidCallback onDismiss;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.onAdd,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(suggestion.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        suggestion.item,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (suggestion.essential)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: dangerColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'อย่าลืม!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    suggestion.reason,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'แนะนำจาก: ${suggestion.source}',
                    style: TextStyle(fontSize: 11, color: colorScheme.outline),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton.filledTonal(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'เพิ่มลงเช็กลิสต์',
                  icon: const Icon(Icons.add_rounded),
                  onPressed: onAdd,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'ไม่ต้องการ',
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onDismiss,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
