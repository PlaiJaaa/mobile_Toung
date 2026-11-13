import 'package:flutter/material.dart';

import '../constant/color.dart';
import '../model/checklist_data.dart';

// แถวของในเช็กลิสต์ 1 รายการ
// ติ๊กว่าเตรียมแล้ว: พื้นหลังเปลี่ยนเป็นสีเขียวอ่อน (AnimatedContainer)
// และตัวหนังสือจางลง (AnimatedOpacity)
class ChecklistTile extends StatelessWidget {
  final ChecklistData item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const ChecklistTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: item.isPacked
            ? successColor.withValues(alpha: 0.12)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isPacked
              ? successColor.withValues(alpha: 0.5)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: item.isPacked,
            activeColor: successColor,
            onChanged: (bool? value) => onToggle(value ?? false),
          ),
          Expanded(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 350),
              opacity: item.isPacked ? 0.6 : 1,
              child: Text(
                item.item,
                style: TextStyle(
                  fontSize: 15,
                  decoration: item.isPacked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'ลบรายการ',
            icon: Icon(
              Icons.close_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
