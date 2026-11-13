import 'package:flutter/material.dart';

import '../constant/app_constant.dart';
import '../constant/app_format.dart';
import '../constant/color.dart';
import '../model/expense_data.dart';
import '../model/trip_data.dart';
import '../service/expense_service.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/budget_bar.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/expense_tile.dart';
import '../widgets/loading_view.dart';
import '../widgets/section_title.dart';
import 'expense_form_screen.dart';

// แท็บค่าใช้จ่าย: ยอดรวมเทียบงบ (progress bar เปลี่ยนสีเมื่อเกินงบ)
// ยอดแยกตามหมวด และรายการรายจ่ายที่เพิ่ม/ลบได้
class ExpenseTab extends StatefulWidget {
  final TripData trip;

  const ExpenseTab({super.key, required this.trip});

  @override
  State<ExpenseTab> createState() => _ExpenseTabState();
}

class _ExpenseTabState extends State<ExpenseTab>
    with AutomaticKeepAliveClientMixin {
  final ExpenseService expenseService = ExpenseService();

  List<ExpenseData> _expenses = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  // GET /expenses?tripId=...
  Future<void> loadExpenses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      List<ExpenseData> list = await expenseService.getExpenses(widget.trip.id);
      if (!mounted) return;
      setState(() {
        _expenses = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> openForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseFormScreen(trip: widget.trip),
      ),
    );
    if (result == true) loadExpenses();
  }

  Future<void> deleteExpense(ExpenseData expense) async {
    bool confirmed = await showConfirmDialog(
      context,
      title: 'ลบรายจ่ายนี้?',
      message:
          '"${expense.title}" ${formatMoney(expense.amount, widget.trip.currency)} จะถูกลบ',
    );
    if (!confirmed) return;

    try {
      await expenseService.deleteExpense(expense.id);
      if (!mounted) return;
      showSuccessSnackBar(context, 'ลบรายจ่ายเรียบร้อย');
      loadExpenses();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _errorMessage == null && !_isLoading
          ? FloatingActionButton.extended(
              heroTag: 'add-expense',
              onPressed: openForm,
              icon: const Icon(Icons.add_rounded),
              label: const Text('บันทึกรายจ่าย'),
            )
          : null,
      body: RefreshIndicator(onRefresh: loadExpenses, child: buildBody()),
    );
  }

  Widget buildBody() {
    if (_isLoading) {
      return const LoadingView();
    }
    if (_errorMessage != null) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          ErrorView(message: _errorMessage!, onRetry: loadExpenses),
        ],
      );
    }

    // ---------- คำนวณยอดด้วย where / map (บทที่ 1) ----------
    String currency = widget.trip.currency;
    double total = ExpenseData.sumOf(_expenses);
    double budget = widget.trip.budget;
    double ratio = budget <= 0 ? 0 : total / budget;
    Map<String, double> byCategory = ExpenseData.totalByCategory(
      _expenses,
      expenseCategories,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        buildSummaryCard(total, budget, ratio, currency),
        const SizedBox(height: 20),

        if (byCategory.isNotEmpty) ...[
          const SectionTitle(title: 'แยกตามหมวด'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: byCategory.entries.map((entry) {
                  return buildCategoryRow(
                    entry.key,
                    entry.value,
                    total,
                    currency,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        SectionTitle(title: 'รายการรายจ่าย (${_expenses.length})'),
        const SizedBox(height: 8),
        if (_expenses.isEmpty)
          const EmptyView(
            icon: Icons.receipt_long_rounded,
            title: 'ยังไม่มีรายจ่าย',
            message: 'กด "บันทึกรายจ่าย" เพื่อเริ่มจดค่าใช้จ่ายของทริป',
          ),
        for (ExpenseData expense in _expenses)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ExpenseTile(
              expense: expense,
              currency: currency,
              onDelete: () => deleteExpense(expense),
            ),
          ),
      ],
    );
  }

  // การ์ดยอดรวมเทียบงบ
  Widget buildSummaryCard(
    double total,
    double budget,
    double ratio,
    String currency,
  ) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    bool isOver = total > budget;
    Color color = BudgetBar.colorOf(ratio);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ใช้ไปแล้ว',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    formatMoney(total, currency),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  '${(ratio * 100).round()}% ของงบ',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BudgetBar(spent: total, budget: budget, height: 12),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'งบทั้งหมด ${formatMoney(budget, currency)}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
                Icon(
                  isOver ? Icons.warning_amber_rounded : Icons.savings_outlined,
                  size: 18,
                  color: isOver ? dangerColor : successColor,
                ),
                const SizedBox(width: 4),
                Text(
                  isOver
                      ? 'เกินงบ ${formatMoney(total - budget, currency)}'
                      : 'เหลือ ${formatMoney(budget - total, currency)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isOver ? dangerColor : successColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // แถวยอดของ 1 หมวด พร้อมแถบสัดส่วนเทียบกับยอดรวม
  Widget buildCategoryRow(
    String category,
    double amount,
    double total,
    String currency,
  ) {
    Color color = expenseColors[category] ?? primaryColor;
    double share = total <= 0 ? 0 : amount / total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              Icon(expenseIcons[category], size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(category)),
              Text(
                formatMoney(amount, currency),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '${(share * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 6,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
