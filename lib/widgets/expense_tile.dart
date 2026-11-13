import 'package:flutter/material.dart';

import '../constant/app_constant.dart';
import '../constant/app_format.dart';
import '../model/expense_data.dart';

// แถวรายจ่าย 1 รายการ: ไอคอนหมวด ชื่อรายการ วันที่ และจำนวนเงิน
class ExpenseTile extends StatelessWidget {
  final ExpenseData expense;
  final String currency; // สกุลเงินของทริป
  final VoidCallback onDelete;

  const ExpenseTile({
    super.key,
    required this.expense,
    required this.currency,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color color = expenseColors[expense.category] ?? colorScheme.primary;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 14, right: 4),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(expenseIcons[expense.category], color: color, size: 20),
        ),
        title: Text(
          expense.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${expense.category} · ${formatDate(expense.date)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatMoney(expense.amount, currency),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            IconButton(
              tooltip: 'ลบรายจ่าย',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
