import 'package:flutter/material.dart';

import '../constant/app_constant.dart';
import '../constant/app_format.dart';
import '../model/expense_data.dart';
import '../model/trip_data.dart';
import '../service/expense_service.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/primary_button.dart';

// ฟอร์มบันทึกรายจ่าย: รายการ, จำนวนเงิน, หมวด (Dropdown), วันที่จ่าย
class ExpenseFormScreen extends StatefulWidget {
  final TripData trip;

  const ExpenseFormScreen({super.key, required this.trip});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final ExpenseService expenseService = ExpenseService();

  String? _category;
  late DateTime _date;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // วันที่เริ่มต้น: วันนี้ แต่ถ้าวันนี้เลยวันกลับไปแล้วใช้วันกลับ
    DateTime now = today();
    _date = now.isAfter(widget.trip.endDate) ? widget.trip.endDate : now;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // เลือกวันที่จ่าย (ให้เลือกย้อนหลังได้ 1 ปี เผื่อจองตั๋วล่วงหน้า)
  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: widget.trip.startDate.subtract(const Duration(days: 365)),
      lastDate: widget.trip.endDate,
      helpText: 'วันที่จ่าย',
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    ExpenseData expense = ExpenseData(
      id: '',
      tripId: widget.trip.id,
      title: _titleController.text.trim(),
      category: _category!,
      amount: double.parse(_amountController.text.trim()),
      date: _date,
    );

    try {
      await expenseService.createExpense(expense);
      if (!mounted) return;
      showSuccessSnackBar(context, 'บันทึกรายจ่ายเรียบร้อย');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.toString());
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String currency = widget.trip.currency;

    return Scaffold(
      appBar: AppBar(title: const Text('บันทึกรายจ่าย')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'รายการ',
                hintText: 'เช่น ราเมนร้านดัง',
                prefixIcon: Icon(Icons.receipt_outlined),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกชื่อรายการ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'จำนวนเงิน ($currency)',
                prefixText: currencySymbols[currency],
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกจำนวนเงิน';
                }
                double? amount = double.tryParse(value.trim());
                if (amount == null) {
                  return 'กรอกเป็นตัวเลขเท่านั้น';
                }
                if (amount <= 0) {
                  return 'จำนวนเงินต้องมากกว่า 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _category,
              decoration: const InputDecoration(
                labelText: 'หมวด',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: expenseCategories
                  .map(
                    (String item) => DropdownMenuItem(
                      value: item,
                      child: Row(
                        children: [
                          Icon(
                            expenseIcons[item],
                            size: 18,
                            color: expenseColors[item],
                          ),
                          const SizedBox(width: 8),
                          Text(item),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                setState(() {
                  _category = value;
                });
              },
              validator: (String? value) {
                if (value == null) {
                  return 'กรุณาเลือกหมวด';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'วันที่จ่าย',
                  prefixIcon: Icon(Icons.event_rounded),
                ),
                child: Text(formatDate(_date)),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'บันทึกรายจ่าย',
              icon: Icons.check_rounded,
              isLoading: _isSaving,
              onPressed: saveExpense,
            ),
          ],
        ),
      ),
    );
  }
}
